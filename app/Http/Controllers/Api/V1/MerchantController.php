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

        if (! $merchant || ! $merchant->isMerchant()) {
            return response()->json([
                'message' => 'Unauthorized: User is not associated with a merchant store.',
            ], 403);
        }

        $store = $merchant->store ?? \App\Models\Store::find($merchant->store_id) ?? \App\Models\Store::first();

        if (! $store) {
            return response()->json([
                'message' => 'Merchant store entity not found.',
            ], 404);
        }

        $storeId = $store->id;
        $wallet = $store->getOrCreateWallet();

        $todayRedemptionsCount = Redemption::query()
            ->where('store_id', $storeId)
            ->whereDate('redeemed_at', today())
            ->count();

        $totalRedemptionsCount = Redemption::query()
            ->where('store_id', $storeId)
            ->count();

        $totalPendingFees = (float) Redemption::query()
            ->where('store_id', $storeId)
            ->sum('charged_fee');

        $todayPendingFees = (float) Redemption::query()
            ->where('store_id', $storeId)
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
     * List redemption audit logs for the authenticated merchant's store.
     */
    public function history(Request $request): JsonResponse
    {
        $merchant = $request->user();

        if (! $merchant) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 403);
        }

        $storeId = $merchant->store_id ?? 1;

        $redemptions = Redemption::query()
            ->with(['coupon:id,title,code,discount_type,discount_value', 'user:id,name,email,phone'])
            ->where('store_id', $storeId)
            ->latest('redeemed_at')
            ->get();

        return response()->json([
            'data' => $redemptions,
        ]);
    }
}
