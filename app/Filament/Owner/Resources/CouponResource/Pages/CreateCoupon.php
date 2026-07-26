<?php

namespace App\Filament\Owner\Resources\CouponResource\Pages;

use App\Filament\Owner\Resources\CouponResource;
use Filament\Resources\Pages\CreateRecord;

class CreateCoupon extends CreateRecord
{
    protected static string $resource = CouponResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['store_id'] = auth()->user()?->store_id;

        return $data;
    }
}
