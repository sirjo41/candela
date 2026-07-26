<?php

namespace App\Filament\Widgets;

use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return [
            Stat::make('Active Merchants (المتاجر النشطة)', Store::where('is_active', true)->count())
                ->description('Total active stores on platform')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('success'),

            Stat::make('Active Coupons (الكوبونات المتاحة)', Coupon::where('is_active', true)->count())
                ->description('Live merchant & campaign offers')
                ->descriptionIcon('heroicon-m-ticket')
                ->color('primary'),

            Stat::make('Total Redemptions (عمليات التفعيل)', Redemption::count())
                ->description('Dynamic QR scans completed')
                ->descriptionIcon('heroicon-m-qr-code')
                ->color('warning'),

            Stat::make('Platform Revenue (إجمالي الرسوم)', '$' . number_format(Redemption::sum('charged_fee'), 2))
                ->description('Creation & redemption fee earnings')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),
        ];
    }
}