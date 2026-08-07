<?php

namespace App\Http\Resources\Api\V1;

use App\Models\ClaimedCoupon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OfferResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $remainingSeconds = $this->valid_until ? max(0, now()->diffInSeconds($this->valid_until, false)) : 0;

        $user = $request->user('sanctum') ?? $request->user();
        $isClaimed = false;

        if ($user) {
            $isClaimed = ClaimedCoupon::where('user_id', $user->id)
                ->whereHas('coupon', fn ($q) => $q->where('offer_id', $this->id))
                ->exists();
        }

        $claimedCount = ClaimedCoupon::whereHas('coupon', fn ($q) => $q->where('offer_id', $this->id))->count();
        $redemptionsCount = ClaimedCoupon::where('status', 'redeemed')
            ->whereHas('coupon', fn ($q) => $q->where('offer_id', $this->id))
            ->count();

        return [
            'id' => $this->id,
            'store_id' => $this->store_id,
            'store_name' => $this->store->name ?? 'Candela Store',
            'title' => $this->title,
            'description' => $this->description,
            'category' => $this->category,
            'original_price' => (float) $this->original_price,
            'original_price_formatted' => number_format($this->original_price, 2) . ' D.L',
            'discount_rate' => (float) $this->discount_rate,
            'final_price' => (float) $this->final_price,
            'final_price_formatted' => number_format($this->final_price, 2) . ' D.L',
            'currency' => 'D.L',
            'discount_badge' => $this->discount_badge ?? ('-' . (int) $this->discount_rate . '%'),
            'creation_fee' => (float) $this->creation_fee,
            'redemption_fee' => (float) $this->redemption_fee,
            'banner_image' => $this->banner_image,
            'branch_location' => $this->branch_location ?? $this->store->address ?? 'Main Branch',
            'latitude' => $this->latitude ? (float) $this->latitude : null,
            'longitude' => $this->longitude ? (float) $this->longitude : null,
            'distance_km' => isset($this->distance_km) ? round((float) $this->distance_km, 2) : null,
            'valid_until' => $this->valid_until?->toIso8601String(),
            'remaining_seconds' => $remainingSeconds,
            'is_active' => (bool) $this->is_active,
            'status' => $this->is_active ? 'active' : 'paused',
            'claimed' => $isClaimed,
            'is_claimed' => $isClaimed,
            'claimed_count' => $claimedCount,
            'claims' => $claimedCount,
            'redemptions_count' => $redemptionsCount,
            'redemptions' => $redemptionsCount,
            'uses_count' => $redemptionsCount,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
