<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QrController extends Controller
{
    /**
     * Generate an encrypted, time-sensitive QR code payload for a claimed coupon.
     */
    public function generate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'coupon_id' => ['required', 'integer', 'exists:coupons,id'],
            'valid_seconds' => ['nullable', 'integer', 'min:30', 'max:600'],
        ]);

        $user = $request->user();
        $couponId = $validated['coupon_id'];
        $validSeconds = $validated['valid_seconds'] ?? 120;

        $coupon = Coupon::query()
            ->where('is_active', true)
            ->where('expires_at', '>', now())
            ->findOrFail($couponId);

        if ($coupon->max_uses !== null && $coupon->uses_count >= $coupon->max_uses) {
            return response()->json([
                'message' => 'Coupon maximum usage limit has been reached.',
            ], 422);
        }

        // Get or create claim record
        $claimed = ClaimedCoupon::firstOrCreate(
            [
                'user_id' => $user->id,
                'coupon_id' => $coupon->id,
            ],
            [
                'status' => 'claimed',
                'claimed_at' => now(),
            ]
        );

        if ($claimed->status === 'redeemed') {
            return response()->json([
                'message' => 'This coupon has already been redeemed.',
            ], 422);
        }

        $now = now();
        $expiresAt = $now->copy()->addSeconds($validSeconds);

        $payload = [
            'user_id' => $user->id,
            'coupon_id' => $coupon->id,
            'claimed_id' => $claimed->id,
            'created_at' => $now->timestamp,
            'expires_at' => $expiresAt->timestamp,
            'nonce' => Str::random(16),
        ];

        $qrCodeHash = Crypt::encrypt(json_encode($payload));

        return response()->json([
            'qr_code_hash' => $qrCodeHash,
            'expires_at' => $expiresAt->toIso8601String(),
            'valid_seconds' => $validSeconds,
        ]);
    }

    /**
     * Merchant scanner endpoint to process and redeem a customer's QR code payload.
     */
    public function validateQr(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'qr_code_hash' => ['required', 'string'],
            'branch_id' => ['nullable', 'integer', 'exists:branches,id'],
        ]);

        $merchant = $request->user();
        $qrCodeHash = $validated['qr_code_hash'];

        // 1. Decrypt payload
        try {
            $decrypted = Crypt::decrypt($qrCodeHash);
            $payload = json_decode($decrypted, true);
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'Invalid or tampered QR code payload.',
            ], 422);
        }

        if (! is_array($payload) || ! isset($payload['user_id'], $payload['coupon_id'], $payload['claimed_id'], $payload['expires_at'])) {
            return response()->json([
                'message' => 'Malformed QR code payload structure.',
            ], 422);
        }

        // 2. Validate timestamp expiration
        if (now()->timestamp > $payload['expires_at']) {
            return response()->json([
                'message' => 'QR code has expired. Please ask customer to refresh QR code.',
            ], 422);
        }

        // 3. Double-spend prevention check on redemption table
        $existingRedemption = Redemption::where('qr_code_hash', $qrCodeHash)->first();
        if ($existingRedemption) {
            return response()->json([
                'message' => 'This QR code payload has already been processed.',
            ], 422);
        }

        // Find models
        $coupon = Coupon::with('store')->find($payload['coupon_id']);
        if (! $coupon || ! $coupon->is_active || $coupon->expires_at <= now()) {
            return response()->json([
                'message' => 'Coupon is inactive or expired.',
            ], 422);
        }

        // Check merchant store authorization
        if ($merchant->isMerchant() && $merchant->store_id && $merchant->store_id !== $coupon->store_id) {
            return response()->json([
                'message' => 'Unauthorized: Merchant does not belong to this coupon\'s store.',
            ], 403);
        }

        // Resolve branch
        $branchId = $validated['branch_id'] ?? null;
        if (! $branchId) {
            $branch = Branch::where('store_id', $coupon->store_id)->first();
            $branchId = $branch?->id;
        } else {
            $branch = Branch::where('id', $branchId)->where('store_id', $coupon->store_id)->first();
            if (! $branch) {
                return response()->json([
                    'message' => 'Selected branch does not belong to this coupon\'s store.',
                ], 422);
            }
        }

        if (! $branchId) {
            return response()->json([
                'message' => 'No valid branch found for coupon redemption.',
            ], 422);
        }

        // 4. Atomic Database Transaction
        try {
            $result = DB::transaction(function () use ($payload, $coupon, $branchId, $qrCodeHash) {
                // Lock coupon for update
                $lockedCoupon = Coupon::where('id', $coupon->id)->lockForUpdate()->first();

                if ($lockedCoupon->max_uses !== null && $lockedCoupon->uses_count >= $lockedCoupon->max_uses) {
                    throw new \RuntimeException('Coupon maximum redemption limit reached.');
                }

                // Lock claimed coupon record
                $claimed = ClaimedCoupon::where('id', $payload['claimed_id'])->lockForUpdate()->first();

                if (! $claimed || $claimed->status === 'redeemed') {
                    throw new \RuntimeException('Coupon has already been redeemed.');
                }

                // Increment uses_count on Coupon
                $lockedCoupon->increment('uses_count');

                // Mark claimed coupon as redeemed
                $claimed->update([
                    'status' => 'redeemed',
                    'redeemed_at' => now(),
                ]);

                // Determine fee
                $chargedFee = (float) ($lockedCoupon->redemption_fee > 0
                    ? $lockedCoupon->redemption_fee
                    : ($lockedCoupon->store->redemption_fee_rate ?? 0.00));

                // Award loyalty points
                $pointsAwarded = 10;
                $customer = User::where('id', $payload['user_id'])->lockForUpdate()->first();
                if ($customer) {
                    $customer->increment('loyalty_points', $pointsAwarded);
                }

                // Create redemption record
                $redemption = Redemption::create([
                    'coupon_id' => $lockedCoupon->id,
                    'user_id' => $customer?->id ?? $payload['user_id'],
                    'branch_id' => $branchId,
                    'qr_code_hash' => $qrCodeHash,
                    'points_awarded' => $pointsAwarded,
                    'charged_fee' => $chargedFee,
                    'redeemed_at' => now(),
                ]);

                return [
                    'redemption' => $redemption,
                    'coupon' => $lockedCoupon,
                    'customer' => $customer,
                    'points_awarded' => $pointsAwarded,
                    'charged_fee' => $chargedFee,
                ];
            });

            return response()->json([
                'message' => 'Coupon redeemed successfully',
                'redemption' => [
                    'id' => $result['redemption']->id,
                    'points_awarded' => $result['points_awarded'],
                    'charged_fee' => $result['charged_fee'],
                    'redeemed_at' => $result['redemption']->redeemed_at,
                ],
                'discount' => [
                    'coupon_id' => $result['coupon']->id,
                    'title' => $result['coupon']->title,
                    'code' => $result['coupon']->code,
                    'discount_type' => $result['coupon']->discount_type,
                    'discount_value' => (float) $result['coupon']->discount_value,
                    'store_name' => $coupon->store->name,
                ],
                'customer' => [
                    'id' => $result['customer']?->id,
                    'name' => $result['customer']?->name,
                    'new_loyalty_points' => $result['customer']?->loyalty_points,
                ],
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
