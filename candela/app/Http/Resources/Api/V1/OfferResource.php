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
                ->where(function ($q) {
                    $q->whereHas('coupon', fn ($cq) => $cq->where('offer_id', $this->id));
                    $q->orWhere('coupon_id', $this->id);
                })
                ->exists();
        }

        $redemptionsTableCount = \App\Models\Redemption::where('offer_id', $this->id)
            ->orWhereHas('coupon', fn ($q) => $q->where('offer_id', $this->id))
            ->count();

        $couponUsesSum = (int) \App\Models\Coupon::where('offer_id', $this->id)->sum('uses_count');

        $claimedRedeemedCount = ClaimedCoupon::whereIn('status', ['redeemed', 'used'])
            ->where(function ($q) {
                $q->whereHas('coupon', fn ($cq) => $cq->where('offer_id', $this->id));
                $q->orWhere('coupon_id', $this->id);
            })
            ->count();

        $couponRedeemedCount = \App\Models\Coupon::where('offer_id', $this->id)
            ->whereIn('status', ['redeemed', 'used'])
            ->count();

        $redemptionsCount = max($redemptionsTableCount, $couponUsesSum, $claimedRedeemedCount, $couponRedeemedCount);

        $claimedCountTable = ClaimedCoupon::where(function ($q) {
            $q->whereHas('coupon', fn ($cq) => $cq->where('offer_id', $this->id));
            $q->orWhere('coupon_id', $this->id);
        })->count();

        $couponCount = \App\Models\Coupon::where('offer_id', $this->id)->count();

        $claimedCount = max($claimedCountTable, $couponCount, $redemptionsCount);


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
