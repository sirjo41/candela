<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\User;
use Filament\Actions\CreateAction;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Database\Eloquent\Builder;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    public function getTabs(): array
    {
        return [
            'all' => Tab::make('All Users / كل المستخدمين')
                ->icon('heroicon-o-users')
                ->badge(User::count()),
            'customers' => Tab::make('Customers / العملاء')
                ->icon('heroicon-o-user-group')
                ->badge(User::query()->customers()->count())
                ->modifyQueryUsing(fn (Builder $query) => $query->customers()),
            'store_owners' => Tab::make('Store Owners / ملاك المتاجر')
                ->icon('heroicon-o-building-storefront')
                ->badge(User::query()->storeOwners()->count())
                ->modifyQueryUsing(fn (Builder $query) => $query->storeOwners()),
            'admins' => Tab::make('Admins / المسؤولون')
                ->icon('heroicon-o-shield-check')
                ->badge(User::query()->admins()->count())
                ->modifyQueryUsing(fn (Builder $query) => $query->admins()),
        ];
    }
}
