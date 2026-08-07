<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CampaignResource\Pages;
use App\Models\Campaign;
use BackedEnum;
use UnitEnum;
use Filament\Actions\EditAction;
use Filament\Actions\RestoreAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class CampaignResource extends Resource
{
    protected static ?string $model = Campaign::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-megaphone';
    protected static string|UnitEnum|null $navigationGroup = 'Coupons and Fees';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                TextInput::make('title')
                    ->label('Campaign Title / عنوان الحملة')
                    ->required()
                    ->maxLength(255)
                    ->columnSpanFull(),

                Textarea::make('description')
                    ->label('Description / الوصف')
                    ->rows(3)
                    ->columnSpanFull(),

                FileUpload::make('banner_image')
                    ->label('Banner Image / صورة الحملة')
                    ->image()
                    ->directory('campaigns')
                    ->columnSpanFull(),

                DateTimePicker::make('start_date')
                    ->label('Start Date / تاريخ البدء')
                    ->required(),

                DateTimePicker::make('end_date')
                    ->label('End Date / تاريخ الانتهاء')
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
                ImageColumn::make('banner_image')
                    ->label('الصورة')
                    ->height(64)
                    ->width(120),

                TextColumn::make('title')
                    ->label('عنوان الحملة')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->icon('heroicon-m-megaphone'),

                TextColumn::make('start_date')
                    ->label('تاريخ البدء')
                    ->dateTime()
                    ->icon('heroicon-m-calendar'),

                TextColumn::make('end_date')
                    ->label('تاريخ الانتهاء')
                    ->dateTime()
                    ->icon('heroicon-m-calendar'),

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
            'index' => Pages\ListCampaigns::route('/'),
            'create' => Pages\CreateCampaign::route('/create'),
            'edit' => Pages\EditCampaign::route('/{record}/edit'),
        ];
    }
}