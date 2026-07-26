<?php

namespace App\Filament\Resources\Redemptions\Pages;

use App\Filament\Resources\Redemptions\RedemptionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListRedemptions extends ListRecords
{
    protected static string $resource = RedemptionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
