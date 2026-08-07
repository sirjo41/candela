<x-filament-panels::page>
    <div x-data="{
        permissionState: 'Notification' in window ? Notification.permission : 'unsupported',
        requestPermission() {
            if (!('Notification' in window)) {
                alert('متصفحك لا يدعم إشعارات سطح المكتب (Web Notifications API).');
                return;
            }
            Notification.requestPermission().then(perm => {
                this.permissionState = perm;
                if (perm === 'granted') {
                    this.triggerTestNotification('تم تفعيل إشعارات Chrome بنجاح! 🔔', 'ستتلقى جميع الإشعارات الإعلانية مباشرة على سطح المكتب.');
                } else if (perm === 'denied') {
                    alert('تم رفض صلاحية الإشعارات من إعدادات المتصفح. يرجى الضغط على أيقونة القفل 🔒 بجانب رابط الموقع في Chrome واختيار (Allow/سماح) للإشعارات.');
                }
            });
        },
        triggerTestNotification(title, body, url) {
            if (!('Notification' in window) || Notification.permission !== 'granted') {
                this.requestPermission();
                return;
            }
            const n = new Notification(title || 'إشعار تجريبي من واجهة 🔔', {
                body: body || 'هذا إشعار تجريبي لاختبار ظهور تنبيهات متصفح Chrome على سطح المكتب.',
                dir: 'rtl'
            });
            if (url) {
                n.onclick = () => window.open(url, '_blank');
            }
        },
        showChromeNotification(detail) {
            console.log('Livewire event detail:', detail);
            let data = detail;
            if (Array.isArray(detail) && detail.length > 0) {
                data = detail[0];
            } else if (detail && detail.data) {
                data = detail.data;
            }
            data = data || {};

            const title = data.title || 'إشعار جديد من واجهة';
            const body = data.body || data.message || '';
            const url = data.url || data.action_url || null;

            if (!('Notification' in window)) return;

            if (Notification.permission === 'granted') {
                const n = new Notification(title, {
                    body: body,
                    dir: 'rtl'
                });
                if (url) {
                    n.onclick = () => window.open(url, '_blank');
                }
            } else {
                this.requestPermission();
            }
        }
    }"
    @trigger-chrome-notification.window="showChromeNotification($event.detail)"
    x-init="
        if ('Notification' in window) {
            permissionState = Notification.permission;
            if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
                Notification.requestPermission().then(p => permissionState = p);
            }
        }
    ">
        
        <!-- Status Banner -->
        <div class="mb-4 p-3 rounded-xl flex items-center justify-between border text-sm"
             :class="{
                 'bg-emerald-50 text-emerald-800 border-emerald-200 dark:bg-emerald-950 dark:text-emerald-200 dark:border-emerald-800': permissionState === 'granted',
                 'bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-950 dark:text-amber-200 dark:border-amber-800': permissionState === 'default',
                 'bg-rose-50 text-rose-800 border-rose-200 dark:bg-rose-950 dark:text-rose-200 dark:border-rose-800': permissionState === 'denied' || permissionState === 'unsupported'
             }">
            <div class="flex items-center gap-2 font-medium">
                <template x-if="permissionState === 'granted'">
                    <span>🟢 إشعارات Chrome مفعلة وجاهزة لسطح المكتب</span>
                </template>
                <template x-if="permissionState === 'default'">
                    <span>🟡 يرجى الضغط لتفعيل إشعارات متصفح Chrome</span>
                </template>
                <template x-if="permissionState === 'denied'">
                    <span>🔴 الإشعارات محظورة من إعدادات المتصفح (انقر القفل 🔒 بالرابط واختر Allow)</span>
                </template>
            </div>

            <div class="flex items-center gap-2">
                <button type="button" 
                        @click="triggerTestNotification()" 
                        class="px-3 py-1 bg-white dark:bg-gray-800 border rounded-lg shadow-sm hover:bg-gray-50 text-xs font-bold transition">
                    🧪 تجربة إشعار Chrome الآن
                </button>
                <button type="button" 
                        @click="requestPermission()" 
                        class="px-3 py-1 bg-amber-500 text-white rounded-lg shadow-sm hover:bg-amber-600 text-xs font-bold transition"
                        x-show="permissionState !== 'granted'">
                    🔔 تفعيل الآن
                </button>
            </div>
        </div>

        <form wire:submit="send" class="space-y-6">
            {{ $this->form }}

            <div class="mt-4 flex items-center justify-end">
                <x-filament::button type="submit" size="lg" icon="heroicon-o-paper-airplane">
                    إرسال الإشعار والاعلان الآن
                </x-filament::button>
            </div>
        </form>
    </div>
</x-filament-panels::page>
