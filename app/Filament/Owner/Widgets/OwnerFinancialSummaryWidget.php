<?php

namespace App\Filament\Owner\Widgets;

use App\Models\Coupon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class OwnerFinancialSummaryWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $store = auth()->user()?->store;

        if (!$store) {
            return [];
        }

        return [
            Stat::make('Creation Fees Incurred', '$' . number_format($store->total_creation_fees, 2))
                ->description('Fees from creating coupons')
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('warning'),
            Stat::make('Redemption Fees Incurred', '$' . number_format($store->total_redemption_fees, 2))
                ->description('Fees from scanned redemptions')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('warning'),
            Stat::make('Total Account Balance Due', '$' . number_format($store->grand_total_fees, 2))
                ->description('Total platform fees incurred')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('danger'),
        ];
    }
}
