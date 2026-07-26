<?php

namespace App\Filament\Owner\Resources;

use App\Filament\Owner\Resources\CouponResource\Pages;
use App\Models\Coupon;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\RestoreAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Hidden;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CouponResource extends Resource
{
    protected static ?string $model = Coupon::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-ticket';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('store_id', auth()->user()?->store_id);
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                Hidden::make('store_id')
                    ->default(fn () => auth()->user()?->store_id),

                Select::make('campaign_id')
                    ->label('Campaign / الحملة')
                    ->relationship('campaign', 'title')
                    ->nullable(),

                TextInput::make('title')
                    ->label('Coupon Title / عنوان الكوبون')
                    ->required()
                    ->maxLength(255),

                TextInput::make('code')
                    ->label('Coupon Code / كود الخصم')
                    ->required()
                    ->unique(ignoreRecord: true),

                Select::make('discount_type')
                    ->label('Discount Type / نوع الخصم')
                    ->options([
                        'percentage' => 'Percentage (%)',
                        'fixed_amount' => 'Fixed Amount ($)',
                    ])
                    ->required(),

                TextInput::make('discount_value')
                    ->label('Discount Value / قيمة الخصم')
                    ->numeric()
                    ->required(),

                TextInput::make('creation_fee')
                    ->label('Calculated Creation Fee ($)')
                    ->numeric()
                    ->prefix('$')
                    ->default(fn () => auth()->user()?->store?->creation_fee_rate ?? 0)
                    ->required(),

                TextInput::make('redemption_fee')
                    ->label('Calculated Redemption Fee ($)')
                    ->numeric()
                    ->prefix('$')
                    ->default(fn () => auth()->user()?->store?->redemption_fee_rate ?? 0)
                    ->required(),

                DateTimePicker::make('expires_at')
                    ->label('Expiration Date / تاريخ الانتهاء')
                    ->required(),

                Toggle::make('is_active')
                    ->label('Active Status / مفعل')
                    ->default(true)
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->contentGrid([
                'md' => 2,
                'xl' => 3,
            ])
            ->columns([
                TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->icon('heroicon-m-ticket'),

                TextColumn::make('code')
                    ->label('الكود')
                    ->badge()
                    ->color('primary')
                    ->copyable()
                    ->icon('heroicon-m-qr-code'),

                TextColumn::make('discount_value')
                    ->label('قيمة الخصم')
                    ->icon('heroicon-m-tag'),

                TextColumn::make('creation_fee')
                    ->label('رسوم الإنشاء')
                    ->money('USD'),

                TextColumn::make('redemption_fee')
                    ->label('رسوم التفعيل')
                    ->money('USD'),

                IconColumn::make('is_active')
                    ->label('الحالة')
                    ->boolean(),

                TextColumn::make('expires_at')
                    ->label('تاريخ الانتهاء')
                    ->dateTime()
                    ->icon('heroicon-m-calendar'),
            ])
            ->filters([ Tables\Filters\TrashedFilter::make() ])
            ->actions([
                EditAction::make(),
                RestoreAction::make(),
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
