<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RedemptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'coupon_id' => $this->coupon_id,
            'coupon_code' => $this->coupon->code ?? null,
            'offer_id' => $this->offer_id,
            'store_id' => $this->store_id,
            'store_name' => $this->store->name ?? null,
            'customer_user' => [
                'id' => $this->user_id,
                'name' => $this->user->name ?? 'Customer',
                'phone' => $this->user->phone ?? null,
            ],
            'verified_by_staff' => [
                'id' => $this->staff_user_id,
                'name' => $this->staffUser->name ?? 'Merchant Scanner',
            ],
            'qr_token' => $this->qr_token,
            'redemption_fee' => (float) $this->charged_fee,
            'redemption_fee_formatted' => number_format($this->charged_fee, 2) . ' D.L',
            'points_awarded' => (int) $this->points_awarded,
            'status' => $this->status ?? 'completed',
            'redeemed_at' => $this->redeemed_at?->toIso8601String() ?? now()->toIso8601String(),
        ];
    }
}
