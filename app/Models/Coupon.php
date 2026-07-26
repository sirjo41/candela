<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Coupon extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'store_id',
        'campaign_id',
        'title',
        'code',
        'discount_type',
        'discount_value',
        'max_uses',
        'uses_count',
        'creation_fee',
        'redemption_fee',
        'expires_at',
        'is_active',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function campaign(): BelongsTo
    {
        return $this->belongsTo(Campaign::class);
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(Redemption::class);
    }

    protected static function booted()
    {
        static::creating(function (Coupon $coupon) {
            if ($coupon->store_id) {
                $store = $coupon->store;
                if ($store) {
                    if ($coupon->creation_fee === null || $coupon->creation_fee <= 0) {
                        $coupon->creation_fee = $store->creation_fee_rate;
                    }
                    if ($coupon->redemption_fee === null || $coupon->redemption_fee <= 0) {
                        $coupon->redemption_fee = $store->redemption_fee_rate;
                    }
                }
            }
        });
    }
}