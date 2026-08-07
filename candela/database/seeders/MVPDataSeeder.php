<?php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\Campaign;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class MVPDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. System Admins
        $admin = User::firstOrCreate(
            ['email' => 'admin@candelasmart.com'],
            [
                'name' => 'National Admin',
                'phone' => '+1234567890',
                'loyalty_points' => 0,
                'is_active' => true,
                'role' => 'admin',
                'password' => Hash::make('password'),
            ]
        );

        User::firstOrCreate(
            ['email' => 'test@example.com'],
            [
                'name' => 'Test Admin',
                'phone' => '+1234567899',
                'loyalty_points' => 0,
                'is_active' => true,
                'role' => 'admin',
                'password' => Hash::make('password'),
            ]
        );

        // 2. Customers
        $customer1 = User::firstOrCreate(
            ['email' => 'alice@example.com'],
            [
                'name' => 'Alice Johnson',
                'phone' => '+1987654321',
                'loyalty_points' => 150,
                'is_active' => true,
                'role' => 'customer',
                'password' => Hash::make('password'),
            ]
        );

        $customer2 = User::firstOrCreate(
            ['email' => 'bob@example.com'],
            [
                'name' => 'Bob Smith',
                'phone' => '+1987654322',
                'loyalty_points' => 280,
                'is_active' => true,
                'role' => 'customer',
                'password' => Hash::make('password'),
            ]
        );

        $customer3 = User::firstOrCreate(
            ['email' => 'charlie@example.com'],
            [
                'name' => 'Charlie Davis',
                'phone' => '+1987654323',
                'loyalty_points' => 75,
                'is_active' => true,
                'role' => 'customer',
                'password' => Hash::make('password'),
            ]
        );

        // 3. Merchants (Stores)
        $store1 = Store::firstOrCreate(
            ['name' => 'Urban Coffee Co.'],
            [
                'logo' => 'stores/urban-coffee.jpg',
                'phone' => '+15550100',
                'creation_fee_rate' => 5.00,
                'redemption_fee_rate' => 0.50,
                'is_active' => true,
            ]
        );

        $store2 = Store::firstOrCreate(
            ['name' => 'Gourmet Burger Kitchen'],
            [
                'logo' => 'stores/gourmet-burger.jpg',
                'phone' => '+15550200',
                'creation_fee_rate' => 10.00,
                'redemption_fee_rate' => 1.00,
                'is_active' => true,
            ]
        );

        // Merchant Users assigned to stores
        User::firstOrCreate(
            ['email' => 'merchant1@example.com'],
            [
                'name' => 'Urban Coffee Merchant',
                'phone' => '+15550100',
                'loyalty_points' => 0,
                'is_active' => true,
                'role' => 'merchant',
                'store_id' => $store1->id,
                'password' => Hash::make('password'),
            ]
        );

        User::firstOrCreate(
            ['email' => 'merchant2@example.com'],
            [
                'name' => 'Gourmet Burger Merchant',
                'phone' => '+15550200',
                'loyalty_points' => 0,
                'is_active' => true,
                'role' => 'merchant',
                'store_id' => $store2->id,
                'password' => Hash::make('password'),
            ]
        );

        // 4. Branches
        $branch1 = Branch::firstOrCreate(
            ['store_id' => $store1->id, 'name' => 'Downtown Flagship'],
            [
                'address' => '123 Main St, Cityville',
                'phone' => '+15550101',
                'latitude' => 40.712800,
                'longitude' => -74.006000,
                'is_active' => true,
            ]
        );

        $branch2 = Branch::firstOrCreate(
            ['store_id' => $store1->id, 'name' => 'Airport Kiosk'],
            [
                'address' => 'Terminal 2, Metro Airport',
                'phone' => '+15550102',
                'latitude' => 40.641300,
                'longitude' => -73.778100,
                'is_active' => true,
            ]
        );

        $branch3 = Branch::firstOrCreate(
            ['store_id' => $store2->id, 'name' => 'Uptown Mall Branch'],
            [
                'address' => '456 High St, Cityville',
                'phone' => '+15550201',
                'latitude' => 40.758900,
                'longitude' => -73.985100,
                'is_active' => true,
            ]
        );

        // 5. Campaigns
        $campaign1 = Campaign::firstOrCreate(
          ['title' => 'حملة الانتعاش الصيفي'],
          [
            'description' => 'استمتع بأفضل المشروبات الباردة والحلويات الصيفية مع تخفيضات مباشرة.',
            'banner_image' => 'campaigns/summer-blast.jpg',
            'start_date' => now(),
            'end_date' => now()->addDays(30),
            'is_active' => true,
          ]
        );

        $campaign2 = Campaign::firstOrCreate(
          ['title' => 'حملة العودة للمدارس'],
          [
            'description' => 'عروض حصرية على الوجبات السريعة والمستلزمات لجميع الطلاب.',
            'banner_image' => 'campaigns/back-to-school.jpg',
            'start_date' => now(),
            'end_date' => now()->addDays(60),
            'is_active' => true,
          ]
        );

        $campaign3 = Campaign::firstOrCreate(
          ['title' => 'عروض نهاية الأسبوع المذهلة'],
          [
            'description' => 'تخفيضات خاصة على جميع الفروع في الويك إند.',
            'banner_image' => 'campaigns/weekend-deals.jpg',
            'start_date' => now(),
            'end_date' => now()->addDays(14),
            'is_active' => true,
          ]
        );

        // 6. Coupons
        $coupon1 = Coupon::firstOrCreate(
          ['code' => 'COLDBREW20'],
          [
            'store_id' => $store1->id,
            'campaign_id' => $campaign1->id,
            'title' => 'خصم 20% على القهوة الباردة',
            'discount_type' => 'percentage',
            'discount_value' => 20.00,
            'creation_fee' => 5.00,
            'redemption_fee' => 0.50,
            'max_uses' => 100,
            'uses_count' => 2,
            'expires_at' => now()->addDays(30),
            'is_active' => true,
          ]
        );

        $coupon2 = Coupon::firstOrCreate(
          ['code' => 'FREEMUFFIN'],
          [
            'store_id' => $store1->id,
            'campaign_id' => $campaign1->id,
            'title' => 'خصم 5 د.ل على المأكولات والمشروبات',
            'discount_type' => 'fixed',
            'discount_value' => 5.00,
            'creation_fee' => 5.00,
            'redemption_fee' => 0.50,
            'max_uses' => 50,
            'uses_count' => 1,
            'expires_at' => now()->addDays(20),
            'is_active' => true,
          ]
        );

        $coupon3 = Coupon::firstOrCreate(
          ['code' => 'BURGERBOGO'],
          [
            'store_id' => $store2->id,
            'campaign_id' => $campaign2->id,
            'title' => 'خصم 50% على الوجبة الثانية',
            'discount_type' => 'percentage',
            'discount_value' => 50.00,
            'creation_fee' => 10.00,
            'redemption_fee' => 1.00,
            'max_uses' => 200,
            'uses_count' => 1,
            'expires_at' => now()->addDays(45),
            'is_active' => true,
          ]
        );

        $coupon4 = Coupon::firstOrCreate(
          ['code' => 'COMBO5OFF'],
          [
            'store_id' => $store2->id,
            'campaign_id' => $campaign3->id,
            'title' => 'خصم 10 د.ل على وجبات الكومبو',
            'discount_type' => 'fixed',
            'discount_value' => 10.00,
            'creation_fee' => 10.00,
            'redemption_fee' => 1.00,
            'max_uses' => 150,
            'uses_count' => 1,
            'expires_at' => now()->addDays(60),
            'is_active' => true,
          ]
        );

        // 7. Redemptions
        if (Redemption::count() === 0) {
            Redemption::create([
                'coupon_id' => $coupon1->id,
                'user_id' => $customer1->id,
                'branch_id' => $branch1->id,
                'qr_code_hash' => Str::random(32),
                'points_awarded' => 20,
                'charged_fee' => 0.50,
                'redeemed_at' => now()->subDays(4),
            ]);

            Redemption::create([
                'coupon_id' => $coupon1->id,
                'user_id' => $customer2->id,
                'branch_id' => $branch2->id,
                'qr_code_hash' => Str::random(32),
                'points_awarded' => 20,
                'charged_fee' => 0.50,
                'redeemed_at' => now()->subDays(3),
            ]);

            Redemption::create([
                'coupon_id' => $coupon2->id,
                'user_id' => $customer3->id,
                'branch_id' => $branch1->id,
                'qr_code_hash' => Str::random(32),
                'points_awarded' => 15,
                'charged_fee' => 0.50,
                'redeemed_at' => now()->subDays(2),
            ]);

            Redemption::create([
                'coupon_id' => $coupon3->id,
                'user_id' => $customer1->id,
                'branch_id' => $branch3->id,
                'qr_code_hash' => Str::random(32),
                'points_awarded' => 50,
                'charged_fee' => 1.00,
                'redeemed_at' => now()->subDays(1),
            ]);

            Redemption::create([
                'coupon_id' => $coupon4->id,
                'user_id' => $customer2->id,
                'branch_id' => $branch3->id,
                'qr_code_hash' => Str::random(32),
                'points_awarded' => 25,
                'charged_fee' => 1.00,
                'redeemed_at' => now(),
            ]);
        }
    }
}
