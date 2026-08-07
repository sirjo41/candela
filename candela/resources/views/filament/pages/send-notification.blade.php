<x-filament-panels::page>
    <x-filament-panels::form wire:submit="send">
        {{ $this->form }}

        <div class="mt-4 flex justify-end">
            <x-filament::button type="submit" size="lg" icon="heroicon-o-paper-airplane">
                إرسال الإشعار الآن
            </x-filament::button>
        </div>
    </x-filament-panels::form>
</x-filament-panels::page>
