<?php

namespace App\Filament\Owner\Resources;

use App\Filament\Owner\Resources\RedemptionResource\Pages;
use App\Models\Redemption;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class RedemptionResource extends Resource
{
    protected static ?string $model = Redemption::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-qr-code';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->whereHas('branch', function (Builder $query) {
            $query->where('store_id', auth()->user()?->store_id);
        });
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
                Select::make('coupon_id')
                    ->label('Coupon / الكوبون')
                    ->relationship('coupon', 'title')
                    ->disabled(),

                Select::make('user_id')
                    ->label('Customer / العميل')
                    ->relationship('user', 'name')
                    ->disabled(),

                Select::make('branch_id')
                    ->label('Branch / الفرع')
                    ->relationship('branch', 'name')
                    ->disabled(),

                TextInput::make('qr_code_hash')
                    ->label('QR Code Hash / كود التفعيل')
                    ->disabled(),

                TextInput::make('points_awarded')
                    ->label('Points Awarded / النقاط')
                    ->numeric()
                    ->disabled(),

                TextInput::make('charged_fee')
                    ->label('Charged Fee / الرسوم المستحقة')
                    ->numeric()
                    ->prefix('$')
                    ->disabled(),

                DateTimePicker::make('redeemed_at')
                    ->label('Redemption Date / تاريخ التفعيل')
                    ->disabled()
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('coupon.title')
                    ->label('Coupon')
                    ->searchable()
                    ->icon('heroicon-m-ticket'),

                TextColumn::make('user.name')
                    ->label('Customer')
                    ->searchable()
                    ->icon('heroicon-m-user'),

                TextColumn::make('branch.name')
                    ->label('Branch')
                    ->searchable()
                    ->icon('heroicon-m-map-pin'),

                TextColumn::make('qr_code_hash')
                    ->label('QR Hash')
                    ->badge()
                    ->copyable()
                    ->icon('heroicon-m-qr-code'),

                TextColumn::make('points_awarded')
                    ->label('Points')
                    ->numeric()
                    ->badge()
                    ->color('warning'),

                TextColumn::make('charged_fee')
                    ->label('Charged Fee')
                    ->money('USD')
                    ->sortable()
                    ->icon('heroicon-m-currency-dollar'),

                TextColumn::make('redeemed_at')
                    ->label('Date')
                    ->dateTime()
                    ->sortable()
                    ->icon('heroicon-m-calendar'),
            ])
            ->actions([
                ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListRedemptions::route('/'),
            'view' => Pages\ViewRedemption::route('/{record}'),
        ];
    }
}
