<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BranchResource\Pages;
use App\Models\Branch;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\RestoreAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use UnitEnum;

class BranchResource extends Resource
{
    protected static ?string $model = Branch::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-map-pin';

    protected static string|UnitEnum|null $navigationGroup = 'Store Management';
    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                Select::make('store_id')
                    ->label('Store / المتجر')
                    ->relationship('store', 'name')
                    ->required(),

                TextInput::make('name')
                    ->label('Branch Name / اسم الفرع')
                    ->required()
                    ->maxLength(255),

                TextInput::make('phone')
                    ->label('Phone / الهاتف')
                    ->tel(),

                TextInput::make('address')
                    ->label('Address / العنوان'),

                TextInput::make('latitude')
                    ->label('Latitude / خط العرض')
                    ->numeric(),

                TextInput::make('longitude')
                    ->label('Longitude / خط الطول')
                    ->numeric(),

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
                TextColumn::make('name')
                    ->label('اسم الفرع')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->icon('heroicon-m-map-pin'),

                TextColumn::make('store.name')
                    ->label('المتجر')
                    ->sortable()
                    ->searchable()
                    ->icon('heroicon-m-building-storefront'),

                TextColumn::make('phone')
                    ->label('الهاتف')
                    ->icon('heroicon-m-phone'),

                TextColumn::make('address')
                    ->label('العنوان')
                    ->limit(30),

                IconColumn::make('is_active')
                    ->label('الحالة')
                    ->boolean(),
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
            'index' => Pages\ListBranches::route('/'),
            'create' => Pages\CreateBranch::route('/create'),
            'edit' => Pages\EditBranch::route('/{record}/edit'),
        ];
    }
}