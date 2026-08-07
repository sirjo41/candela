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
        'offer_id',
        'campaign_id',
        'user_id',
        'title',
        'code',
        'qr_token',
        'discount_type',
        'discount_value',
        'creation_fee',
        'redemption_fee',
        'max_uses',
        'uses_count',
        'status', // 'active', 'claimed', 'redeemed', 'used', 'expired'
        'expires_at',
        'redeemed_at',
        'is_active',
    ];

    protected $casts = [
        'discount_value' => 'decimal:2',
        'creation_fee' => 'decimal:2',
        'redemption_fee' => 'decimal:2',
        'expires_at' => 'datetime',
        'redeemed_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    protected static function booted(): void
    {
        static::creating(function (Coupon $coupon) {
            if ($coupon->store_id && ($coupon->creation_fee === null || (float)$coupon->creation_fee === 0.0)) {
                $store = $coupon->store ?? Store::find($coupon->store_id);
                if ($store && $store->creation_fee_rate !== null) {
                    $coupon->creation_fee = $store->creation_fee_rate;
                }
            }
            if ($coupon->store_id && ($coupon->redemption_fee === null || (float)$coupon->redemption_fee === 0.0)) {
                $store = $coupon->store ?? Store::find($coupon->store_id);
                if ($store && $store->redemption_fee_rate !== null) {
                    $coupon->redemption_fee = $store->redemption_fee_rate;
                }
            }
        });
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function campaign(): BelongsTo
    {
        return $this->belongsTo(Campaign::class);
    }

    public function merchant(): BelongsTo
    {
        return $this->store();
    }

    public function offer(): BelongsTo
    {
        return $this->belongsTo(Offer::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(Redemption::class);
    }

    /**
     * Check if the coupon is redeemed or used.
     */
    public function isRedeemed(): bool
    {
        return in_array($this->status, ['redeemed', 'used']) || $this->redeemed_at !== null;
    }

    /**
     * Check if the coupon is expired.
     */
    public function isExpired(): bool
    {
        if ($this->status === 'expired') {
            return true;
        }

        return $this->expires_at ? $this->expires_at->isPast() : false;
    }

    /**
     * Check if the coupon is active and valid for redemption.
     */
    public function isValidForRedemption(): bool
    {
        return $this->is_active && !$this->isRedeemed() && !$this->isExpired();
    }

    /**
     * Generate or ensure dynamic QR token payload.
     */
    public function ensureQrToken(): string
    {
        if (!empty($this->qr_token)) {
            return $this->qr_token;
        }

        $userId = $this->user_id ?? 1;
        $timestamp = now()->timestamp;
        $token = "CANDELA:{$userId}:{$this->code}:{$timestamp}";

        $this->qr_token = $token;
        $this->save();

        return $token;
    }
}