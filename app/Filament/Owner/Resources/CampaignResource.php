<?php

namespace App\Filament\Owner\Resources;

use App\Filament\Owner\Resources\CampaignResource\Pages;
use App\Models\Campaign;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
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

class CampaignResource extends Resource
{
    protected static ?string $model = Campaign::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-megaphone';

    protected static ?string $navigationLabel = 'Active Campaigns / الحملات النشطة';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('end_date')->orWhere('end_date', '>=', now());
            });
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit(Model $record): bool
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
                TextInput::make('title')
                    ->label('Campaign Title / عنوان الحملة')
                    ->disabled()
                    ->columnSpanFull(),

                Textarea::make('description')
                    ->label('Description / الوصف')
                    ->rows(3)
                    ->disabled()
                    ->columnSpanFull(),

                FileUpload::make('banner_image')
                    ->label('Banner Image / صورة الحملة')
                    ->disabled()
                    ->columnSpanFull(),

                DateTimePicker::make('start_date')
                    ->label('Start Date / تاريخ البدء')
                    ->disabled(),

                DateTimePicker::make('end_date')
                    ->label('End Date / تاريخ الانتهاء')
                    ->disabled(),

                Toggle::make('is_active')
                    ->label('Active Status / مفعل')
                    ->disabled()
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
            ->actions([
                ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCampaigns::route('/'),
            'view' => Pages\ViewCampaign::route('/{record}'),
        ];
    }
}
