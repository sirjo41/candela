<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Offer extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'store_id',
        'title',
        'description',
        'category',
        'original_price',
        'discount_rate',
        'final_price',
        'creation_fee',
        'redemption_fee',
        'discount_badge',
        'banner_image',
        'branch_location',
        'latitude',
        'longitude',
        'valid_until',
        'is_active',
    ];

    protected $casts = [
        'original_price' => 'decimal:2',
        'discount_rate' => 'decimal:2',
        'final_price' => 'decimal:2',
        'creation_fee' => 'decimal:2',
        'redemption_fee' => 'decimal:2',
        'latitude' => 'float',
        'longitude' => 'float',
        'valid_until' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function merchant(): BelongsTo
    {
        return $this->store();
    }

    public function coupons(): HasMany
    {
        return $this->hasMany(Coupon::class);
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(Redemption::class);
    }

    /**
     * Calculate final price in D.L given original price and discount rate percentage.
     */
    public static function calculateFinalPrice(float $originalPrice, float $discountRate): float
    {
        if ($originalPrice <= 0) return 0.0;
        $discountAmount = ($originalPrice * $discountRate) / 100.0;
        $final = $originalPrice - $discountAmount;
        return round(max(0, $final), 2);
    }

    /**
     * Scope query to filter active and non-expired offers.
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true)
                     ->where('valid_until', '>', now());
    }

    /**
     * Scope query to filter by category.
     */
    public function scopeByCategory(Builder $query, ?string $category): Builder
    {
        if (empty($category) || strtolower($category) === 'all') {
            return $query;
        }

        if (strtolower($category) === 'hot deals') {
            return $query->where(function ($q) {
                $q->where('discount_rate', '>=', 40)
                  ->orWhere('category', 'Hot Deals');
            });
        }

        return $query->whereRaw('LOWER(category) = ?', [strtolower($category)]);
    }

    /**
     * Scope query to filter by minimum discount percentage.
     */
    public function scopeMinDiscount(Builder $query, ?float $minDiscount): Builder
    {
        if ($minDiscount === null || $minDiscount <= 0) {
            return $query;
        }
        return $query->where('discount_rate', '>=', $minDiscount);
    }

    /**
     * Scope query to filter by location proximity (Haversine formula in KM).
     */
    public function scopeWithinDistance(Builder $query, ?float $latitude, ?float $longitude, float $radiusKm = 10.0): Builder
    {
        if ($latitude === null || $longitude === null) {
            return $query;
        }

        $haversine = "(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude))))";

        return $query->select('*')
                     ->selectRaw("{$haversine} AS distance_km", [$latitude, $longitude, $latitude])
                     ->having('distance_km', '<=', $radiusKm)
                     ->orderBy('distance_km', 'asc');
    }
}
