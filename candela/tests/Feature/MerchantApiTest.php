<?php

use App\Models\Branch;
use App\Models\Campaign;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;

test('customer can view stores list', function () {
    $store = Store::factory()->create(['name' => 'City Supermarket', 'is_active' => true]);
    Branch::create([
        'store_id' => $store->id,
        'name' => 'Main Branch',
        'address' => '123 Main St',
        'is_active' => true,
    ]);

    $response = $this->getJson('/api/v1/customer/stores');

    $response->assertSuccessful()
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'name', 'branches'],
            ],
        ]);
});

test('customer can claim campaign coupon and access wallet', function () {
    $customer = User::factory()->create(['role' => 'customer', 'is_active' => true]);
    $store = Store::factory()->create();
    $coupon = Coupon::create([
        'store_id' => $store->id,
        'title' => '20% Off Coffee',
        'code' => 'COFFEE20',
        'discount_type' => 'percentage',
        'discount_value' => 20,
        'expires_at' => now()->addDays(5),
        'is_active' => true,
    ]);

    // Claim coupon via POST /api/v1/customer/campaigns/{id}/claim
    $response = $this->actingAs($customer)
        ->postJson("/api/v1/customer/campaigns/{$coupon->id}/claim");

    $response->assertCreated()
        ->assertJsonPath('claimed_coupon.coupon_id', $coupon->id);

    // Fetch wallet via GET /api/v1/customer/wallet
    $walletResponse = $this->actingAs($customer)
        ->getJson('/api/v1/customer/wallet');

    $walletResponse->assertSuccessful()
        ->assertJsonStructure([
            'wallet' => ['active', 'used', 'expired', 'qr_pass'],
            'user' => ['id', 'name', 'loyalty_points'],
        ])
        ->assertJsonCount(1, 'wallet.active');
});

test('merchant dashboard and history endpoints return store metrics and logs', function () {
    $store = Store::factory()->create(['name' => 'Merchant Bakery']);
    $merchant = User::factory()->merchant()->create(['store_id' => $store->id, 'is_active' => true]);
    $branch = Branch::create(['store_id' => $store->id, 'name' => 'Bakery Branch', 'is_active' => true]);
    $customer = User::factory()->create(['role' => 'customer']);

    $coupon = Coupon::create([
        'store_id' => $store->id,
        'title' => 'Free Muffin',
        'code' => 'MUFFIN1',
        'discount_type' => 'fixed_amount',
        'discount_value' => 5,
        'expires_at' => now()->addDays(3),
        'is_active' => true,
    ]);

    Redemption::create([
        'coupon_id' => $coupon->id,
        'user_id' => $customer->id,
        'branch_id' => $branch->id,
        'qr_code_hash' => 'hash_test_123',
        'points_awarded' => 10,
        'charged_fee' => 1.50,
        'redeemed_at' => now(),
    ]);

    // Test GET /api/v1/merchant/dashboard
    $dashResponse = $this->actingAs($merchant)
        ->getJson('/api/v1/merchant/dashboard');

    $dashResponse->assertSuccessful()
        ->assertJsonPath('dashboard.total_redemptions', 1)
        ->assertJsonPath('dashboard.total_pending_fees', 1.5)
        ->assertJsonPath('store.name', 'Merchant Bakery');

    // Test GET /api/v1/merchant/history
    $historyResponse = $this->actingAs($merchant)
        ->getJson('/api/v1/merchant/history');

    $historyResponse->assertSuccessful()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.qr_code_hash', 'hash_test_123');
});
