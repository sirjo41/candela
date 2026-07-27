<?php

namespace App\Filament\Resources\ClaimedCouponResource\Pages;

use App\Filament\Resources\ClaimedCouponResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditClaimedCoupon extends EditRecord
{
    protected static string $resource = ClaimedCouponResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\ViewAction::make(),
            Actions\DeleteAction::make(),
        ];
    }
}
