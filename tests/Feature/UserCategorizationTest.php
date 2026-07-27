<?php

use App\Models\Store;
use App\Models\User;
use App\Filament\Resources\CustomerResource;
use App\Filament\Resources\AdminResource;
use App\Filament\Resources\MerchantResource;
use App\Filament\Resources\UserResource;

test('user query scopes correctly categorize customers, admins, and merchants', function () {
    $admin = User::factory()->create(['role' => 'admin', 'email' => 'admin@example.com']);
    $nationalAdmin = User::factory()->create(['role' => 'national_admin', 'email' => 'nadmin@example.com']);
    
    $store = Store::create(['name' => 'Cat Store', 'phone' => '123456789', 'is_active' => true]);
    $storeOwner = User::factory()->create(['role' => 'store_owner', 'store_id' => $store->id, 'email' => 'owner@example.com']);
    $merchant = User::factory()->create(['role' => 'merchant', 'store_id' => $store->id, 'email' => 'merchant@example.com']);

    $customer = User::factory()->create(['role' => 'customer', 'email' => 'customer@example.com']);
    $defaultCustomer = User::factory()->create(['role' => 'customer', 'email' => 'defaultcust@example.com']);

    // Admins scope check
    $admins = User::query()->admins()->get();
    expect($admins->pluck('id'))->toContain($admin->id, $nationalAdmin->id);
    expect($admins->pluck('id'))->not->toContain($customer->id, $storeOwner->id);

    // Merchants scope check
    $merchants = User::query()->merchants()->get();
    expect($merchants->pluck('id'))->toContain($storeOwner->id, $merchant->id);
    expect($merchants->pluck('id'))->not->toContain($admin->id, $customer->id);

    // Customers scope check
    $customers = User::query()->customers()->get();
    expect($customers->pluck('id'))->toContain($customer->id, $defaultCustomer->id);
    expect($customers->pluck('id'))->not->toContain($admin->id, $storeOwner->id);
});

test('dedicated customer, admin, and merchant resources scope getEloquentQuery properly', function () {
    $admin = User::factory()->create(['role' => 'admin']);
    $owner = User::factory()->merchant()->create();
    $customer = User::factory()->create(['role' => 'customer']);

    $customerQuery = CustomerResource::getEloquentQuery()->get();
    expect($customerQuery->pluck('id'))->toContain($customer->id);
    expect($customerQuery->pluck('id'))->not->toContain($admin->id, $owner->id);

    $adminQuery = AdminResource::getEloquentQuery()->get();
    expect($adminQuery->pluck('id'))->toContain($admin->id);
    expect($adminQuery->pluck('id'))->not->toContain($customer->id, $owner->id);

    $merchantQuery = MerchantResource::getEloquentQuery()->get();
    expect($merchantQuery->pluck('id'))->toContain($owner->id);
    expect($merchantQuery->pluck('id'))->not->toContain($customer->id, $admin->id);
});
