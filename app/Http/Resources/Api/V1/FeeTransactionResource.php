<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FeeTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'wallet_id' => $this->wallet_id,
            'store_id' => $this->store_id,
            'type' => $this->type,
            'amount' => (float) $this->amount,
            'amount_formatted' => number_format($this->amount, 2) . ' ' . ($this->currency ?? 'D.L'),
            'balance_after' => (float) $this->balance_after,
            'balance_after_formatted' => number_format($this->balance_after, 2) . ' ' . ($this->currency ?? 'D.L'),
            'currency' => $this->currency ?? 'D.L',
            'reference_id' => $this->reference_id,
            'reference_type' => $this->reference_type,
            'status' => $this->status ?? 'completed',
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
