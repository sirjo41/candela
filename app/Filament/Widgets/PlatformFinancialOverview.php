<?php

namespace App\Filament\Widgets;

use App\Models\Coupon;
use App\Models\Redemption;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class PlatformFinancialOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalCreationFees = Coupon::sum('creation_fee');
        $totalRedemptionFees = Redemption::sum('charged_fee');
        $grossRevenue = $totalCreationFees + $totalRedemptionFees;

        return [
            Stat::make('Total Platform Creation Fees', '$' . number_format($totalCreationFees, 2))
                ->description('Total fees accrued from coupon creation')
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('info'),
            Stat::make('Total Platform Redemption Fees', '$' . number_format($totalRedemptionFees, 2))
                ->description('Total fees accrued from coupon redemptions')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('info'),
            Stat::make('Gross Platform Revenue', '$' . number_format($grossRevenue, 2))
                ->description('Total creation + redemption fees')
                ->descriptionIcon('heroicon-m-chart-bar')
                ->color('success'),
        ];
    }
}
