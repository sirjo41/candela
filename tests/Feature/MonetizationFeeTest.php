<?php

use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use App\Models\Branch;

it('automatically sets coupon fees from store rates upon creation', function () {
    $store = Store::create([
        'name' => 'Test Store',
        'creation_fee_rate' => 5.50,
        'redemption_fee_rate' => 1.25,
    ]);

    $coupon = Coupon::create([
        'store_id' => $store->id,
        'title' => 'Test Coupon',
        'code' => 'TEST1234',
        'discount_type' => 'percentage',
        'discount_value' => 10,
        'expires_at' => now()->addDays(7),
        'creation_fee' => 0,
        'redemption_fee' => 0,
    ]);

    expect($coupon->creation_fee)->toEqual(5.50)
        ->and($coupon->redemption_fee)->toEqual(1.25);
});

it('calculates total creation fees for a store', function () {
    $store = Store::create([
        'name' => 'Test Store 2'
    ]);

    for ($i = 0; $i < 3; $i++) {
        Coupon::create([
            'store_id' => $store->id,
            'title' => 'Coupon ' . $i,
            'code' => 'CODE_' . uniqid(),
            'discount_type' => 'fixed_amount',
            'discount_value' => 5,
            'expires_at' => now()->addDays(7),
            'creation_fee' => 10.00,
        ]);
    }

    expect($store->total_creation_fees)->toEqual(30.00);
});

it('calculates total redemption fees for a store', function () {
    $store = Store::create(['name' => 'Test Store 3']);
    
    $coupon1 = Coupon::create([
        'store_id' => $store->id,
        'title' => 'C1',
        'code' => 'C1_' . uniqid(),
        'discount_type' => 'percentage',
        'discount_value' => 10,
        'expires_at' => now()->addDays(7),
    ]);
    $coupon2 = Coupon::create([
        'store_id' => $store->id,
        'title' => 'C2',
        'code' => 'C2_' . uniqid(),
        'discount_type' => 'percentage',
        'discount_value' => 10,
        'expires_at' => now()->addDays(7),
    ]);

    $branch = Branch::create(['store_id' => $store->id, 'name' => 'B1', 'city' => 'City', 'address' => 'Addr']);
    $user = User::create(['name' => 'U1', 'email' => 'u1@test.com', 'password' => 'pwd']);

    Redemption::create([
        'coupon_id' => $coupon1->id,
        'branch_id' => $branch->id,
        'user_id' => $user->id,
        'qr_code_hash' => 'hash1',
        'charged_fee' => 2.50,
        'redeemed_at' => now(),
    ]);

    Redemption::create([
        'coupon_id' => $coupon2->id,
        'branch_id' => $branch->id,
        'user_id' => $user->id,
        'qr_code_hash' => 'hash2',
        'charged_fee' => 1.50,
        'redeemed_at' => now(),
    ]);

    expect($store->total_redemption_fees)->toEqual(4.00)
        ->and($store->grand_total_fees)->toEqual($store->total_creation_fees + 4.00);
});

it('allows admin to override fees manually', function () {
    $store = Store::create([
        'name' => 'Test Store 4',
        'creation_fee_rate' => 5.50,
    ]);

    $coupon = Coupon::create([
        'store_id' => $store->id,
        'title' => 'C3',
        'code' => 'C3_' . uniqid(),
        'discount_type' => 'percentage',
        'discount_value' => 10,
        'expires_at' => now()->addDays(7),
        'creation_fee' => 15.00, // Explicit override
    ]);

    expect($coupon->creation_fee)->toEqual(15.00);
});
