<x-filament-widgets::widget>
    <div style="background-color: #18181b; border: 1px solid #27272a; border-radius: 0.875rem; padding: 1rem 1.25rem; display: flex; align-items: center; justify-content: space-between; gap: 1.25rem; width: 100%;">
        
        <!-- Left Section: Label -->
        <div style="display: flex; align-items: center; gap: 0.75rem; shrink: 0;">
            <div style="background-color: rgba(245, 158, 11, 0.15); color: #fbbf24; padding: 0.5rem; border-radius: 0.625rem; display: flex; align-items: center; justify-content: center;">
                <svg style="width: 20px; height: 20px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                </svg>
            </div>
            <div style="display: flex; flex-direction: column;">
                <span style="font-size: 0.95rem; font-weight: 700; color: #ffffff; line-height: 1.2;">إجراءات سريعة</span>
                <span style="font-size: 0.7rem; color: #a1a1aa; text-transform: uppercase; tracking: 0.05em;">Quick Actions</span>
            </div>
        </div>

        <!-- Right Section: Action Buttons in a Row -->
        <div style="display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap; justify-content: flex-end;">
            
            <!-- 1. Store Creation -->
            <a href="{{ \App\Filament\Resources\StoreResource::getUrl('create') }}"
               style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.55rem 1rem; background-color: #27272a; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 0.625rem; font-size: 0.85rem; font-weight: 600; text-decoration: none; transition: all 0.15s ease;"
               onmouseover="this.style.backgroundColor='#d97706'; this.style.borderColor='#b45309'; this.style.color='#ffffff';"
               onmouseout="this.style.backgroundColor='#27272a'; this.style.borderColor='#3f3f46'; this.style.color='#f4f4f5';">
                <svg style="width: 17px; height: 17px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H21m-9 0H3m2.25-1.5a4.5 4.5 0 004.5-4.5v-3.75l-1.5-1.5h-3l-1.5 1.5V15a4.5 4.5 0 004.5 4.5zM12 3v3.75m0 0l2.25-2.25M12 6.75L9.75 4.5" />
                </svg>
                <span>إضافة متجر</span>
            </a>

            <!-- 2. Coupon Creation -->
            <a href="{{ \App\Filament\Resources\CouponResource::getUrl('create') }}"
               style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.55rem 1rem; background-color: #27272a; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 0.625rem; font-size: 0.85rem; font-weight: 600; text-decoration: none; transition: all 0.15s ease;"
               onmouseover="this.style.backgroundColor='#2563eb'; this.style.borderColor='#1d4ed8'; this.style.color='#ffffff';"
               onmouseout="this.style.backgroundColor='#27272a'; this.style.borderColor='#3f3f46'; this.style.color='#f4f4f5';">
                <svg style="width: 17px; height: 17px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 6v.75m0 3v.75m0 3v.75m0 3V18m-9-12v.75m0 3v.75m0 3v.75m0 3V18M3 7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v9a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 16.5v-9z" />
                </svg>
                <span>إنشاء كوبون</span>
            </a>

            <!-- 3. Campaign Creation -->
            <a href="{{ \App\Filament\Resources\CampaignResource::getUrl('create') }}"
               style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.55rem 1rem; background-color: #27272a; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 0.625rem; font-size: 0.85rem; font-weight: 600; text-decoration: none; transition: all 0.15s ease;"
               onmouseover="this.style.backgroundColor='#059669'; this.style.borderColor='#047857'; this.style.color='#ffffff';"
               onmouseout="this.style.backgroundColor='#27272a'; this.style.borderColor='#3f3f46'; this.style.color='#f4f4f5';">
                <svg style="width: 17px; height: 17px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M10.34 15.84c-.688-.06-1.386-.09-2.09-.09H7.5a4.5 4.5 0 110-9h.75c.704 0 1.402-.03 2.09-.09m0 9.18c.253.962.584 1.892.985 2.783.247.55.6 1.01 1.087 1.328.488.318 1.053.486 1.638.486h.05a2.25 2.25 0 002.246-2.235 21.848 21.848 0 00-.533-4.832m-5.473 2.472a10.97 10.97 0 013.999-5.185m-3.999 5.185a10.97 10.97 0 003.999 5.185M10.34 6.66a21.854 21.854 0 005.473 2.472m0 0a10.97 10.97 0 01-3.999 5.185" />
                </svg>
                <span>إطلاق حملة</span>
            </a>

            <!-- 4. Redemption Logs -->
            <a href="{{ \App\Filament\Resources\RedemptionResource::getUrl('index') }}"
               style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.55rem 1rem; background-color: #27272a; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 0.625rem; font-size: 0.85rem; font-weight: 600; text-decoration: none; transition: all 0.15s ease;"
               onmouseover="this.style.backgroundColor='#7c3aed'; this.style.borderColor='#6d28d9'; this.style.color='#ffffff';"
               onmouseout="this.style.backgroundColor='#27272a'; this.style.borderColor='#3f3f46'; this.style.color='#f4f4f5';">
                <svg style="width: 17px; height: 17px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 013.75 9.375v-4.5zM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 01-1.125-1.125v-4.5zM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0113.5 9.375v-4.5z" />
                </svg>
                <span>سجل التفعيلات</span>
            </a>

        </div>
    </div>
</x-filament-widgets::widget>