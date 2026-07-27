<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\SoftDeletes;

class Store extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'logo',
        'phone',
        'is_active',
        'creation_fee_rate',
        'redemption_fee_rate',
    ];

    public function merchants(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function owners(): HasMany
    {
        return $this->merchants();
    }

    public function branches(): HasMany
    {
        return $this->hasMany(Branch::class);
    }

    public function coupons(): HasMany
    {
        return $this->hasMany(Coupon::class);
    }

    public function redemptions(): HasManyThrough
    {
        return $this->hasManyThrough(Redemption::class, Coupon::class);
    }

    public function getTotalCreationFeesAttribute(): float
    {
        return (float) $this->coupons()->sum('creation_fee');
    }

    public function getTotalRedemptionFeesAttribute(): float
    {
        return (float) $this->redemptions()->sum('charged_fee');
    }

    public function getGrandTotalFeesAttribute(): float
    {
        return $this->total_creation_fees + $this->total_redemption_fees;
    }
}