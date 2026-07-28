<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Offer\CreateOfferRequest;
use App\Http\Requests\Api\V1\Offer\FilterOfferRequest;
use App\Http\Resources\Api\V1\OfferResource;
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
     * POST /api/v1/merchant/offers/create
     * Creates a new offer and automatically checks/deducts the Creation Fee from merchant's wallet.
     */
    public function create(CreateOfferRequest $request): JsonResponse
    {
        $user = $request->user();
        $store = $user->store ?? Store::find($user->store_id) ?? Store::first();

        if (! $store) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'STORE_NOT_FOUND',
                    'message' => 'No active merchant store associated with this staff account.',
                ],
            ], 404);
        }

        $creationFee = (float) ($request->creation_fee ?? $store->creation_fee_rate ?? 50.00);
        $redemptionFee = (float) ($request->redemption_fee ?? $store->redemption_fee_rate ?? 5.00);

        try {
            $offer = DB::transaction(function () use ($request, $store, $creationFee, $redemptionFee) {
                // 1. Fetch & lock Merchant Wallet
                $wallet = $store->getOrCreateWallet();

                // 2. Check sufficient balance for Creation Fee
                if ((float) $wallet->balance < $creationFee) {
                    throw new Exception('INSUFFICIENT_MERCHANT_BALANCE');
                }

                // 3. Dynamic discount & final price calculation in D.L
                $originalPrice = (float) $request->original_price;
                $discountRate = (float) $request->discount_rate;
                $finalPrice = Offer::calculateFinalPrice($originalPrice, $discountRate);

                // 4. Create Offer record
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
                    'discount_badge' => $request->discount_badge ?? ('-' . (int) $discountRate . '%'),
                    'banner_image' => $request->banner_image,
                    'branch_location' => $request->branch_location ?? $store->address ?? 'Downtown Branch',
                    'latitude' => $request->latitude ?? $store->latitude,
                    'longitude' => $request->longitude ?? $store->longitude,
                    'valid_until' => $request->valid_until,
                    'is_active' => true,
                ]);

                // 5. Atomically deduct Creation Fee from Merchant Wallet
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
            if ($e->getMessage() === 'INSUFFICIENT_MERCHANT_BALANCE') {
                return response()->json([
                    'success' => false,
                    'error' => [
                        'code' => 'INSUFFICIENT_MERCHANT_BALANCE',
                        'message' => "Merchant wallet balance is insufficient for the offer creation fee of {$creationFee} D.L.",
                        'required_amount' => $creationFee,
                        'current_balance' => (float) ($store->wallet->balance ?? $store->balance ?? 0.00),
                    ],
                ], 422);
            }

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'OFFER_CREATION_FAILED',
                    'message' => $e->getMessage(),
                ],
            ], 500);
        }
    }
}
