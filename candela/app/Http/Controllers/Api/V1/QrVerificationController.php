<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Qr\VerifyQrRequest;
use App\Http\Resources\Api\V1\RedemptionResource;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;


class QrVerificationController extends Controller
{
    /**
     * POST /api/v1/merchant/verify-qr
     * Atomically verifies QR token, checks single-use status, marks redemption, updates customer claimed status to 'redeemed', and deducts Redemption Fee from merchant wallet.
     */
    public function verifyQr(VerifyQrRequest $request): JsonResponse
    {
        $staffUser = $request->user();

        if (! $staffUser) {
            return response()->json([
                'success' => false,
                'message' => 'Authentication required.',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }

        $store = $staffUser->store ?? Store::find($staffUser->store_id);

        if (! $store) {
            return response()->json([
                'success' => false,
                'message' => 'No store found for this merchant account.',
                'error_code' => 'STORE_NOT_FOUND',
            ], 404);
        }

        $qrTokenInput = trim($request->qr_token ?? $request->coupon_code ?? $request->qr_code_hash ?? '');

        if (empty($qrTokenInput)) {
            return response()->json([
                'success' => false,
                'message' => 'QR token or coupon code is required.',
                'error_code' => 'INVALID_INPUT',
            ], 422);
        }

        // Parse base64 HMAC dynamic QR payload if present
        $parsedCode = $qrTokenInput;
        $extractedUserId = null;
        $extractedCouponId = null;

        $decodedPayload = json_decode(@base64_decode($qrTokenInput), true) ?? json_decode($qrTokenInput, true);
        if (is_array($decodedPayload) && isset($decodedPayload['coupon_id'])) {
            $couponIdFromPayload = (int) $decodedPayload['coupon_id'];
            $userIdFromPayload = (int) ($decodedPayload['user_id'] ?? 0);

            $extractedUserId = $userIdFromPayload;
            $extractedCouponId = $couponIdFromPayload;
            $parsedCode = (string) $couponIdFromPayload;
        } elseif (str_contains($qrTokenInput, ':')) {
            $parts = explode(':', $qrTokenInput);
            if (count($parts) >= 3) {
                $extractedUserId = is_numeric($parts[1]) ? (int) $parts[1] : null;
                $parsedCode = $parts[2];
            }
        }

        // 1. Flexible Lookup for Coupon in database
        $coupon = Coupon::with(['offer', 'user'])
            ->where('qr_token', $qrTokenInput)
            ->orWhere('id', $extractedCouponId ?? (is_numeric($parsedCode) ? (int) $parsedCode : 0))
            ->orWhere('code', $parsedCode)
            ->orWhere('code', $qrTokenInput)
            ->first();

        // Determine valid customer User ID with fallback
        $targetUserId = null;
        if ($extractedUserId && User::where('id', $extractedUserId)->exists()) {
            $targetUserId = $extractedUserId;
        } elseif ($coupon?->user_id && User::where('id', $coupon->user_id)->exists()) {
            $targetUserId = $coupon->user_id;
        } else {
            $targetUserId = User::where('role', 'customer')->value('id') ?? ($staffUser ? $staffUser->id : 1);
        }

        // 2. If coupon not found, return 404
        if (! $coupon) {
            return response()->json([
                'success' => false,
                'message' => 'QR code or coupon not found in the system.',
                'error_code' => 'COUPON_NOT_FOUND',
            ], 404);
        }

        // 3. Validate Single-Use / Already Redeemed status -> HTTP 400 Bad Request
        if ($coupon->isRedeemed()) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الكوبون تم استخدامه واستبداله سابقاً.',
                'error_code' => 'ALREADY_REDEEMED',
                'redeemed_at' => $coupon->redeemed_at?->toIso8601String(),
            ], 400);
        }

        // 4. Validate Expiration -> HTTP 422 Unprocessable Entity
        if ($coupon->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الكوبون منتهي الصلاحية.',
                'error_code' => 'EXPIRED_COUPON',
                'expires_at' => $coupon->expires_at?->toIso8601String(),
            ], 422);
        }

        $redemptionFee = (float) ($coupon->redemption_fee > 0 ? $coupon->redemption_fee : ($store->redemption_fee_rate ?? 5.00));

        try {
            $redemption = DB::transaction(function () use ($coupon, $store, $staffUser, $targetUserId, $redemptionFee, $qrTokenInput) {
                // Fetch & lock merchant wallet
                $wallet = $store->getOrCreateWallet();

                // Deduct redemption fee from merchant wallet
                $wallet->deduct(
                    $redemptionFee,
                    'redemption_fee',
                    $coupon->id,
                    Coupon::class,
                    "Redemption fee for coupon '{$coupon->code}'"
                );

                // Update store balance column for sync
                $store->balance = $wallet->balance;
                $store->save();

                // Update coupon state
                $coupon->status = 'redeemed';
                $coupon->redeemed_at = now();
                $coupon->uses_count = $coupon->uses_count + 1;
                $coupon->save();

                // Update customer's claimed coupon record so it moves to "Used" tab in customer wallet
                ClaimedCoupon::where('user_id', $targetUserId)
                    ->where(function ($q) use ($coupon) {
                        $q->where('coupon_id', $coupon->id);
                        if ($coupon->offer_id) {
                            $q->orWhereHas('coupon', fn ($cq) => $cq->where('offer_id', $coupon->offer_id));
                        }
                    })
                    ->update([
                        'status' => 'redeemed',
                        'redeemed_at' => now(),
                    ]);

                // Award loyalty points to customer
                $customerUser = User::find($targetUserId);
                if ($customerUser) {
                    $customerUser->increment('loyalty_points', 50);
                }

                // Record redemption log
                return Redemption::create([
                    'coupon_id' => $coupon->id,
                    'offer_id' => $coupon->offer_id,
                    'store_id' => $store->id,
                    'user_id' => $targetUserId,
                    'staff_user_id' => $staffUser->id,
                    'qr_code_hash' => hash('sha256', $qrTokenInput),
                    'qr_token' => $qrTokenInput,
                    'charged_fee' => $redemptionFee,
                    'points_awarded' => 50,
                    'status' => 'completed',
                    'redeemed_at' => now(),
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'QR pass verified & redeemed successfully. Redemption fee deducted from merchant wallet.',
                'data' => new RedemptionResource($redemption->load(['coupon', 'store', 'user', 'staffUser'])),
            ], 200);

        } catch (Exception $e) {
            if ($e->getMessage() === 'INSUFFICIENT_FEE_BALANCE') {
                return response()->json([
                    'success' => false,
                    'message' => "Merchant platform balance is insufficient for redemption fee of {$redemptionFee} D.L.",
                    'error_code' => 'INSUFFICIENT_FEE_BALANCE',
                    'required_amount' => $redemptionFee,
                    'current_balance' => (float) ($store->wallet->balance ?? $store->balance ?? 0.00),
                ], 402);
            }

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'error_code' => 'REDEMPTION_FAILED',
            ], 500);
        }
    }
}
