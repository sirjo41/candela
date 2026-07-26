<?php

namespace App\Filament\Owner\Resources\BranchResource\Pages;

use App\Filament\Owner\Resources\BranchResource;
use Filament\Resources\Pages\CreateRecord;

class CreateBranch extends CreateRecord
{
    protected static string $resource = BranchResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['store_id'] = auth()->user()?->store_id;

        return $data;
    }
}
