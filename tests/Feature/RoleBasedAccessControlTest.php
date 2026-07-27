<?php

use App\Filament\Owner\Widgets\OwnerStatsOverview;
use App\Models\Branch;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Filament\Panel;

test('user role helpers return expected booleans', function () {
    $admin = new User(['role' => 'admin']);
    $owner = new User(['role' => 'merchant']);
    $customer = new User(['role' => 'customer']);

    expect($admin->isAdmin())->toBeTrue();
    expect($admin->isMerchant())->toBeFalse();
    expect($admin->isCustomer())->toBeFalse();

    expect($owner->isMerchant())->toBeTrue();
    expect($owner->isStoreOwner())->toBeTrue();
    expect($owner->isAdmin())->toBeFalse();

    expect($customer->isCustomer())->toBeTrue();
    expect($customer->isAdmin())->toBeFalse();
    expect($customer->isMerchant())->toBeFalse();
});

test('panel access authorization strictly enforces roles and state', function () {
    $adminPanel = new Panel;
    $adminPanel->id('admin');

    $ownerPanel = new Panel;
    $ownerPanel->id('owner');

    $store = Store::create([
        'name' => 'Test Store',
        'phone' => '123456789',
        'is_active' => true,
    ]);

    $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
    $owner = User::factory()->merchant()->create(['store_id' => $store->id, 'is_active' => true]);
    $inactiveOwner = User::factory()->merchant()->create(['store_id' => $store->id, 'is_active' => false]);
    $unassignedOwner = User::factory()->merchant()->create(['store_id' => null, 'is_active' => true]);
    $customer = User::factory()->create(['role' => 'customer', 'is_active' => true]);

    // Admin Panel access
    expect($admin->canAccessPanel($adminPanel))->toBeTrue();
    expect($owner->canAccessPanel($adminPanel))->toBeFalse();
    expect($customer->canAccessPanel($adminPanel))->toBeFalse();

    // Owner Panel access
    expect($owner->canAccessPanel($ownerPanel))->toBeTrue();
    expect($admin->canAccessPanel($ownerPanel))->toBeFalse();
    expect($inactiveOwner->canAccessPanel($ownerPanel))->toBeFalse();
    expect($unassignedOwner->canAccessPanel($ownerPanel))->toBeFalse();
    expect($customer->canAccessPanel($ownerPanel))->toBeFalse();
});

test('store owner widget computes scoped kpi metrics correctly', function () {
    $storeA = Store::create(['name' => 'Store A', 'phone' => '111', 'is_active' => true]);
    $storeB = Store::create(['name' => 'Store B', 'phone' => '222', 'is_active' => true]);

    $ownerA = User::factory()->merchant()->create(['store_id' => $storeA->id]);

    Coupon::create([
        'store_id' => $storeA->id,
        'title' => 'Coupon A',
        'code' => 'CODE-A',
        'discount_type' => 'percentage',
        'discount_value' => 10,
        'creation_fee' => 5,
        'redemption_fee' => 1,
        'expires_at' => now()->addDays(7),
        'is_active' => true,
    ]);

    Coupon::create([
        'store_id' => $storeB->id,
        'title' => 'Coupon B',
        'code' => 'CODE-B',
        'discount_type' => 'percentage',
        'discount_value' => 20,
        'creation_fee' => 5,
        'redemption_fee' => 1,
        'expires_at' => now()->addDays(7),
        'is_active' => true,
    ]);

    $branchA = Branch::create([
        'store_id' => $storeA->id,
        'name' => 'Branch A',
        'is_active' => true,
    ]);

    $customer = User::factory()->create(['role' => 'customer']);

    Redemption::create([
        'coupon_id' => 1,
        'user_id' => $customer->id,
        'branch_id' => $branchA->id,
        'qr_code_hash' => 'hash123',
        'points_awarded' => 50,
        'charged_fee' => 2.50,
        'redeemed_at' => now(),
    ]);

    $this->actingAs($ownerA);

    $widget = new OwnerStatsOverview;
    $reflection = new ReflectionClass($widget);
    $method = $reflection->getMethod('getStats');
    $method->setAccessible(true);
    $stats = $method->invoke($widget);

    expect($stats)->toBeArray()->toHaveCount(4);
    expect($stats[0]->getValue())->toBe(1); // 1 active coupon for Store A
    expect($stats[1]->getValue())->toBe(1); // 1 redemption for Store A
    expect($stats[2]->getValue())->toBe('$2.50'); // $2.50 fee for Store A
});
