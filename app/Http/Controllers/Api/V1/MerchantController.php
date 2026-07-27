<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\Redemption;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantController extends Controller
{
    /**
     * Get merchant dashboard summary: today's redemptions, pending fees, active coupons count, store profile.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $merchant = $request->user();

        if (! $merchant->isMerchant() || ! $merchant->store_id) {
            return response()->json([
                'message' => 'Unauthorized: User is not associated with a merchant store.',
            ], 403);
        }

        $storeId = $merchant->store_id;

        $todayRedemptionsCount = Redemption::query()
            ->whereHas('branch', fn ($q) => $q->where('store_id', $storeId))
            ->whereDate('redeemed_at', today())
            ->count();

        $totalRedemptionsCount = Redemption::query()
            ->whereHas('branch', fn ($q) => $q->where('store_id', $storeId))
            ->count();

        $totalPendingFees = (float) Redemption::query()
            ->whereHas('branch', fn ($q) => $q->where('store_id', $storeId))
            ->sum('charged_fee');

        $todayPendingFees = (float) Redemption::query()
            ->whereHas('branch', fn ($q) => $q->where('store_id', $storeId))
            ->whereDate('redeemed_at', today())
            ->sum('charged_fee');

        $activeCouponsCount = Coupon::query()
            ->where('store_id', $storeId)
            ->where('is_active', true)
            ->where('expires_at', '>', now())
            ->count();

        return response()->json([
            'dashboard' => [
                'today_redemptions' => $todayRedemptionsCount,
                'total_redemptions' => $totalRedemptionsCount,
                'today_pending_fees' => $todayPendingFees,
                'total_pending_fees' => $totalPendingFees,
                'active_coupons_count' => $activeCouponsCount,
            ],
            'merchant' => [
                'id' => $merchant->id,
                'name' => $merchant->name,
                'email' => $merchant->email,
                'store_id' => $merchant->store_id,
            ],
            'store' => $merchant->store ? [
                'id' => $merchant->store->id,
                'name' => $merchant->store->name,
                'is_active' => $merchant->store->is_active,
                'creation_fee_rate' => (float) $merchant->store->creation_fee_rate,
                'redemption_fee_rate' => (float) $merchant->store->redemption_fee_rate,
            ] : null,
        ]);
    }

    /**
     * List redemption audit logs for the authenticated merchant's store.
     */
    public function history(Request $request): JsonResponse
    {
        $merchant = $request->user();

        if (! $merchant->isMerchant() || ! $merchant->store_id) {
            return response()->json([
                'message' => 'Unauthorized: User is not associated with a merchant store.',
            ], 403);
        }

        $storeId = $merchant->store_id;

        $redemptions = Redemption::query()
            ->with(['coupon:id,title,code,discount_type,discount_value', 'user:id,name,email,phone', 'branch:id,name,address'])
            ->whereHas('branch', fn ($q) => $q->where('store_id', $storeId))
            ->latest('redeemed_at')
            ->get();

        return response()->json([
            'data' => $redemptions,
        ]);
    }
}
