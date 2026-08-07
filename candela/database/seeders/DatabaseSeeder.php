<?php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\Campaign;
use App\Models\Coupon;
use App\Models\Offer;
use App\Models\Store;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with production-like testing data.
     */
    public function run(): void
    {
        // 1. Create Admin Account
        $admin = User::firstOrCreate(
            ['email' => 'admin@candela.app'],
            [
                'name' => 'System Administrator',
                'phone' => '+201000000000',
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'is_merchant' => false,
                'is_active' => true,
                'loyalty_points' => 5000,
            ]
        );

        // 2. Create Demo Customer Account
        $customer = User::firstOrCreate(
            ['email' => 'customer@candela.app'],
            [
                'name' => 'Kareem Ahmed',
                'phone' => '+201011112222',
                'password' => Hash::make('password123'),
                'role' => 'customer',
                'is_merchant' => false,
                'is_active' => true,
                'loyalty_points' => 1250,
            ]
        );

        // 3. Create Production Merchant Stores & Staff Users with Funded Platform Wallets
        $merchantStoresData = [
            [
                'name' => 'Sultan Grill & Bistro',
                'business_registration' => 'CR-884920',
                'phone' => '+20227364001',
                'address' => '104 Nile Corniche, Downtown Cairo',
                'latitude' => 30.0444,
                'longitude' => 31.2357,
                'balance' => 1500.00,
                'creation_fee_rate' => 50.00,
                'redemption_fee_rate' => 5.00,
                'staff_email' => 'sultan@candela.app',
                'staff_name' => 'Sultan Owner',
            ],
            [
                'name' => 'Artisan Espresso Bar',
                'business_registration' => 'CR-552194',
                'phone' => '+20227364002',
                'address' => '22 26th July St, Zamalek, Cairo',
                'latitude' => 30.0617,
                'longitude' => 31.2198,
                'balance' => 800.00,
                'creation_fee_rate' => 50.00,
                'redemption_fee_rate' => 5.00,
                'staff_email' => 'artisan@candela.app',
                'staff_name' => 'Artisan Barista',
            ],
            [
                'name' => 'Urban Outfitters & Style',
                'business_registration' => 'CR-339102',
                'phone' => '+20227364003',
                'address' => 'Level 2, City Center Mall, New Cairo',
                'latitude' => 30.0285,
                'longitude' => 31.4722,
                'balance' => 2000.00,
                'creation_fee_rate' => 50.00,
                'redemption_fee_rate' => 5.00,
                'staff_email' => 'urban@candela.app',
                'staff_name' => 'Urban Manager',
            ],
        ];

        foreach ($merchantStoresData as $sData) {
            $store = Store::firstOrCreate(
                ['name' => $sData['name']],
                [
                    'business_registration' => $sData['business_registration'],
                    'phone' => $sData['phone'],
                    'address' => $sData['address'],
                    'latitude' => $sData['latitude'],
                    'longitude' => $sData['longitude'],
                    'balance' => $sData['balance'],
                    'creation_fee_rate' => $sData['creation_fee_rate'],
                    'redemption_fee_rate' => $sData['redemption_fee_rate'],
                    'is_active' => true,
                ]
            );

            // Create or fund Wallet
            Wallet::firstOrCreate(
                ['store_id' => $store->id],
                [
                    'balance' => $sData['balance'],
                    'currency' => 'D.L',
                    'status' => 'active',
                ]
            );

            // Create Merchant Staff User
            User::firstOrCreate(
                ['email' => $sData['staff_email']],
                [
                    'name' => $sData['staff_name'],
                    'phone' => $sData['phone'],
                    'password' => Hash::make('password123'),
                    'role' => 'merchant_staff',
                    'is_merchant' => true,
                    'store_id' => $store->id,
                    'is_active' => true,
                ]
            );

            // Create Primary Branch
            Branch::firstOrCreate(
                ['store_id' => $store->id, 'name' => $store->name . ' Main Branch'],
                [
                    'address' => $sData['address'],
                    'phone' => $sData['phone'],
                    'is_active' => true,
                ]
            );
        }

        // 4. Seed Realistic Production Offers across Categories
        $sultanStore = Store::where('name', 'Sultan Grill & Bistro')->first();
        $artisanStore = Store::where('name', 'Artisan Espresso Bar')->first();
        $urbanStore = Store::where('name', 'Urban Outfitters & Style')->first();

        $offersData = [
            [
                'store_id' => $sultanStore->id,
                'title' => 'Sultan Grill Platter Special',
                'description' => 'Authentic oriental grill platter with appetizers and soft drink.',
                'category' => 'Restaurants',
                'original_price' => 250.00,
                'discount_rate' => 30.00,
                'final_price' => 175.00,
                'discount_badge' => '-30%',
                'branch_location' => $sultanStore->address,
                'latitude' => $sultanStore->latitude,
                'longitude' => $sultanStore->longitude,
                'valid_until' => now()->addDays(7),
            ],
            [
                'store_id' => $artisanStore->id,
                'title' => 'Specialty Cold Brew & Latte BOGO',
                'description' => 'Buy any specialty latte or cold brew and get the second beverage free.',
                'category' => 'Cafes',
                'original_price' => 90.00,
                'discount_rate' => 50.00,
                'final_price' => 45.00,
                'discount_badge' => 'BUY 1 GET 1',
                'branch_location' => $artisanStore->address,
                'latitude' => $artisanStore->latitude,
                'longitude' => $artisanStore->longitude,
                'valid_until' => now()->addDays(14),
            ],
            [
                'store_id' => $urbanStore->id,
                'title' => 'Summer Denim & Essentials Sale',
                'description' => '50% Flat discount on all new summer arrivals and denim collection.',
                'category' => 'Shopping',
                'original_price' => 850.00,
                'discount_rate' => 50.00,
                'final_price' => 425.00,
                'discount_badge' => '-50%',
                'branch_location' => $urbanStore->address,
                'latitude' => $urbanStore->latitude,
                'longitude' => $urbanStore->longitude,
                'valid_until' => now()->addDays(10),
            ],
            [
                'store_id' => $sultanStore->id,
                'title' => 'Hot Deal: Sunset Mixed Grill Package',
                'description' => 'Sunset dinner package with river view seating included.',
                'category' => 'Hot Deals',
                'original_price' => 400.00,
                'discount_rate' => 40.00,
                'final_price' => 240.00,
                'discount_badge' => '-40%',
                'branch_location' => $sultanStore->address,
                'latitude' => $sultanStore->latitude,
                'longitude' => $sultanStore->longitude,
                'valid_until' => now()->addDays(3),
            ],
        ];

        foreach ($offersData as $oData) {
            $offer = Offer::firstOrCreate(
                ['title' => $oData['title']],
                array_merge($oData, [
                    'creation_fee' => 50.00,
                    'redemption_fee' => 5.00,
                    'is_active' => true,
                ])
            );

            // Create matching Campaign & Coupon records for testing
            $campaign = Campaign::firstOrCreate(
                ['title' => $oData['title']],
                [
                    'description' => $oData['description'],
                    'start_date' => now(),
                    'end_date' => $oData['valid_until'],
                    'is_active' => true,
                ]
            );

            $couponCode = 'CPN-' . strtoupper(substr(md5($offer->id . $oData['title']), 0, 8));
            $coupon = Coupon::firstOrCreate(
                ['code' => $couponCode],
                [
                    'store_id' => $offer->store_id,
                    'offer_id' => $offer->id,
                    'campaign_id' => $campaign->id,
                    'user_id' => $customer->id,
                    'title' => $oData['title'],
                    'discount_type' => 'percentage',
                    'discount_value' => $oData['discount_rate'],
                    'creation_fee' => 50.00,
                    'redemption_fee' => 5.00,
                    'status' => 'active',
                    'expires_at' => $oData['valid_until'],
                    'is_active' => true,
                ]
            );

            $coupon->ensureQrToken();
        }
    }
}
