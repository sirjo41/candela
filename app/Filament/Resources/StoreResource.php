<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StoreResource\Pages;
use App\Filament\Resources\StoreResource\RelationManagers\StoreBranchesRelationManager;
use App\Models\Store;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\RestoreAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Radio;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class StoreResource extends Resource
{
    protected static ?string $model = Store::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-building-storefront';

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

                TextInput::make('creation_fee_rate')
                    ->label('Creation Fee Rate ($)')
                    ->numeric()
                    ->prefix('$')
                    ->default(0)
                    ->required(),

                TextInput::make('redemption_fee_rate')
                    ->label('Redemption Fee Rate ($)')
                    ->numeric()
                    ->prefix('$')
                    ->default(0)
                    ->required(),

                FileUpload::make('logo')
                    ->label('Store Logo / شعار المتجر')
                    ->image()
                    ->directory('stores')
                    ->columnSpanFull(),

                Toggle::make('is_active')
                    ->label('Active Status / مفعل')
                    ->default(true)
                    ->columnSpanFull(),

                Section::make('Store Owner Assignment / تعيين مالك المتجر')
                    ->description('Assign an existing user or create a new store owner account.')
                    ->schema([
                        Radio::make('owner_option')
                            ->label('Owner Assignment Method')
                            ->options([
                                'none' => 'No Owner Assignment',
                                'existing' => 'Assign Existing User',
                                'new' => 'Create New User',
                            ])
                            ->default('none')
                            ->reactive()
                            ->columnSpanFull(),

                        Select::make('existing_owner_id')
                            ->label('Select Existing User')
                            ->options(fn () => User::query()
                                ->whereIn('role', ['customer', 'store_owner', 'merchant'])
                                ->pluck('name', 'id'))
                            ->searchable()
                            ->visible(fn ($get) => $get('owner_option') === 'existing')
                            ->columnSpanFull(),

                        Group::make([
                            TextInput::make('new_owner_name')
                                ->label('Owner Name / اسم المالك')
                                ->required(fn ($get) => $get('owner_option') === 'new')
                                ->maxLength(255),

                            TextInput::make('new_owner_email')
                                ->label('Owner Email / البريد الإلكتروني')
                                ->email()
                                ->required(fn ($get) => $get('owner_option') === 'new')
                                ->maxLength(255),

                            TextInput::make('new_owner_phone')
                                ->label('Owner Phone / رقم الهاتف')
                                ->tel(),

                            TextInput::make('new_owner_password')
                                ->label('Owner Password / كلمة المرور')
                                ->password()
                                ->required(fn ($get) => $get('owner_option') === 'new')
                                ->minLength(6),
                        ])
                        ->columns(2)
                        ->visible(fn ($get) => $get('owner_option') === 'new')
                        ->columnSpanFull(),
                    ])
                    ->columnSpanFull()
                    ->collapsible(),
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
                ImageColumn::make('logo')
                    ->label('الشعار')
                    ->height(48)
                    ->width(48)
                    ->circular(),

                TextColumn::make('name')
                    ->label('اسم المتجر')
                    ->searchable()
                    ->sortable()
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
            ->filters([ Tables\Filters\TrashedFilter::make() ])
            ->actions([
                EditAction::make(),
                RestoreAction::make(),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            StoreBranchesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStores::route('/'),
            'create' => Pages\CreateStore::route('/create'),
            'edit' => Pages\EditStore::route('/{record}/edit'),
        ];
    }
}