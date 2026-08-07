<?php

namespace App\Filament\Owner\Resources;

use App\Filament\Owner\Resources\MyStoreResource\Pages;
use App\Models\Store;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class MyStoreResource extends Resource
{
    protected static ?string $model = Store::class;
    protected static ?string $navigationLabel = 'My Store / متجري';
    protected static ?string $modelLabel = 'Store Profile';
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-building-storefront';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('id', auth()->user()?->store_id);
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                TextInput::make('name')
                    ->label('Store Name / اسم المتجر')
                    ->required()
                    ->maxLength(255),

                TextInput::make('phone')
                    ->label('Phone Number / رقم الهاتف')
                    ->tel()
                    ->required(),

                FileUpload::make('logo')
                    ->label('Store Logo / شعار المتجر')
                    ->image()
                    ->directory('stores')
                    ->columnSpanFull(),

                Toggle::make('is_active')
                    ->label('Active Status / مفعل')
                    ->disabled()
                    ->columnSpanFull(),

                TextInput::make('creation_fee_rate')
                    ->label('Assigned Creation Fee Rate ($) / رسوم الإنشاء المعينة')
                    ->prefix('$')
                    ->disabled()
                    ->dehydrated(false),

                TextInput::make('redemption_fee_rate')
                    ->label('Assigned Redemption Fee Rate ($) / رسوم التفعيل المعينة')
                    ->prefix('$')
                    ->disabled()
                    ->dehydrated(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                ImageColumn::make('logo')
                    ->label('الشعار')
                    ->height(48)
                    ->width(48)
                    ->circular(),

                TextColumn::make('name')
                    ->label('اسم المتجر')
                    ->weight('bold')
                    ->icon('heroicon-m-building-storefront'),

                TextColumn::make('phone')
                    ->label('الهاتف')
                    ->icon('heroicon-m-phone'),

                IconColumn::make('is_active')
                    ->label('الحالة')
                    ->boolean(),

                TextColumn::make('creation_fee_rate')
                    ->label('رسوم الإنشاء')
                    ->money('USD')
                    ->icon('heroicon-m-currency-dollar'),

                TextColumn::make('redemption_fee_rate')
                    ->label('رسوم التفعيل')
                    ->money('USD')
                    ->icon('heroicon-m-banknotes'),
            ])
            ->actions([
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMyStores::route('/'),
            'edit' => Pages\EditMyStore::route('/{record}/edit'),
        ];
    }
}
