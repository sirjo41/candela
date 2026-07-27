<?php

namespace App\Filament\Resources\ClaimedCouponResource\Pages;

use App\Filament\Resources\ClaimedCouponResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;

class ViewClaimedCoupon extends ViewRecord
{
    protected static string $resource = ClaimedCouponResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make(),
        ];
    }
}
