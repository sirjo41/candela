<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Redemption extends Model
{
    use HasFactory;

    protected $fillable = [
        'coupon_id',
        'offer_id',
        'store_id',
        'user_id',
        'staff_user_id',
        'branch_id',
        'qr_code_hash',
        'qr_token',
        'points_awarded',
        'charged_fee',
        'status',
        'redeemed_at',
    ];

    protected $casts = [
        'charged_fee' => 'decimal:2',
        'points_awarded' => 'integer',
        'redeemed_at' => 'datetime',
    ];

    public function coupon(): BelongsTo
    {
        return $this->belongsTo(Coupon::class);
    }

    public function offer(): BelongsTo
    {
        return $this->belongsTo(Offer::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function merchant(): BelongsTo
    {
        return $this->store();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function staffUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'staff_user_id');
    }
}