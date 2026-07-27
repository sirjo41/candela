<?php

use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

test('customer registration successfully creates user and returns token', function () {
    $response = $this->postJson('/api/v1/auth/customer/register', [
        'name' => 'Alice Customer',
        'email' => 'alice@example.com',
        'phone' => '+1234567890',
        'password' => 'password123',
    ]);

    $response->assertCreated()
        ->assertJsonStructure([
            'message',
            'access_token',
            'token_type',
            'user' => ['id', 'name', 'email', 'phone', 'role', 'loyalty_points'],
        ]);

    $this->assertDatabaseHas('users', [
        'email' => 'alice@example.com',
        'phone' => '+1234567890',
        'role' => 'customer',
    ]);
});

test('customer registration fails when phone is duplicated', function () {
    User::factory()->create([
        'phone' => '+1234567890',
    ]);

    $response = $this->postJson('/api/v1/auth/customer/register', [
        'name' => 'Bob Customer',
        'email' => 'bob@example.com',
        'phone' => '+1234567890',
        'password' => 'password123',
    ]);

    $response->assertUnprocessable()
        ->assertJsonValidationErrors(['phone']);
});

test('customer login succeeds with valid credentials', function () {
    $customer = User::factory()->create([
        'phone' => '+1987654321',
        'password' => Hash::make('secret123'),
        'role' => 'customer',
        'is_active' => true,
    ]);

    $response = $this->postJson('/api/v1/auth/customer/login', [
        'phone' => '+1987654321',
        'password' => 'secret123',
    ]);

    $response->assertSuccessful()
        ->assertJsonStructure([
            'message',
            'access_token',
            'token_type',
            'user',
        ]);
});

test('customer login fails with invalid password or role', function () {
    User::factory()->create([
        'phone' => '+1987654321',
        'password' => Hash::make('secret123'),
        'role' => 'customer',
    ]);

    $response = $this->postJson('/api/v1/auth/customer/login', [
        'phone' => '+1987654321',
        'password' => 'wrongpassword',
    ]);

    $response->assertUnauthorized();
});

test('merchant login succeeds for store owner/merchant user with store data', function () {
    $store = Store::factory()->create(['name' => 'Awesome Store']);

    $merchant = User::factory()->create([
        'email' => 'merchant@example.com',
        'password' => Hash::make('merchant123'),
        'role' => 'merchant',
        'store_id' => $store->id,
        'is_active' => true,
    ]);

    $response = $this->postJson('/api/v1/auth/merchant/login', [
        'email' => 'merchant@example.com',
        'password' => 'merchant123',
    ]);

    $response->assertSuccessful()
        ->assertJsonStructure([
            'message',
            'access_token',
            'token_type',
            'user' => ['id', 'name', 'email', 'store_id'],
            'store' => ['id', 'name', 'is_active'],
        ])
        ->assertJsonPath('store.name', 'Awesome Store');
});

test('merchant login fails for customer users', function () {
    $customer = User::factory()->create([
        'email' => 'notmerchant@example.com',
        'password' => Hash::make('password123'),
        'role' => 'customer',
    ]);

    $response = $this->postJson('/api/v1/auth/merchant/login', [
        'email' => 'notmerchant@example.com',
        'password' => 'password123',
    ]);

    $response->assertUnauthorized();
});

test('protected API routes deny unauthenticated requests', function () {
    $this->getJson('/api/v1/customer/profile')->assertUnauthorized();
    $this->postJson('/api/v1/customer/coupons/1/claim')->assertUnauthorized();
    $this->postJson('/api/v1/qr/generate', ['coupon_id' => 1])->assertUnauthorized();
    $this->postJson('/api/v1/qr/validate', ['qr_code_hash' => 'dummy'])->assertUnauthorized();
});
