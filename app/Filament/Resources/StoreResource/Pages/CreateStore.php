<?php

namespace App\Filament\Resources\StoreResource\Pages;

use App\Filament\Resources\StoreResource;
use App\Models\User;
use Filament\Resources\Pages\CreateRecord;

class CreateStore extends CreateRecord
{
    protected static string $resource = StoreResource::class;

    protected function afterCreate(): void
    {
        /** @var array $data */
        $data = $this->form->getRawState();
        $store = $this->record;

        $option = $data['owner_option'] ?? 'none';

        if ($option === 'existing' && !empty($data['existing_owner_id'])) {
            $user = User::find($data['existing_owner_id']);
            if ($user) {
                $user->update([
                    'role' => 'merchant',
                    'store_id' => $store->id,
                ]);
            }
        } elseif ($option === 'new' && !empty($data['new_owner_email'])) {
            User::create([
                'name' => $data['new_owner_name'],
                'email' => $data['new_owner_email'],
                'phone' => $data['new_owner_phone'] ?? null,
                'password' => $data['new_owner_password'],
                'role' => 'merchant',
                'store_id' => $store->id,
                'is_active' => true,
            ]);
        }
    }
}
