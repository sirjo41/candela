<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use InvalidArgumentException;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'user_id',
        'balance',
        'currency',
        'status',
    ];

    protected $casts = [
        'balance' => 'decimal:2',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function merchant(): BelongsTo
    {
        return $this->store();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function feeTransactions(): HasMany
    {
        return $this->hasMany(FeeTransaction::class);
    }

    /**
     * Deduct funds from the wallet and record a fee transaction.
     */
    public function deduct(float $amount, string $type, ?int $referenceId = null, ?string $referenceType = null, ?string $notes = null): FeeTransaction
    {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Deduction amount must be greater than zero.');
        }

        if ((float) $this->balance < $amount) {
            throw new InvalidArgumentException('Insufficient wallet balance.');
        }

        $this->balance = (float) $this->balance - $amount;
        $this->save();

        return $this->feeTransactions()->create([
            'store_id' => $this->store_id,
            'type' => $type,
            'amount' => $amount,
            'currency' => $this->currency ?? 'D.L',
            'balance_after' => $this->balance,
            'reference_id' => $referenceId,
            'reference_type' => $referenceType,
            'status' => 'completed',
            'notes' => $notes,
        ]);
    }

    /**
     * Deposit funds into the wallet and record a fee transaction.
     */
    public function deposit(float $amount, string $type = 'deposit', ?int $referenceId = null, ?string $referenceType = null, ?string $notes = null): FeeTransaction
    {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Deposit amount must be greater than zero.');
        }

        $this->balance = (float) $this->balance + $amount;
        $this->save();

        return $this->feeTransactions()->create([
            'store_id' => $this->store_id,
            'type' => $type,
            'amount' => $amount,
            'currency' => $this->currency ?? 'D.L',
            'balance_after' => $this->balance,
            'reference_id' => $referenceId,
            'reference_type' => $referenceType,
            'status' => 'completed',
            'notes' => $notes,
        ]);
    }
}
