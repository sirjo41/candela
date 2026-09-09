<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\Offer;
use App\Models\Redemption;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantController extends Controller
{
    /**
     * Get merchant dashboard summary: today's redemptions, pending fees, active coupons count, store profile & wallet balance.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $merchant = $request->user();
        if (! $merchant) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $store = $merchant->store ?? \App\Models\Store::find($merchant->store_id) ?? \App\Models\Store::first();

        if (! $store) {
            $store = \App\Models\Store::create([
                'name' => 'Candela Partner Store',
                'balance' => 500.00,
                'is_active' => true,
            ]);
        }

        $storeId = $store->id;
        $wallet = $store->getOrCreateWallet();

        $todayRedemptionsCount = Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->whereDate('redeemed_at', today())
            ->count();

        $redemptionsTableCount = Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->count();

        $couponUsesSum = (int) Coupon::where('store_id', $storeId)->sum('uses_count');
        $claimedRedeemedCount = \App\Models\ClaimedCoupon::whereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
            ->whereIn('status', ['redeemed', 'used'])
            ->count();
        $couponRedeemedCount = Coupon::where('store_id', $storeId)
            ->whereIn('status', ['redeemed', 'used'])
            ->count();

        $totalRedemptionsCount = max($redemptionsTableCount, $couponUsesSum, $claimedRedeemedCount, $couponRedeemedCount);


        $totalPendingFees = (float) Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->sum('charged_fee');

        $todayPendingFees = (float) Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->whereDate('redeemed_at', today())
            ->sum('charged_fee');

        $activeOffersCount = Offer::query()
            ->where('store_id', $storeId)
            ->where('is_active', true)
            ->count();

        $activeCouponsCount = Coupon::query()
            ->where('store_id', $storeId)
            ->where('is_active', true)
            ->count();

        $activeCount = max($activeOffersCount, $activeCouponsCount);
        $currentBalance = (float) ($wallet->balance ?? $store->balance ?? 0.00);

        return response()->json([
            'todays_redemptions' => $todayRedemptionsCount,
            'total_redemptions' => $totalRedemptionsCount,
            'today_pending_fees' => $todayPendingFees,
            'total_pending_fees' => $totalPendingFees,
            'active_coupons_count' => $activeCount,
            'active_offers_count' => $activeCount,
            'wallet_balance' => $currentBalance,
            'dashboard' => [
                'today_redemptions' => $todayRedemptionsCount,
                'total_redemptions' => $totalRedemptionsCount,
                'today_pending_fees' => $todayPendingFees,
                'total_pending_fees' => $totalPendingFees,
                'active_coupons_count' => $activeCount,
                'wallet_balance' => $currentBalance,
            ],
            'merchant' => [
                'id' => $merchant->id,
                'name' => $merchant->name,
                'email' => $merchant->email,
                'store_id' => $storeId,
            ],
            'store' => [
                'id' => $store->id,
                'name' => $store->name,
                'is_active' => $store->is_active,
                'balance' => $currentBalance,
                'wallet_balance' => $currentBalance,
                'creation_fee_rate' => (float) $store->creation_fee_rate,
                'redemption_fee_rate' => (float) $store->redemption_fee_rate,
            ],
        ]);
    }

    /**
    /**
     * List read-only redemption audit ledger for the authenticated merchant's store branches.
     */
    public function history(Request $request): JsonResponse
    {
        $merchant = $request->user();

        if (! $merchant) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401);
        }

        $storeId = $merchant->store_id ?? $merchant->store?->id ?? 1;

        $query = Redemption::query()
            ->with([
                'coupon:id,title,code,discount_type,discount_value',
                'user:id,name,email,phone',
                'branch:id,name,address',
                'staffUser:id,name',
            ])
            ->where(function ($q) use ($storeId) {
                $q->whereHas('branch', fn ($bq) => $bq->where('store_id', $storeId))
                  ->orWhere('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId));
            });

        // Optional branch filter
        if ($branchId = $request->query('branch_id')) {
            $query->where('branch_id', $branchId);
        }

        $redemptions = $query->latest('redeemed_at')->get();

        $totalRedemptions = $redemptions->count();
        $totalChargedFees = (float) $redemptions->sum('charged_fee');
        $todayRedemptions = $redemptions->filter(fn ($r) => $r->redeemed_at && $r->redeemed_at->isToday())->count();
        $todayChargedFees = (float) $redemptions->filter(fn ($r) => $r->redeemed_at && $r->redeemed_at->isToday())->sum('charged_fee');

        $data = $redemptions->map(function ($r) {
            return [
                'id' => $r->id,
                'coupon_id' => $r->coupon_id,
                'coupon_title' => $r->coupon?->title ?? 'كوبون خصم',
                'coupon_code' => $r->coupon?->code ?? 'CPN',
                'discount_type' => $r->coupon?->discount_type ?? 'percentage',
                'discount_value' => (float) ($r->coupon?->discount_value ?? 0),
                'customer_id' => $r->user_id,
                'customer_name' => $r->user?->name ?? 'عميل كانديلا',
                'customer_phone' => $r->user?->phone ?? '—',
                'customer_email' => $r->user?->email,
                'branch_id' => $r->branch_id,
                'branch_name' => $r->branch?->name ?? 'الفرع الرئيسي',
                'branch_address' => $r->branch?->address ?? 'طرابلس',
                'staff_name' => $r->staffUser?->name ?? 'موظف المتجر',
                'points_awarded' => (int) $r->points_awarded,
                'charged_fee' => (float) $r->charged_fee,
                'qr_code_hash' => $r->qr_code_hash,
                'status' => $r->status ?? 'completed',
                'redeemed_at' => $r->redeemed_at?->toIso8601String(),
                'redeemed_at_formatted' => $r->redeemed_at?->format('Y-m-d H:i'),
            ];
        });

        return response()->json([
            'success' => true,
            'summary' => [
                'total_redemptions' => $totalRedemptions,
                'total_charged_fees' => $totalChargedFees,
                'today_redemptions' => $todayRedemptions,
                'today_charged_fees' => $todayChargedFees,
            ],
            'data' => $data,
        ], 200);
    }

    /**
     * GET /api/v1/merchant/store-qr
     * Returns the store QR payload for merchant display at checkout counter.
     * Customer scans this to select and redeem a coupon.
     */
    public function storeQr(Request $request): JsonResponse
    {
        $merchant = $request->user();
        if (! $merchant) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $store = $merchant->store ?? \App\Models\Store::find($merchant->store_id) ?? \App\Models\Store::first();

        if (! $store) {
            return response()->json([
                'success' => false,
                'message' => 'No store found for this merchant account.',
                'error_code' => 'STORE_NOT_FOUND',
            ], 404);
        }

        $secretKey = config('app.key', 'CandelaSmartAntiFraudSecretKey2026');
        $timestamp = now()->timestamp;
        $storeToken = hash_hmac('sha256', "STORE:{$store->id}:{$timestamp}", $secretKey);

        // Build QR payload that the customer app reads
        $qrPayload = [
            'type'       => 'store',
            'store_id'   => $store->id,
            'store_name' => $store->name,
            'token'      => $storeToken,
            'issued_at'  => $timestamp,
        ];
        $qrData = base64_encode(json_encode($qrPayload));

        $branches = $store->branches()->where('is_active', true)->get(['id', 'name', 'address']);
        $wallet   = $store->getOrCreateWallet();

        return response()->json([
            'success'        => true,
            'qr_data'        => $qrData,
            'store_id'       => $store->id,
            'store_name'     => $store->name,
            'store_logo'     => $store->logo ? asset('storage/' . ltrim($store->logo, '/')) : null,
            'redemption_fee' => (float) ($store->redemption_fee_rate ?? 5.00),
            'wallet_balance' => (float) ($wallet->balance ?? $store->balance ?? 0.0),
            'branches'       => $branches,
        ], 200);
    }
}
