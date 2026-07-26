<?php

namespace App\Filament\Resources\StoreOwnerResource\Pages;

use App\Filament\Resources\StoreOwnerResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditStoreOwner extends EditRecord
{
    protected static string $resource = StoreOwnerResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
