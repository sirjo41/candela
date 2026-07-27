<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Campaign;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Store;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;

class CustomerController extends Controller
{
    /**
     * Get list of merchant locations and branch addresses.
     */
    public function stores(Request $request): JsonResponse
    {
        $stores = Store::query()
            ->where('is_active', true)
            ->with(['branches' => fn ($query) => $query->where('is_active', true)])
            ->get();

        return response()->json([
            'data' => $stores,
        ]);
    }

    /**
     * Get customer wallet with active, used, and expired claimed coupons + dynamic QR pass data.
     */
    public function wallet(Request $request): JsonResponse
    {
        $user = $request->user();
        $now = now();

        $claimedCoupons = ClaimedCoupon::query()
            ->with(['coupon.store:id,name,logo', 'coupon.campaign:id,title'])
            ->where('user_id', $user->id)
            ->get();

        $active = [];
        $used = [];
        $expired = [];

        foreach ($claimedCoupons as $claimed) {
            $coupon = $claimed->coupon;
            $isExpired = $claimed->status === 'expired' || ($coupon && $coupon->expires_at && \Illuminate\Support\Carbon::parse($coupon->expires_at)->isPast());

            if ($claimed->status === 'redeemed') {
                $used[] = $claimed;
            } elseif ($isExpired) {
                $expired[] = $claimed;
            } else {
                $active[] = $claimed;
            }
        }

        $qrPassData = [
            'user_id' => $user->id,
            'name' => $user->name,
            'phone' => $user->phone,
            'loyalty_points' => $user->loyalty_points,
            'dynamic_pass_payload' => Crypt::encrypt(json_encode([
                'user_id' => $user->id,
                'created_at' => $now->timestamp,
                'expires_at' => $now->copy()->addMinutes(15)->timestamp,
            ])),
        ];

        return response()->json([
            'wallet' => [
                'active' => $active,
                'used' => $used,
                'expired' => $expired,
                'qr_pass' => $qrPassData,
            ],
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'loyalty_points' => $user->loyalty_points,
            ],
        ]);
    }
    /**
     * Get list of active campaigns.
     */
    public function campaigns(Request $request): JsonResponse
    {
        $now = now();

        $campaigns = Campaign::query()
            ->where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('start_date')->orWhere('start_date', '<=', $now);
            })
            ->where(function ($q) use ($now) {
                $q->whereNull('end_date')->orWhere('end_date', '>=', $now);
            })
            ->get(['id', 'title', 'description', 'banner_image', 'start_date', 'end_date', 'is_active']);

        return response()->json([
            'data' => $campaigns,
        ]);
    }

    /**
     * Get list of active coupons with optional filtering.
     */
    public function coupons(Request $request): JsonResponse
    {
        $now = now();

        $query = Coupon::query()
            ->with(['store:id,name,logo', 'campaign:id,title'])
            ->where('is_active', true)
            ->where('expires_at', '>', $now)
            ->where(function ($q) {
                $q->whereNull('max_uses')->orWhereColumn('uses_count', '<', 'max_uses');
            });

        // Filter by store
        if ($storeId = $request->query('store_id') ?? $request->query('store')) {
            $query->where('store_id', $storeId);
        }

        // Filter by campaign
        if ($campaignId = $request->query('campaign_id') ?? $request->query('campaign')) {
            $query->where('campaign_id', $campaignId);
        }

        // Filter by location
        if ($location = $request->query('location')) {
            $query->whereHas('store.branches', function ($bQuery) use ($location) {
                $bQuery->where('address', 'like', "%{$location}%")
                    ->orWhere('name', 'like', "%{$location}%");
            });
        }

        $coupons = $query->get();

        return response()->json([
            'data' => $coupons,
        ]);
    }

    /**
     * Claim/save a coupon to customer's wallet.
     */
    public function claim(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $coupon = Coupon::query()
            ->where('is_active', true)
            ->where('expires_at', '>', now())
            ->findOrFail($id);

        if ($coupon->max_uses !== null && $coupon->uses_count >= $coupon->max_uses) {
            return response()->json([
                'message' => 'Coupon has reached maximum redemptions',
            ], 422);
        }

        $claimed = ClaimedCoupon::firstOrCreate(
            [
                'user_id' => $user->id,
                'coupon_id' => $coupon->id,
            ],
            [
                'status' => 'claimed',
                'claimed_at' => now(),
            ]
        );

        return response()->json([
            'message' => 'Coupon claimed successfully',
            'claimed_coupon' => [
                'id' => $claimed->id,
                'coupon_id' => $claimed->coupon_id,
                'status' => $claimed->status,
                'claimed_at' => $claimed->claimed_at,
                'coupon' => [
                    'id' => $coupon->id,
                    'title' => $coupon->title,
                    'code' => $coupon->code,
                    'discount_type' => $coupon->discount_type,
                    'discount_value' => $coupon->discount_value,
                    'expires_at' => $coupon->expires_at,
                    'store' => $coupon->store ? [
                        'id' => $coupon->store->id,
                        'name' => $coupon->store->name,
                    ] : null,
                ],
            ],
        ], 201);
    }

    /**
     * Get customer profile with claimed coupons and loyalty point balances.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        $claimedCoupons = ClaimedCoupon::query()
            ->with(['coupon.store:id,name,logo', 'coupon.campaign:id,title'])
            ->where('user_id', $user->id)
            ->get();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'loyalty_points' => $user->loyalty_points,
                'role' => $user->role,
            ],
            'claimed_coupons' => $claimedCoupons->map(function ($claimed) {
                return [
                    'id' => $claimed->id,
                    'status' => $claimed->status,
                    'claimed_at' => $claimed->claimed_at,
                    'redeemed_at' => $claimed->redeemed_at,
                    'coupon' => $claimed->coupon,
                ];
            }),
        ]);
    }
}
