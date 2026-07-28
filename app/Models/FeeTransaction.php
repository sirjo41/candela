<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeeTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'wallet_id',
        'store_id',
        'type',
        'amount',
        'currency',
        'balance_after',
        'reference_id',
        'reference_type',
        'status',
        'notes',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function merchant(): BelongsTo
    {
        return $this->store();
    }
}
