<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\RestoreAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TrashedFilter;
use Filament\Tables\Table;
use UnitEnum;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-users';

    protected static string|UnitEnum|null $navigationGroup = 'User Management';

    protected static ?string $navigationLabel = 'All Users / كل المستخدمين';

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
                    ->label('User Category / فئة المستخدم')
                    ->options([
                        'customer' => 'Customer / عميل',
                        'admin' => 'Admin / مسؤول',
                        'store_owner' => 'Store Owner / مالك متجر',
                    ])
                    ->default('customer')
                    ->reactive()
                    ->required(),

                Select::make('store_id')
                    ->label('Assigned Store / المتجر المعين')
                    ->relationship('store', 'name')
                    ->searchable()
                    ->preload()
                    ->nullable()
                    ->visible(fn ($get) => in_array($get('role'), ['store_owner', 'merchant'])),

                TextInput::make('loyalty_points')
                    ->label('Loyalty Points / نقاط الولاء')
                    ->numeric()
                    ->default(0)
                    ->required()
                    ->visible(fn ($get) => empty($get('role')) || $get('role') === 'customer'),

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

                TextColumn::make('role')
                    ->label('الفئة / الدور')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'admin', 'national_admin' => 'Admin / مسؤول',
                        'store_owner', 'merchant' => 'Store Owner / مالك متجر',
                        default => 'Customer / عميل',
                    })
                    ->color(fn (?string $state): string => match ($state) {
                        'admin', 'national_admin' => 'danger',
                        'store_owner', 'merchant' => 'info',
                        default => 'success',
                    }),

                TextColumn::make('store.name')
                    ->label('المتجر')
                    ->placeholder('—')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('loyalty_points')
                    ->label('نقاط الولاء')
                    ->numeric()
                    ->sortable()
                    ->badge()
                    ->color('warning'),

                IconColumn::make('is_active')
                    ->label('الحالة')
                    ->boolean(),

                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->label('User Category / فئة المستخدم')
                    ->options([
                        'customer' => 'Customers / العملاء',
                        'admin' => 'Admins / المسؤولون',
                        'store_owner' => 'Store Owners / ملاك المتاجر',
                    ])
                    ->query(function ($query, array $data) {
                        if (empty($data['value'])) {
                            return $query;
                        }

                        return match ($data['value']) {
                            'customer' => $query->customers(),
                            'admin' => $query->admins(),
                            'store_owner' => $query->storeOwners(),
                            default => $query,
                        };
                    }),
                TrashedFilter::make(),
            ])
            ->actions([
                ViewAction::make(),
                EditAction::make(),
                RestoreAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'view' => Pages\ViewUser::route('/{record}'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}