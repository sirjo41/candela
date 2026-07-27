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
            'data' => $stores->map(function ($store) {
                $primaryBranch = $store->branches->first();
                return [
                    'id' => $store->id,
                    'branch_id' => $primaryBranch ? "BRANCH-00{$primaryBranch->id}" : "BRANCH-00{$store->id}",
                    'name' => $store->name,
                    'logo' => $store->logo,
                    'address' => $primaryBranch ? $primaryBranch->address : 'Cairo, Egypt',
                    'distance' => '1.2 km away',
                    'open_hours' => '9:00 AM - 11:00 PM',
                    'rating' => 4.9,
                    'branches' => $store->branches,
                ];
            }),
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
            if (! $coupon) {
                continue;
            }

            $isExpired = $claimed->status === 'expired' || ($coupon->expires_at && \Illuminate\Support\Carbon::parse($coupon->expires_at)->isPast());

            $formattedItem = [
                'id' => $claimed->id,
                'coupon_id' => $coupon->id,
                'code' => $coupon->code ?? "CPN-{$coupon->id}",
                'title' => $coupon->title ?? 'Special Savings Voucher',
                'store' => $coupon->store ? $coupon->store->name : 'Candela Partner Store',
                'store_logo_url' => $coupon->store ? $coupon->store->logo : null,
                'status' => $claimed->status === 'redeemed' ? 'used' : ($isExpired ? 'expired' : 'active'),
                'expires' => $coupon->expires_at ? \Illuminate\Support\Carbon::parse($coupon->expires_at)->format('Y-m-d') : '2026-12-31',
                'claimed_at' => $claimed->claimed_at ? \Illuminate\Support\Carbon::parse($claimed->claimed_at)->format('Y-m-d H:i') : null,
            ];

            if ($claimed->status === 'redeemed') {
                $used[] = $formattedItem;
            } elseif ($isExpired) {
                $expired[] = $formattedItem;
            } else {
                $active[] = $formattedItem;
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
     * Get list of active campaigns with eager loaded stores and user claim status.
     */
    public function campaigns(Request $request): JsonResponse
    {
        $now = now();
        $user = $request->user('sanctum');

        $userClaimedCouponIds = [];
        if ($user) {
            $userClaimedCouponIds = ClaimedCoupon::where('user_id', $user->id)->pluck('coupon_id')->toArray();
        }

        $campaigns = Campaign::query()
            ->with(['coupons.store:id,name,logo'])
            ->where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('start_date')->orWhere('start_date', '<=', $now);
            })
            ->where(function ($q) use ($now) {
                $q->whereNull('end_date')->orWhere('end_date', '>=', $now);
            })
            ->get();

        $data = $campaigns->map(function ($campaign) use ($userClaimedCouponIds) {
            $primaryCoupon = $campaign->coupons->first();
            $store = $primaryCoupon ? $primaryCoupon->store : null;
            $isClaimed = $primaryCoupon && in_array($primaryCoupon->id, $userClaimedCouponIds);

            return [
                'id' => $campaign->id,
                'coupon_id' => $primaryCoupon ? $primaryCoupon->id : $campaign->id,
                'title' => $campaign->title,
                'description' => $campaign->description,
                'discount' => $primaryCoupon ? ($primaryCoupon->discount_type === 'percentage' ? "{$primaryCoupon->discount_value}% OFF" : "EGP {$primaryCoupon->discount_value} OFF") : 'SPECIAL OFFER',
                'store' => $store ? $store->name : 'Candela Partner Stores',
                'store_name' => $store ? $store->name : 'Candela Partner Stores',
                'store_logo_url' => $store ? $store->logo : null,
                'valid_until' => $campaign->end_date ? \Illuminate\Support\Carbon::parse($campaign->end_date)->format('Y-m-d') : ($primaryCoupon && $primaryCoupon->expires_at ? \Illuminate\Support\Carbon::parse($primaryCoupon->expires_at)->format('Y-m-d') : '2026-08-31'),
                'image_color' => 0xFF1E3A8A,
                'claimed' => $isClaimed,
                'is_claimed' => $isClaimed,
            ];
        });

        return response()->json([
            'data' => $data,
        ]);
    }

    /**
     * Get list of active coupons.
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

        if ($storeId = $request->query('store_id') ?? $request->query('store')) {
            $query->where('store_id', $storeId);
        }

        if ($campaignId = $request->query('campaign_id') ?? $request->query('campaign')) {
            $query->where('campaign_id', $campaignId);
        }

        $coupons = $query->get();

        return response()->json([
            'data' => $coupons,
        ]);
    }

    /**
     * Claim/save a coupon or campaign to customer's wallet.
     */
    public function claim(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        // Check if $id refers to a Coupon or Campaign
        $coupon = Coupon::find($id);

        if (! $coupon) {
            // Find coupon by campaign_id or create default coupon for campaign
            $campaign = Campaign::with('coupons')->find($id);
            if ($campaign && $campaign->coupons->isNotEmpty()) {
                $coupon = $campaign->coupons->first();
            } else {
                $store = Store::first();
                $coupon = Coupon::create([
                    'store_id' => $store ? $store->id : 1,
                    'campaign_id' => $id,
                    'title' => $campaign ? $campaign->title : 'Exclusive Offer',
                    'code' => 'CPN-' . strtoupper(substr(md5(uniqid()), 0, 8)),
                    'discount_type' => 'percentage',
                    'discount_value' => 20,
                    'expires_at' => now()->addDays(30),
                    'is_active' => true,
                ]);
            }
        }

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

        $coupon->increment('uses_count');

        return response()->json([
            'message' => 'Coupon claimed successfully',
            'is_claimed' => true,
            'claimed' => true,
            'claimed_coupon' => [
                'id' => $claimed->id,
                'coupon_id' => $claimed->coupon_id,
                'code' => $coupon->code,
                'title' => $coupon->title,
                'store' => $coupon->store ? $coupon->store->name : 'Candela Partner Store',
                'store_logo_url' => $coupon->store ? $coupon->store->logo : null,
                'status' => 'active',
                'expires' => $coupon->expires_at ? \Illuminate\Support\Carbon::parse($coupon->expires_at)->format('Y-m-d') : '2026-08-31',
                'claimed_at' => now()->format('Y-m-d H:i'),
            ],
        ], 200);
    }

    /**
     * Get customer profile with claimed coupons.
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
