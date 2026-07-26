<?php

namespace App\Filament\Resources\StoreOwnerResource\Pages;

use App\Filament\Resources\StoreOwnerResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListStoreOwners extends ListRecords
{
    protected static string $resource = StoreOwnerResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
