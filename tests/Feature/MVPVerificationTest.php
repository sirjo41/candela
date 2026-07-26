<?php

use App\Filament\Widgets\RedemptionsChart;
use App\Filament\Widgets\StatsOverview;
use App\Models\Branch;
use App\Models\Campaign;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Database\Seeders\MVPDataSeeder;

test('mvp database seeder populates core entities correctly', function () {
    $this->seed(MVPDataSeeder::class);

    expect(Store::count())->toBeGreaterThanOrEqual(2);
    expect(Branch::count())->toBeGreaterThanOrEqual(3);
    expect(Campaign::count())->toBeGreaterThanOrEqual(2);
    expect(Coupon::count())->toBeGreaterThanOrEqual(4);
    expect(Redemption::count())->toBeGreaterThanOrEqual(5);
});

test('stats overview widget computes dynamic figures without errors', function () {
    $widget = new StatsOverview;
    $reflection = new ReflectionClass($widget);
    $method = $reflection->getMethod('getStats');
    $method->setAccessible(true);
    $stats = $method->invoke($widget);

    expect($stats)->toBeArray()->toHaveCount(4);
});

test('redemptions chart widget computes trends without errors', function () {
    $widget = new RedemptionsChart;
    $reflection = new ReflectionClass($widget);
    $method = $reflection->getMethod('getData');
    $method->setAccessible(true);
    $data = $method->invoke($widget);

    expect($data)->toHaveKey('datasets');
    expect($data['datasets'][0]['data'])->toBeArray()->toHaveCount(12);
});
