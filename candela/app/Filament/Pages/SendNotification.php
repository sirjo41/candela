<?php

namespace App\Filament\Pages;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\DB;

class SendNotification extends Page implements HasForms
{
    use InteractsWithForms;
    protected static \BackedEnum|string|null $navigationIcon = 'heroicon-o-paper-airplane';
    protected static ?string $navigationLabel = 'إرسال الإشعارات والإعلانات';
    protected static ?string $title = 'إرسال الإشعارات والخصومات للعملاء';
    protected static \UnitEnum|string|null $navigationGroup = 'التسويق والإشعارات';

    protected string $view = 'filament.pages.send-notification';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill();
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title')
                    ->label('عنوان الإعلان / الإشعار')
                    ->required()
                    ->placeholder('مثال: عرض خاص نهاية الأسبوع!'),

                Textarea::make('message')
                    ->label('نص الرسالة الإعلانية')
                    ->required()
                    ->rows(4)
                    ->placeholder('اكتب التفاصيل هنا (مثال: احصل على خصم 20% لدى جميع مطاعم كانديلا)'),

                Select::make('target_role')
                    ->label('الفئة المستهدفة')
                    ->options([
                        'all' => 'جميع المستخدمين (عملاء وتجار)',
                        'customer' => 'العملاء فقط',
                        'merchant' => 'التجار فقط',
                    ])
                    ->default('all')
                    ->required(),

                TextInput::make('action_url')
                    ->label('رابط اختياري (رمز العرض أو رابط متجر)')
                    ->placeholder('https://candela.app/offers/12'),
            ])
            ->statePath('data');
    }

    public function send(): void
    {
        $data = $this->form->getState();

        DB::table('broadcast_ads')->insert([
            'title' => $data['title'],
            'message' => $data['message'],
            'target_role' => $data['target_role'],
            'action_url' => $data['action_url'] ?? null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Notification::make()
            ->title('تم إرسال الإشعار الإعلاني بنجاح!')
            ->body('تم إطلاق الحملة الإعلانية لجميع المستهدفين.')
            ->success()
            ->send();

        $this->dispatch('trigger-chrome-notification',
            title: $data['title'],
            body: $data['message'],
            url: $data['action_url'] ?? null,
        );

        $this->form->fill();
    }
}
