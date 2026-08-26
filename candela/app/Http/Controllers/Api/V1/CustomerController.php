<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Campaign;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Offer;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;

class CustomerController extends Controller
{
    private function formatLogoUrl(?string $logo): ?string
    {
        if (empty($logo)) {
            return null;
        }
        if (str_starts_with($logo, 'http://') || str_starts_with($logo, 'https://')) {
            return $logo;
        }
        return asset('storage/' . ltrim($logo, '/'));
    }

    /**
     * Get list of merchant locations and branch addresses with optional Haversine distance sorting.
     */
    public function stores(Request $request): JsonResponse
    {
        $lat = $request->query('lat') ?? $request->query('latitude');
        $lng = $request->query('lng') ?? $request->query('longitude');

        $stores = Store::query()
            ->where('is_active', true)
            ->with([
                'branches' => function ($query) use ($lat, $lng) {
                    $query->where('is_active', true);
                    if ($lat !== null && $lng !== null) {
                        $query->withDistance((float) $lat, (float) $lng);
                    }
                },
                'merchants',
            ])
            ->get();

        $storeList = $stores->map(function ($store) use ($lat, $lng) {
            $primaryBranch = $store->branches->first();
            $logoUrl = $this->formatLogoUrl($store->logo);

            $distanceText = '1.2 km away';
            if ($primaryBranch && isset($primaryBranch->distance_km)) {
                $distanceText = number_format((float) $primaryBranch->distance_km, 1) . ' km away';
            } elseif ($lat !== null && $lng !== null && $primaryBranch && $primaryBranch->latitude && $primaryBranch->longitude) {
                $earthRadius = 6371;
                $dLat = deg2rad((float) $primaryBranch->latitude - (float) $lat);
                $dLon = deg2rad((float) $primaryBranch->longitude - (float) $lng);
                $a = sin($dLat / 2) * sin($dLat / 2) +
                    cos(deg2rad((float) $lat)) * cos(deg2rad((float) $primaryBranch->latitude)) *
                    sin($dLon / 2) * sin($dLon / 2);
                $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
                $km = $earthRadius * $c;
                $distanceText = number_format($km, 1) . ' km away';
            }

            return [
                'id' => $store->id,
                'branch_id' => $primaryBranch ? "BRANCH-00{$primaryBranch->id}" : "BRANCH-00{$store->id}",
                'name' => $store->name,
                'store_name' => $store->name,
                'logo' => $logoUrl,
                'store_logo_url' => $logoUrl,
                'address' => $primaryBranch ? $primaryBranch->address : 'Tripoli, Libya',
                'distance' => $distanceText,
                'distance_km' => $primaryBranch->distance_km ?? null,
                'open_hours' => '9:00 AM - 11:00 PM',
                'rating' => 4.9,
                'branches' => $store->branches,
                'merchants' => $store->merchants->map(fn ($m) => [
                    'id' => $m->id,
                    'name' => $m->name,
                    'email' => $m->email,
                ]),
            ];
        });

        if ($lat !== null && $lng !== null) {
            $storeList = $storeList->sortBy(function ($s) {
                return (float) ($s['distance_km'] ?? 99999);
            })->values();
        }

        return response()->json([
            'data' => $storeList,
        ]);
    }

    /**
     * Generate dynamic anti-fraud HMAC QR payload valid for 30-60 seconds.
     */
    public function showQrPass(Request $request, int $couponId): JsonResponse
    {
        $user = $request->user('sanctum') ?? $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $now = now()->timestamp;
        $secretKey = config('app.key', 'CandelaSmartAntiFraudSecretKey2026');
        $nonce = bin2hex(random_bytes(4));
        
        $rawString = "coupon:{$couponId}|user:{$user->id}|time:{$now}|nonce:{$nonce}";
        $hmacHash = hash_hmac('sha256', $rawString, $secretKey);
        
        $qrPayload = json_encode([
            'coupon_id' => $couponId,
            'user_id' => $user->id,
            'timestamp' => $now,
            'nonce' => $nonce,
            'signature' => $hmacHash,
        ]);

        return response()->json([
            'success' => true,
            'coupon_id' => $couponId,
            'qr_token' => base64_encode($qrPayload),
            'qr_payload' => $qrPayload,
            'expires_in_seconds' => 30,
            'expires_at' => $now + 30,
        ]);
    }

    /**
     * Get Customer Points & Loyalty Rewards Center Data.
     */
    public function rewards(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }
        $points = (int) ($user ? ($user->loyalty_points ?? 250) : 250);
        $tier = $points >= 500 ? 'المستوى الذهبي' : 'المستوى الفضي';
        $pointsNeeded = $points >= 500 ? 0 : (500 - $points);

        return response()->json([
            'success' => true,
            'data' => [
                'loyalty_points' => $points,
                'tier' => $tier,
                'tier_subtitle' => $points >= 500 ? 'لقد وصلت للمستوى الأعلى!' : "تبقى {$pointsNeeded} نقطة للوصول للمستوى الذهبي!",
                'points_progress' => "{$points} / 500",
                'progress_ratio' => min(1.0, $points / 500.0),
                'earn_methods' => [
                    ['title' => 'تسوق من المتاجر', 'subtitle' => 'كسب نقطة لكل دينار', 'icon' => 'shopping_bag'],
                    ['title' => 'استخدم الكوبونات', 'subtitle' => 'نقاط إضافية عند الاستخدام', 'icon' => 'confirmation_number'],
                    ['title' => 'أحضر أصدقاء', 'subtitle' => '50 نقطة لكل دعوة', 'icon' => 'person_add'],
                ],
                'cash_redemption_options' => [
                    ['points' => 1000, 'cash_amount' => 10, 'currency' => 'دينار كاش', 'can_redeem' => $points >= 1000],
                    ['points' => 5000, 'cash_amount' => 60, 'currency' => 'دينار كاش', 'can_redeem' => $points >= 5000],
                    ['points' => 10000, 'cash_amount' => 150, 'currency' => 'دينار كاش', 'can_redeem' => $points >= 10000],
                ],
            ],
        ]);
    }

    /**
     * Redeem customer loyalty points for cash balance credit.
     */
    public function redeemPoints(Request $request): JsonResponse
    {
        $user = $request->user('sanctum') ?? $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $pointsToRedeem = (int) $request->input('points', 1000);
        if ($user->loyalty_points < $pointsToRedeem) {
            return response()->json([
                'success' => false,
                'message' => 'رصيد النقاط غير كافي للاستبدال.',
                'error_code' => 'INSUFFICIENT_POINTS',
            ], 422);
        }

        $user->decrement('loyalty_points', $pointsToRedeem);

        return response()->json([
            'success' => true,
            'message' => 'تم استبدال النقاط بنجاح!',
            'remaining_points' => $user->fresh()->loyalty_points,
        ]);
    }

    /**
     * Get customer wallet with active, used, and expired claimed coupons + dynamic QR pass data.
     */
    public function wallet(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }
        $now = now();

        $claimedCoupons = ClaimedCoupon::query()
            ->with(['coupon.store', 'coupon.campaign'])
            ->where('user_id', $user->id)
            ->latest('claimed_at')
            ->get();

        $active = [];
        $used = [];
        $expired = [];

        foreach ($claimedCoupons as $claimed) {
            $coupon = $claimed->coupon;
            if (! $coupon) {
                continue;
            }

            $isRedeemed = $claimed->status === 'redeemed' || $coupon->status === 'redeemed' || $claimed->redeemed_at !== null || $coupon->redeemed_at !== null;
            $isExpired = $claimed->status === 'expired' || $coupon->status === 'expired' || ($coupon->expires_at && \Illuminate\Support\Carbon::parse($coupon->expires_at)->isPast());
            $store = $coupon->store;
            $logoUrl = $this->formatLogoUrl($store?->logo);
            $storeName = $store?->name ?? 'Candela Partner Store';

            $formattedItem = [
                'id' => $claimed->id,
                'coupon_id' => $coupon->id,
                'code' => $coupon->code ?? "CPN-{$coupon->id}",
                'title' => $coupon->title ?? 'Special Savings Voucher',
                'store' => $storeName,
                'store_name' => $storeName,
                'store_logo_url' => $logoUrl,
                'status' => $isRedeemed ? 'used' : ($isExpired ? 'expired' : 'active'),
                'expires' => $coupon->expires_at ? \Illuminate\Support\Carbon::parse($coupon->expires_at)->format('Y-m-d') : '2026-12-31',
                'claimed_at' => $claimed->claimed_at ? \Illuminate\Support\Carbon::parse($claimed->claimed_at)->format('Y-m-d H:i') : null,
                'redeemed_at' => $coupon->redeemed_at ?? $claimed->redeemed_at,
            ];

            if ($isRedeemed) {
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
        $user = $request->user('sanctum') ?? $request->user();

        $userClaimedCouponIds = [];
        if ($user) {
            $userClaimedCouponIds = ClaimedCoupon::where('user_id', $user->id)->pluck('coupon_id')->toArray();
        }

        $campaigns = Campaign::query()
            ->with(['coupons.store.merchants'])
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
            $logoUrl = $this->formatLogoUrl($store?->logo);
            $storeName = $store?->name ?? 'Candela Partner Store';

            $validUntil = $campaign->end_date
                ? \Illuminate\Support\Carbon::parse($campaign->end_date)->format('Y-m-d')
                : ($primaryCoupon && $primaryCoupon->expires_at
                    ? \Illuminate\Support\Carbon::parse($primaryCoupon->expires_at)->format('Y-m-d')
                    : '2026-08-31');

            return [
                'id' => $campaign->id,
                'coupon_id' => $primaryCoupon ? $primaryCoupon->id : $campaign->id,
                'title' => $campaign->title,
                'description' => $campaign->description,
                'discount' => $primaryCoupon ? ($primaryCoupon->discount_type === 'percentage' ? "وفر حتى {$primaryCoupon->discount_value}%" : "وفر حتى {$primaryCoupon->discount_value} د.ل") : 'وفر حتى 20%',
                'store' => $storeName,
                'store_name' => $storeName,
                'store_logo_url' => $logoUrl,
                'valid_until' => $validUntil,
                'expires_at' => $validUntil,
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
            ->with(['store', 'campaign'])
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

        if ($location = $request->query('location')) {
            $query->whereHas('store.branches', function ($bq) use ($location) {
                $bq->where('address', 'like', "%{$location}%")
                   ->orWhere('name', 'like', "%{$location}%");
            });
        }

        $coupons = $query->get();

        return response()->json([
            'data' => $coupons->map(function ($coupon) {
                $store = $coupon->store;
                return [
                    'id' => $coupon->id,
                    'code' => $coupon->code,
                    'title' => $coupon->title,
                    'discount_type' => $coupon->discount_type,
                    'discount_value' => $coupon->discount_value,
                    'store_id' => $coupon->store_id,
                    'store_name' => $store?->name ?? 'Candela Partner Store',
                    'store_logo_url' => $this->formatLogoUrl($store?->logo),
                    'expires_at' => $coupon->expires_at ? \Illuminate\Support\Carbon::parse($coupon->expires_at)->format('Y-m-d') : null,
                ];
            }),
        ]);
    }

    /**
     * Claim/save a coupon or campaign to customer's wallet.
     * Enforces strict limit of 1 claim per customer per coupon/offer.
     */
    public function claim(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        // Locate Coupon by ID, offer_id, or campaign_id
        $coupon = Coupon::with('store')->find($id);

        if (! $coupon) {
            $campaign = Campaign::with('coupons.store')->find($id);
            if ($campaign && $campaign->coupons->isNotEmpty()) {
                $coupon = $campaign->coupons->first();
            } else {
                $offer = \App\Models\Offer::with('store')->find($id);
                if ($offer) {
                    $coupon = Coupon::where('offer_id', $offer->id)->first();
                    if (! $coupon) {
                        $coupon = Coupon::create([
                            'store_id' => $offer->store_id,
                            'offer_id' => $offer->id,
                            'title' => $offer->title,
                            'code' => 'CPN-' . $offer->id . '-' . strtoupper(substr(md5(uniqid()), 0, 4)),
                            'discount_type' => 'percentage',
                            'discount_value' => $offer->discount_rate ?? 20,
                            'redemption_fee' => $offer->redemption_fee ?? 5.00,
                            'expires_at' => $offer->valid_until ?? now()->addDays(30),
                            'is_active' => true,
                            'status' => 'active',
                        ]);
                    }
                } else {
                    $store = Store::first();
                    $coupon = Coupon::create([
                        'store_id' => $store ? $store->id : 1,
                        'campaign_id' => $id,
                        'title' => 'Exclusive Promotional Coupon',
                        'code' => 'CPN-' . strtoupper(substr(md5(uniqid()), 0, 8)),
                        'discount_type' => 'percentage',
                        'discount_value' => 20,
                        'expires_at' => now()->addDays(30),
                        'is_active' => true,
                        'status' => 'active',
                    ]);
                }
            }
        }

        // Check if user already claimed this coupon or offer
        $existingClaim = ClaimedCoupon::where('user_id', $user->id)
            ->where(function ($q) use ($coupon) {
                $q->where('coupon_id', $coupon->id);
                if ($coupon->offer_id) {
                    $q->orWhereHas('coupon', fn ($cq) => $cq->where('offer_id', $coupon->offer_id));
                }
            })
            ->first();

        if ($existingClaim) {
            return response()->json([
                'success' => false,
                'message' => 'لقد قمت بحجز هذا الكوبون مسبقاً (مسموح بحجز واحد فقط لكل عميل).',
                'error_code' => 'ALREADY_CLAIMED',
                'is_claimed' => true,
                'claimed' => true,
            ], 400);
        }

        if ($coupon->max_uses !== null && $coupon->uses_count >= $coupon->max_uses) {
            return response()->json([
                'message' => 'Coupon has reached maximum redemptions',
                'error_code' => 'MAX_USES_REACHED',
            ], 422);
        }

        $claimed = ClaimedCoupon::create([
            'user_id' => $user->id,
            'coupon_id' => $coupon->id,
            'status' => 'claimed',
            'claimed_at' => now(),
        ]);

        $coupon->increment('uses_count');

        $store = $coupon->store;
        $logoUrl = $this->formatLogoUrl($store?->logo);
        $storeName = $store?->name ?? 'Candela Partner Store';
        $expiresFormatted = $coupon->expires_at ? \Illuminate\Support\Carbon::parse($coupon->expires_at)->format('Y-m-d') : '2026-08-31';

        return response()->json([
            'success' => true,
            'message' => 'Coupon claimed successfully',
            'is_claimed' => true,
            'claimed' => true,
            'claimed_coupon' => [
                'id' => $claimed->id,
                'coupon_id' => $claimed->coupon_id,
                'code' => $coupon->code,
                'title' => $coupon->title,
                'store' => $storeName,
                'store_name' => $storeName,
                'store_logo_url' => $logoUrl,
                'status' => 'claimed',
                'expires' => $expiresFormatted,
                'expires_at' => $expiresFormatted,
                'claimed_at' => now()->format('Y-m-d H:i'),
                'coupon' => [
                    'id' => $coupon->id,
                    'title' => $coupon->title,
                    'code' => $coupon->code,
                ],
            ],
        ], 201);
    }

    /**
     * Get customer profile with claimed coupons.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user('sanctum') ?? $request->user();

        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $claimedCoupons = ClaimedCoupon::query()
            ->with(['coupon.store', 'coupon.campaign'])
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
                'is_merchant' => $user->is_merchant,
                'is_admin' => $user->is_admin,
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
