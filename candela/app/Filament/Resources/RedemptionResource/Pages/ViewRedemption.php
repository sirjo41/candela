<?php

namespace App\Filament\Resources\RedemptionResource\Pages;

use App\Filament\Resources\RedemptionResource;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewRedemption extends ViewRecord
{
    protected static string $resource = RedemptionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            EditAction::make(),
        ];
    }
}
