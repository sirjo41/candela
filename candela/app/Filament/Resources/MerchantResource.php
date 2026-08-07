<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MerchantResource\Pages;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
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
use UnitEnum;

class MerchantResource extends Resource
{
    protected static ?string $model = User::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-building-storefront';

    protected static string|UnitEnum|null $navigationGroup = 'User Management';

    protected static ?string $navigationLabel = 'Merchants / التجار';

    protected static ?int $navigationSort = 4;

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->merchants();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                TextInput::make('name')
                    ->label('Full Name / الاسم الكامل')
                    ->required()
                    ->maxLength(255),

                TextInput::make('email')
                    ->label('Email Address / البريد الإلكتروني')
                    ->email()
                    ->required()
                    ->unique(ignoreRecord: true),

                TextInput::make('phone')
                    ->label('Phone / رقم الهاتف')
                    ->tel()
                    ->nullable(),

                Select::make('role')
                    ->label('Role / الدور')
                    ->options([
                        'merchant' => 'Merchant / تاجر',
                    ])
                    ->default('merchant')
                    ->required(),

                Select::make('store_id')
                    ->label('Assigned Store / المتجر المعين')
                    ->relationship('store', 'name')
                    ->searchable()
                    ->preload()
                    ->nullable(),

                Toggle::make('is_active')
                    ->label('Account Active Status / مفعل')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->icon('heroicon-m-user'),

                TextColumn::make('email')
                    ->label('البريد')
                    ->searchable()
                    ->sortable()
                    ->icon('heroicon-m-envelope'),

                TextColumn::make('phone')
                    ->label('الهاتف')
                    ->searchable()
                    ->icon('heroicon-m-phone'),

                TextColumn::make('store.name')
                    ->label('المتجر المعين')
                    ->placeholder('—')
                    ->sortable()
                    ->badge()
                    ->color('primary'),

                TextColumn::make('store.balance')
                    ->label('رصيد المحفظة')
                    ->money('LYD')
                    ->placeholder('0.00 د.ل')
                    ->badge()
                    ->color('success')
                    ->icon('heroicon-m-wallet'),

                TextColumn::make('role')
                    ->label('الدور')
                    ->badge()
                    ->color('info'),

                IconColumn::make('is_active')
                    ->label('الحالة')
                    ->boolean(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime()
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
            'index' => Pages\ListMerchants::route('/'),
            'create' => Pages\CreateMerchant::route('/create'),
            'edit' => Pages\EditMerchant::route('/{record}/edit'),
        ];
    }
}
