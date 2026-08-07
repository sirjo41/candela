<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MerchantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'business_registration' => $this->business_registration,
            'logo' => $this->logo,
            'phone' => $this->phone,
            'address' => $this->address,
            'latitude' => $this->latitude ? (float) $this->latitude : null,
            'longitude' => $this->longitude ? (float) $this->longitude : null,
            'wallet_balance' => (float) ($this->wallet->balance ?? $this->balance ?? 0.00),
            'currency' => 'D.L',
            'creation_fee_rate' => (float) ($this->creation_fee_rate ?? 50.00),
            'redemption_fee_rate' => (float) ($this->redemption_fee_rate ?? 5.00),
            'is_active' => (bool) ($this->is_active ?? true),
        ];
    }
}
