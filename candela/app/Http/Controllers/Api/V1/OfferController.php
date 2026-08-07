<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Offer\CreateOfferRequest;
use App\Http\Requests\Api\V1\Offer\FilterOfferRequest;
use App\Http\Resources\Api\V1\OfferResource;
use App\Models\Coupon;
use App\Models\Offer;
use App\Models\Store;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class OfferController extends Controller
{
    /**
     * GET /api/v1/offers
     * Filterable list of active promotional offers by category, min_discount, and location proximity.
     */
    public function index(FilterOfferRequest $request): JsonResponse
    {
        $category = $request->query('category');
        $minDiscount = $request->query('min_discount') ?? $request->query('discount_percentage');
        $latitude = $request->query('latitude') ? (float) $request->query('latitude') : null;
        $longitude = $request->query('longitude') ? (float) $request->query('longitude') : null;
        $radiusKm = $request->query('radius') ? (float) $request->query('radius') : 10.0;

        $query = Offer::with('store')
            ->active()
            ->byCategory($category)
            ->minDiscount($minDiscount ? (float) $minDiscount : null)
            ->withinDistance($latitude, $longitude, $radiusKm);

        $offers = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'count' => $offers->count(),
            'data' => OfferResource::collection($offers),
        ]);
    }

    /**
     * GET /api/v1/offers/{id}
     * Find single offer by ID with strict Eloquent lookup and 404 response.
     */
    public function show(int $id): JsonResponse
    {
        $offer = Offer::with('store')->active()->find($id);

        if (! $offer) {
            return response()->json([
                'success' => false,
                'message' => 'Resource not found',
                'error_code' => 'RESOURCE_NOT_FOUND',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new OfferResource($offer),
        ]);
    }

    /**
     * POST /api/v1/merchant/offers/create
     * Creates a new offer and coupon in MySQL and automatically deducts the Creation Fee from merchant's wallet.
     */
    public function create(CreateOfferRequest $request): JsonResponse
    {
        $user = $request->user();
        $store = $user->store ?? Store::find($user->store_id) ?? Store::first();

        if (! $store) {
            return response()->json([
                'success' => false,
                'message' => 'Resource not found',
                'error_code' => 'RESOURCE_NOT_FOUND',
            ], 404);
        }

        $creationFee = (float) ($request->creation_fee ?? $store->creation_fee_rate ?? 50.00);
        $redemptionFee = (float) ($request->redemption_fee ?? $store->redemption_fee_rate ?? 5.00);

        try {
            $offer = DB::transaction(function () use ($request, $store, $creationFee, $redemptionFee) {
                // Fetch & lock Merchant Wallet
                $wallet = $store->getOrCreateWallet();

                // Check sufficient balance for Creation Fee
                if ((float) $wallet->balance < $creationFee) {
                    throw new Exception('INSUFFICIENT_FEE_BALANCE');
                }

                // Dynamic discount & final price calculation in D.L
                $originalPrice = $request->filled('original_price') ? (float) $request->original_price : null;
                $discountRate = $request->filled('discount_rate') ? (float) $request->discount_rate : null;
                $finalPrice = ($originalPrice !== null && $discountRate !== null)
                    ? Offer::calculateFinalPrice($originalPrice, $discountRate)
                    : null;

                $badge = $request->discount_badge;
                if (empty($badge)) {
                    $badge = $discountRate !== null ? ('-' . (int) $discountRate . '%') : 'عرض خاص';
                }

                // Create Offer record in MySQL
                $createdOffer = Offer::create([
                    'store_id' => $store->id,
                    'title' => $request->title,
                    'description' => $request->description,
                    'category' => $request->category,
                    'original_price' => $originalPrice,
                    'discount_rate' => $discountRate,
                    'final_price' => $finalPrice,
                    'creation_fee' => $creationFee,
                    'redemption_fee' => $redemptionFee,
                    'discount_badge' => $badge,
                    'banner_image' => $request->banner_image,
                    'branch_location' => $request->branch_location ?? $store->address ?? 'Downtown Branch',
                    'latitude' => $request->latitude ?? $store->latitude,
                    'longitude' => $request->longitude ?? $store->longitude,
                    'valid_until' => $request->valid_until ?? now()->addDays(30),
                    'is_active' => true,
                ]);

                // Create corresponding Coupon record in MySQL
                $rawDiscountType = strtolower($request->discount_type ?? 'percentage');
                $couponDiscountType = ($rawDiscountType === 'fixed' || $rawDiscountType === 'fixed_amount') ? 'fixed_amount' : 'percentage';

                Coupon::create([
                    'store_id' => $store->id,
                    'offer_id' => $createdOffer->id,
                    'campaign_id' => $request->filled('campaign_id') ? (int) $request->campaign_id : null,
                    'title' => $createdOffer->title,
                    'code' => 'CPN-' . $createdOffer->id . '-' . strtoupper(substr(md5(uniqid()), 0, 4)),
                    'discount_type' => $couponDiscountType,
                    'discount_value' => $request->discount_value ?? $discountRate ?? 20.00,
                    'redemption_fee' => $redemptionFee,
                    'expires_at' => $request->valid_until ?? now()->addDays(30),
                    'is_active' => true,
                ]);

                // Atomically deduct Creation Fee from Merchant Wallet
                $wallet->deduct(
                    $creationFee,
                    'offer_creation_fee',
                    $createdOffer->id,
                    Offer::class,
                    "Offer creation fee for '{$createdOffer->title}'"
                );

                // Update store balance column for sync
                $store->balance = $wallet->balance;
                $store->save();

                return $createdOffer;
            });

            return response()->json([
                'success' => true,
                'message' => 'Offer created successfully. Creation fee deducted from merchant wallet.',
                'data' => new OfferResource($offer->load('store')),
            ], 201);

        } catch (Exception $e) {
            if ($e->getMessage() === 'INSUFFICIENT_FEE_BALANCE') {
                return response()->json([
                    'success' => false,
                    'message' => "Merchant wallet balance is insufficient for offer creation fee of {$creationFee} D.L.",
                    'error_code' => 'INSUFFICIENT_FEE_BALANCE',
                    'required_amount' => $creationFee,
                    'current_balance' => (float) ($store->wallet->balance ?? $store->balance ?? 0.00),
                ], 402);
            }

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'error_code' => 'OFFER_CREATION_FAILED',
            ], 500);
        }
    }

    /**
     * POST /api/v1/merchant/offers/{id}/update
     * Updates existing offer and syncs changes to MySQL coupons and campaigns.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $offer = Offer::find($id);

        if (! $offer) {
            return response()->json([
                'success' => false,
                'message' => 'Offer not found.',
                'error_code' => 'RESOURCE_NOT_FOUND',
            ], 404);
        }

        if ($request->filled('title')) {
            $offer->title = $request->title;
        }
        if ($request->filled('description')) {
            $offer->description = $request->description;
        }
        if ($request->filled('category')) {
            $offer->category = $request->category;
        }
        if ($request->filled('discount_badge')) {
            $offer->discount_badge = $request->discount_badge;
        }
        if ($request->filled('original_price')) {
            $offer->original_price = (float) $request->original_price;
        }
        if ($request->filled('discount_rate')) {
            $offer->discount_rate = (float) $request->discount_rate;
        }
        if ($request->filled('final_price')) {
            $offer->final_price = (float) $request->final_price;
        }
        if ($request->filled('valid_until')) {
            $offer->valid_until = $request->valid_until;
        }
        if ($request->has('is_active')) {
            $offer->is_active = (bool) $request->is_active;
        }

        $offer->save();

        // Sync with linked Coupon
        $coupon = Coupon::where('offer_id', $offer->id)->first();
        if ($coupon) {
            if ($request->filled('title')) $coupon->title = $offer->title;
            if ($request->filled('valid_until')) $coupon->expires_at = $offer->valid_until;
            if ($request->filled('discount_value')) $coupon->discount_value = (float) $request->discount_value;
            $coupon->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Offer updated successfully.',
            'data' => new OfferResource($offer->load('store')),
        ]);
    }

    /**
     * DELETE /api/v1/merchant/offers/{id}
     * Deletes an offer and its associated coupons from MySQL database.
     */
    public function destroy(int $id): JsonResponse
    {
        $offer = Offer::find($id);

        if ($offer) {
            Coupon::where('offer_id', $offer->id)->delete();
            $offer->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Offer deleted successfully from database.',
        ]);
    }
}
