<?php

namespace App\Filament\Owner\Widgets;

use App\Models\Coupon;
use App\Models\Redemption;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class OwnerStatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $storeId = auth()->user()?->store_id;

        if (!$storeId) {
            return [
                Stat::make('Store Status', 'No Store Assigned')
                    ->description('Please contact national admin')
                    ->color('danger'),
            ];
        }

        $activeCoupons = Coupon::query()
            ->where('store_id', $storeId)
            ->where('is_active', true)
            ->count();

        $totalRedemptions = Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->count();

        $totalFees = Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId))
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId));
            })
            ->sum('charged_fee');

        $topCoupon = Coupon::query()
            ->where('store_id', $storeId)
            ->withCount('redemptions')
            ->orderByDesc('redemptions_count')
            ->first();

        $topCouponText = $topCoupon
            ? "{$topCoupon->title} ({$topCoupon->redemptions_count} scans)"
            : 'No redemptions yet';

        return [
            Stat::make('Active Store Coupons (الكوبونات النشطة)', $activeCoupons)
                ->description('Live merchant offers')
                ->descriptionIcon('heroicon-m-ticket')
                ->color('primary'),

            Stat::make('Total Redemptions (عمليات التفعيل)', $totalRedemptions)
                ->description('Scans completed at store branches')
                ->descriptionIcon('heroicon-m-qr-code')
                ->color('success'),

            Stat::make('Total Incurred Fees (إجمالي الرسوم)', '$' . number_format($totalFees, 2))
                ->description('Redemption fee charges')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('warning'),

            Stat::make('Top Coupon Usage (أكثر الكوبونات تفعيلاً)', $topCouponText)
                ->description('Most redeemed offer breakdown')
                ->descriptionIcon('heroicon-m-fire')
                ->color('info'),
        ];
    }
}
