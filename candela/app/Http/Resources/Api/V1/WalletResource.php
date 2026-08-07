<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WalletResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'store_id' => $this->store_id,
            'balance' => (float) $this->balance,
            'balance_formatted' => number_format($this->balance, 2) . ' ' . ($this->currency ?? 'D.L'),
            'currency' => $this->currency ?? 'D.L',
            'status' => $this->status ?? 'active',
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
