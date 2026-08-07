<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ClaimedCouponResource\Pages;
use App\Models\ClaimedCoupon;
use BackedEnum;
use UnitEnum;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ClaimedCouponResource extends Resource
{
    protected static ?string $model = ClaimedCoupon::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-wallet';

    protected static string|UnitEnum|null $navigationGroup = 'Coupons and Fees';

    protected static ?string $navigationLabel = 'Wallet Transactions / محفظة الكوبونات';

    protected static ?int $navigationSort = 3;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                Select::make('user_id')
                    ->label('Customer / العميل')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),

                Select::make('coupon_id')
                    ->label('Coupon / الكوبون')
                    ->relationship('coupon', 'title')
                    ->searchable()
                    ->preload()
                    ->required(),

                Select::make('status')
                    ->label('Status / الحالة')
                    ->options([
                        'claimed' => 'Claimed / محجوز',
                        'redeemed' => 'Redeemed / مفعل',
                        'expired' => 'Expired / منتهي',
                    ])
                    ->default('claimed')
                    ->required(),

                DateTimePicker::make('claimed_at')
                    ->label('Claimed At / تاريخ المطالبة')
                    ->default(now())
                    ->required(),

                DateTimePicker::make('redeemed_at')
                    ->label('Redeemed At / تاريخ الاستخدام')
                    ->nullable(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.name')
                    ->label('العميل')
                    ->searchable()
                    ->sortable()
                    ->icon('heroicon-m-user'),

                TextColumn::make('coupon.title')
                    ->label('الكوبون')
                    ->searchable()
                    ->sortable()
                    ->icon('heroicon-m-ticket'),

                TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'redeemed' => 'success',
                        'claimed' => 'warning',
                        'expired' => 'danger',
                        default => 'secondary',
                    }),

                TextColumn::make('claimed_at')
                    ->label('تاريخ المطالبة')
                    ->dateTime()
                    ->sortable(),

                TextColumn::make('redeemed_at')
                    ->label('تاريخ الاستخدام')
                    ->dateTime()
                    ->placeholder('—')
                    ->sortable(),
            ])
            ->actions([
                ViewAction::make(),
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListClaimedCoupons::route('/'),
            'create' => Pages\CreateClaimedCoupon::route('/create'),
            'view' => Pages\ViewClaimedCoupon::route('/{record}'),
            'edit' => Pages\EditClaimedCoupon::route('/{record}/edit'),
        ];
    }
}
