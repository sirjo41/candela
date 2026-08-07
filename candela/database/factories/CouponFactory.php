<?php

namespace Database\Factories;

use App\Models\Campaign;
use App\Models\Coupon;
use App\Models\Store;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Coupon>
 */
class CouponFactory extends Factory
{
    protected $model = Coupon::class;

    public function definition(): array
    {
        return [
            'store_id' => Store::factory(),
            'campaign_id' => Campaign::factory(),
            'title' => fake()->words(3, true),
            'code' => 'COUPON-'.strtoupper(Str::random(6)),
            'discount_type' => 'percentage',
            'discount_value' => 20.00,
            'max_uses' => 100,
            'uses_count' => 0,
            'creation_fee' => 5.00,
            'redemption_fee' => 1.50,
            'expires_at' => now()->addDays(10),
            'is_active' => true,
        ];
    }
}
