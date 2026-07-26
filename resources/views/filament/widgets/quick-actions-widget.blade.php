<x-filament-widgets::widget>
    <div class="p-2 sm:px-3 sm:py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
        <div class="flex items-center gap-2 shrink-0 px-1 pt-1 sm:pt-0">
            <div class="p-1 rounded bg-amber-500/10 text-amber-500 dark:bg-amber-400/10 dark:text-amber-400">
                <x-heroicon-o-bolt class="w-3.5 h-3.5" />
            </div>
            <span class="text-xs font-bold text-gray-900 dark:text-white whitespace-nowrap">
                إجراءات سريعة <span class="text-[11px] font-normal text-gray-400 dark:text-gray-500 ms-0.5">/ Quick Actions</span>
            </span>
        </div>

        <div class="grid grid-cols-2 sm:flex sm:flex-wrap items-center gap-2 flex-1 sm:justify-end">
            <!-- 1. Store Creation -->
            <a href="{{ \App\Filament\Resources\StoreResource::getUrl('create') }}"
               class="inline-flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-amber-200/80 dark:border-amber-900/40 bg-amber-50/50 dark:bg-amber-950/20 text-amber-700 dark:text-amber-300 hover:bg-amber-500 hover:text-white dark:hover:bg-amber-500 dark:hover:text-white transition-all duration-150 text-xs font-medium shrink-0">
                <x-heroicon-o-building-storefront class="w-3.5 h-3.5 shrink-0" />
                <span class="truncate">إضافة متجر</span>
            </a>

            <!-- 2. Coupon Creation -->
            <a href="{{ \App\Filament\Resources\CouponResource::getUrl('create') }}"
               class="inline-flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-blue-200/80 dark:border-blue-900/40 bg-blue-50/50 dark:bg-blue-950/20 text-blue-700 dark:text-blue-300 hover:bg-blue-500 hover:text-white dark:hover:bg-blue-500 dark:hover:text-white transition-all duration-150 text-xs font-medium shrink-0">
                <x-heroicon-o-ticket class="w-3.5 h-3.5 shrink-0" />
                <span class="truncate">إنشاء كوبون</span>
            </a>

            <!-- 3. Campaign Creation -->
            <a href="{{ \App\Filament\Resources\CampaignResource::getUrl('create') }}"
               class="inline-flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-emerald-200/80 dark:border-emerald-900/40 bg-emerald-50/50 dark:bg-emerald-950/20 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-500 hover:text-white dark:hover:bg-emerald-500 dark:hover:text-white transition-all duration-150 text-xs font-medium shrink-0">
                <x-heroicon-o-megaphone class="w-3.5 h-3.5 shrink-0" />
                <span class="truncate">إطلاق حملة</span>
            </a>

            <!-- 4. Redemption Logs -->
            <a href="{{ \App\Filament\Resources\RedemptionResource::getUrl('index') }}"
               class="inline-flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-purple-200/80 dark:border-purple-900/40 bg-purple-50/50 dark:bg-purple-950/20 text-purple-700 dark:text-purple-300 hover:bg-purple-500 hover:text-white dark:hover:bg-purple-500 dark:hover:text-white transition-all duration-150 text-xs font-medium shrink-0">
                <x-heroicon-o-qr-code class="w-3.5 h-3.5 shrink-0" />
                <span class="truncate">سجل التفعيلات</span>
            </a>
        </div>
    </div>
</x-filament-widgets::widget>
