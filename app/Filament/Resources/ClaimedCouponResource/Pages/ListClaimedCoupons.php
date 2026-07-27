<?php

namespace App\Filament\Resources\ClaimedCouponResource\Pages;

use App\Filament\Resources\ClaimedCouponResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListClaimedCoupons extends ListRecords
{
    protected static string $resource = ClaimedCouponResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
