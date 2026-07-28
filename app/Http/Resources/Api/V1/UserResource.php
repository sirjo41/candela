<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role ?? 'customer',
            'is_customer' => $this->isCustomer(),
            'is_merchant' => $this->isMerchant(),
            'is_admin' => $this->isAdmin(),
            'store_id' => $this->store_id,
            'loyalty_points' => $this->loyalty_points ?? 0,
            'is_active' => (bool) ($this->is_active ?? true),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
