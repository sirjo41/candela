<?php

namespace Database\Factories;

use App\Models\Store;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Store>
 */
class StoreFactory extends Factory
{
    protected $model = Store::class;

    public function definition(): array
    {
        return [
            'name' => fake()->company(),
            'logo' => 'logos/default.png',
            'phone' => fake()->phoneNumber(),
            'is_active' => true,
            'creation_fee_rate' => 5.00,
            'redemption_fee_rate' => 1.50,
        ];
    }
}
