<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CouponResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'offer_id' => $this->offer_id,
            'store_id' => $this->store_id,
            'store_name' => $this->store->name ?? 'Candela Store',
            'title' => $this->title,
            'code' => $this->code,
            'qr_token' => $this->qr_token ?? $this->ensureQrToken(),
            'status' => $this->status ?? ($this->isRedeemed() ? 'redeemed' : ($this->isExpired() ? 'expired' : 'active')),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'redeemed_at' => $this->redeemed_at?->toIso8601String(),
            'is_valid' => $this->isValidForRedemption(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
