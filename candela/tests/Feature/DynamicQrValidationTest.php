<?php

use App\Models\Branch;
use App\Models\Campaign;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;

test('customer can list active campaigns', function () {
    Campaign::factory()->create([
        'title' => 'Summer Sale Campaign',
        'is_active' => true,
        'start_date' => now()->subDays(2),
        'end_date' => now()->addDays(10),
    ]);

    Campaign::factory()->create([
        'title' => 'Inactive Campaign',
        'is_active' => false,
    ]);

    $response = $this->getJson('/api/v1/customer/campaigns');

    $response->assertSuccessful()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.title', 'Summer Sale Campaign');
});

test('customer can list active coupons with store, campaign, and location filters', function () {
    $storeA = Store::factory()->create(['name' => 'Store Alpha']);
    Branch::factory()->create(['store_id' => $storeA->id, 'address' => 'Downtown Beirut']);

    $storeB = Store::factory()->create(['name' => 'Store Beta']);
    Branch::factory()->create(['store_id' => $storeB->id, 'address' => 'Uptown Tripoli']);

    $campaign = Campaign::factory()->create(['title' => 'Mega Deals']);

    $couponA = Coupon::factory()->create([
        'store_id' => $storeA->id,
        'campaign_id' => $campaign->id,
        'title' => 'Alpha Coupon',
        'is_active' => true,
        'expires_at' => now()->addDays(5),
    ]);

    $couponB = Coupon::factory()->create([
        'store_id' => $storeB->id,
        'title' => 'Beta Coupon',
        'is_active' => true,
        'expires_at' => now()->addDays(5),
    ]);

    // Test filter by store
    $responseStore = $this->getJson('/api/v1/customer/coupons?store_id=' . $storeA->id);
    $responseStore->assertSuccessful()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.title', 'Alpha Coupon');

    // Test filter by campaign
    $responseCampaign = $this->getJson('/api/v1/customer/coupons?campaign_id=' . $campaign->id);
    $responseCampaign->assertSuccessful()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.title', 'Alpha Coupon');

    // Test filter by location
    $responseLocation = $this->getJson('/api/v1/customer/coupons?location=Tripoli');
    $responseLocation->assertSuccessful()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.title', 'Beta Coupon');
});

test('customer can claim a coupon and view profile wallet', function () {
    $customer = User::factory()->customer()->create();
    Sanctum::actingAs($customer);

    $coupon = Coupon::factory()->create([
        'title' => '10% Off Coffee',
        'is_active' => true,
        'expires_at' => now()->addDays(5),
    ]);

    $claimResponse = $this->postJson('/api/v1/customer/coupons/' . $coupon->id . '/claim');
    $claimResponse->assertCreated()
        ->assertJsonPath('claimed_coupon.status', 'claimed')
        ->assertJsonPath('claimed_coupon.coupon.title', '10% Off Coffee');

    $this->assertDatabaseHas('claimed_coupons', [
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'status' => 'claimed',
    ]);

    $profileResponse = $this->getJson('/api/v1/customer/profile');
    $profileResponse->assertSuccessful()
        ->assertJsonPath('user.id', $customer->id)
        ->assertJsonCount(1, 'claimed_coupons');
});

test('customer can generate encrypted time-sensitive QR code payload', function () {
    $customer = User::factory()->customer()->create();
    Sanctum::actingAs($customer);

    $coupon = Coupon::factory()->create([
        'is_active' => true,
        'expires_at' => now()->addDays(5),
    ]);

    $response = $this->postJson('/api/v1/qr/generate', [
        'coupon_id' => $coupon->id,
        'valid_seconds' => 120,
    ]);

    $response->assertSuccessful()
        ->assertJsonStructure(['qr_code_hash', 'expires_at', 'valid_seconds']);

    $hash = $response->json('qr_code_hash');
    $decrypted = json_decode(Crypt::decrypt($hash), true);

    expect($decrypted['user_id'])->toBe($customer->id);
    expect($decrypted['coupon_id'])->toBe($coupon->id);
    expect($decrypted)->toHaveKey('expires_at');
});

test('merchant can validate valid QR code payload and execute atomic redemption', function () {
    $store = Store::factory()->create([
        'name' => 'Pizza Palace',
        'redemption_fee_rate' => 2.50,
    ]);
    $branch = Branch::factory()->create(['store_id' => $store->id]);

    $merchant = User::factory()->merchant()->create(['store_id' => $store->id]);
    $customer = User::factory()->customer()->create(['loyalty_points' => 50]);

    $coupon = Coupon::factory()->create([
        'store_id' => $store->id,
        'title' => '20% Off Pizza',
        'discount_type' => 'percentage',
        'discount_value' => 20.00,
        'redemption_fee' => 2.50,
        'max_uses' => 10,
        'uses_count' => 0,
        'is_active' => true,
        'expires_at' => now()->addDays(5),
    ]);

    $claimed = ClaimedCoupon::create([
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'status' => 'claimed',
        'claimed_at' => now(),
    ]);

    $payload = [
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'claimed_id' => $claimed->id,
        'created_at' => now()->timestamp,
        'expires_at' => now()->addSeconds(120)->timestamp,
        'nonce' => Str::random(16),
    ];
    $qrCodeHash = Crypt::encrypt(json_encode($payload));

    Sanctum::actingAs($merchant);

    $response = $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => $qrCodeHash,
        'branch_id' => $branch->id,
    ]);

    $response->assertSuccessful()
        ->assertJsonPath('message', 'Coupon redeemed successfully')
        ->assertJsonPath('discount.title', '20% Off Pizza')
        ->assertJsonPath('redemption.charged_fee', 2.5)
        ->assertJsonPath('customer.new_loyalty_points', 60);

    // Verify DB mutations
    expect($coupon->fresh()->uses_count)->toBe(1);
    expect($claimed->fresh()->status)->toBe('redeemed');
    expect($customer->fresh()->loyalty_points)->toBe(60);

    $this->assertDatabaseHas('redemptions', [
        'coupon_id' => $coupon->id,
        'user_id' => $customer->id,
        'branch_id' => $branch->id,
        'charged_fee' => 2.50,
        'points_awarded' => 10,
    ]);
});

test('merchant QR validation fails for expired QR code (>120s old)', function () {
    $store = Store::factory()->create();
    $branch = Branch::factory()->create(['store_id' => $store->id]);
    $merchant = User::factory()->merchant()->create(['store_id' => $store->id]);
    $customer = User::factory()->customer()->create();

    $coupon = Coupon::factory()->create(['store_id' => $store->id, 'expires_at' => now()->addDays(5)]);
    $claimed = ClaimedCoupon::create([
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'status' => 'claimed',
    ]);

    // Payload expired 10 seconds ago
    $payload = [
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'claimed_id' => $claimed->id,
        'created_at' => now()->subSeconds(130)->timestamp,
        'expires_at' => now()->subSeconds(10)->timestamp,
        'nonce' => Str::random(16),
    ];
    $expiredHash = Crypt::encrypt(json_encode($payload));

    Sanctum::actingAs($merchant);

    $response = $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => $expiredHash,
        'branch_id' => $branch->id,
    ]);

    $response->assertUnprocessable()
        ->assertJsonPath('message', 'QR code has expired. Please ask customer to refresh QR code.');
});

test('merchant QR validation fails for tampered or invalid hash', function () {
    $store = Store::factory()->create();
    $merchant = User::factory()->merchant()->create(['store_id' => $store->id]);

    Sanctum::actingAs($merchant);

    $response = $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => 'invalid_tampered_payload_string',
    ]);

    $response->assertUnprocessable()
        ->assertJsonPath('message', 'Invalid or tampered QR code payload.');
});

test('merchant QR validation prevents double-spending', function () {
    $store = Store::factory()->create();
    $branch = Branch::factory()->create(['store_id' => $store->id]);
    $merchant = User::factory()->merchant()->create(['store_id' => $store->id]);
    $customer = User::factory()->customer()->create();

    $coupon = Coupon::factory()->create(['store_id' => $store->id, 'expires_at' => now()->addDays(5)]);
    $claimed = ClaimedCoupon::create([
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'status' => 'claimed',
    ]);

    $payload = [
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'claimed_id' => $claimed->id,
        'created_at' => now()->timestamp,
        'expires_at' => now()->addSeconds(120)->timestamp,
        'nonce' => Str::random(16),
    ];
    $qrCodeHash = Crypt::encrypt(json_encode($payload));

    Sanctum::actingAs($merchant);

    // First redemption succeeds
    $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => $qrCodeHash,
        'branch_id' => $branch->id,
    ])->assertSuccessful();

    // Second redemption attempt fails
    $response = $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => $qrCodeHash,
        'branch_id' => $branch->id,
    ]);

    $response->assertUnprocessable()
        ->assertJsonPath('message', 'This QR code payload has already been processed.');
});

test('merchant QR validation fails if max_uses limit is reached', function () {
    $store = Store::factory()->create();
    $branch = Branch::factory()->create(['store_id' => $store->id]);
    $merchant = User::factory()->merchant()->create(['store_id' => $store->id]);
    $customer = User::factory()->customer()->create();

    $coupon = Coupon::factory()->create([
        'store_id' => $store->id,
        'max_uses' => 1,
        'uses_count' => 1, // Already at max limit
        'expires_at' => now()->addDays(5),
    ]);

    $claimed = ClaimedCoupon::create([
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'status' => 'claimed',
    ]);

    $payload = [
        'user_id' => $customer->id,
        'coupon_id' => $coupon->id,
        'claimed_id' => $claimed->id,
        'created_at' => now()->timestamp,
        'expires_at' => now()->addSeconds(120)->timestamp,
        'nonce' => Str::random(16),
    ];
    $qrCodeHash = Crypt::encrypt(json_encode($payload));

    Sanctum::actingAs($merchant);

    $response = $this->postJson('/api/v1/qr/validate', [
        'qr_code_hash' => $qrCodeHash,
        'branch_id' => $branch->id,
    ]);

    $response->assertUnprocessable();
});
