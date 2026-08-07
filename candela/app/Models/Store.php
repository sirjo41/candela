<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Store extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'business_registration',
        'logo',
        'phone',
        'address',
        'latitude',
        'longitude',
        'is_active',
        'creation_fee_rate',
        'redemption_fee_rate',
        'balance',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'creation_fee_rate' => 'decimal:2',
        'redemption_fee_rate' => 'decimal:2',
        'balance' => 'decimal:2',
        'latitude' => 'float',
        'longitude' => 'float',
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

    public function offers(): HasMany
    {
        return $this->hasMany(Offer::class);
    }

    public function coupons(): HasMany
    {
        return $this->hasMany(Coupon::class);
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(Redemption::class);
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class, 'store_id');
    }

    public function feeTransactions(): HasMany
    {
        return $this->hasMany(FeeTransaction::class, 'store_id');
    }

    /**
     * Get or create platform wallet for merchant.
     */
    public function getOrCreateWallet(): Wallet
    {
        if ($this->wallet) {
            return $this->wallet;
        }

        return $this->wallet()->create([
            'balance' => $this->balance ?? 500.00,
            'currency' => 'D.L',
            'status' => 'active',
        ]);
    }

    public function getTotalCreationFeesAttribute(): float
    {
        return (float) $this->coupons()->sum('creation_fee');
    }

    public function getTotalRedemptionFeesAttribute(): float
    {
        $storeId = $this->id;
        return (float) Redemption::query()
            ->where(function ($q) use ($storeId) {
                $q->where('store_id', $storeId)
                  ->orWhereHas('branch', fn ($bq) => $bq->where('store_id', $storeId))
                  ->orWhereHas('coupon', fn ($cq) => $cq->where('store_id', $storeId));
            })
            ->sum('charged_fee');
    }

    public function getGrandTotalFeesAttribute(): float
    {
        return $this->total_creation_fees + $this->total_redemption_fees;
    }
}