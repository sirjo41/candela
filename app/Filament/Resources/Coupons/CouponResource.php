<?php

namespace App\Filament\Resources;
use App\Filament\Resources\CouponResource\Pages;
use App\Models\Coupon;
use BackedEnum;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class CouponResource extends Resource
{
    protected static ?string $model = Coupon::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-ticket';

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            Select::make('store_id')->relationship('store', 'name')->required(),
            Select::make('campaign_id')->relationship('campaign', 'title')->nullable(),
            TextInput::make('title')->required(),
            TextInput::make('code')->required()->unique(ignoreRecord: true),
            Select::make('discount_type')->options([
                'percentage' => 'Percentage',
                'fixed_amount' => 'Fixed Amount',
            ])->required(),
            TextInput::make('discount_value')->numeric()->required(),
            TextInput::make('creation_fee')->numeric()->prefix('$')->required(),
            TextInput::make('redemption_fee')->numeric()->prefix('$')->required(),
            DateTimePicker::make('expires_at')->required(),
            Toggle::make('is_active')->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('store.name')->label('Store')->sortable(),
                TextColumn::make('title')->searchable(),
                TextColumn::make('code')->badge()->color('primary'),
                TextColumn::make('discount_value'),
                IconColumn::make('is_active')->boolean(),
                TextColumn::make('expires_at')->dateTime(),
            ])
            ->filters([ Tables\Filters\TrashedFilter::make() ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\RestoreAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCoupons::route('/'),
            'create' => Pages\CreateCoupon::route('/create'),
            'edit' => Pages\EditCoupon::route('/{record}/edit'),
        ];
    }
}