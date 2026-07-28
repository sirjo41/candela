<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Qr\VerifyQrRequest;
use App\Http\Resources\Api\V1\RedemptionResource;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class QrVerificationController extends Controller
{
    /**
     * POST /api/v1/merchant/verify-qr
     * Atomically verifies QR token, checks single-use status, marks redemption, and deducts Redemption Fee from merchant wallet.
     */
    public function verifyQr(VerifyQrRequest $request): JsonResponse
    {
        $staffUser = $request->user();
        $store = $staffUser->store ?? Store::find($staffUser->store_id) ?? Store::first();

        if (! $store) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'STORE_NOT_FOUND',
                    'message' => 'Merchant store context not found for logged in staff user.',
                ],
            ], 404);
        }

        $qrTokenInput = $request->qr_token ?? $request->coupon_code ?? $request->qr_code_hash;

        // Parse token if format is "CANDELA:{userId}:{couponCode}:{timestamp}"
        $parsedCode = $qrTokenInput;
        if (str_contains($qrTokenInput, ':')) {
            $parts = explode(':', $qrTokenInput);
            if (count($parts) >= 3) {
                $parsedCode = $parts[2];
            }
        }

        // 1. Locate Coupon
        $coupon = Coupon::with(['offer', 'user'])
            ->where('qr_token', $qrTokenInput)
            ->orWhere('code', $parsedCode)
            ->first();

        if (! $coupon) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'INVALID_TOKEN',
                    'message' => 'Invalid or unrecognized QR coupon token.',
                ],
            ], 404);
        }

        // 2. Validate Single-Use / Already Redeemed status
        if ($coupon->isRedeemed()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'ALREADY_REDEEMED',
                    'message' => 'This single-use coupon pass has already been redeemed.',
                    'redeemed_at' => $coupon->redeemed_at?->toIso8601String(),
                ],
            ], 422);
        }

        // 3. Validate Expiration
        if ($coupon->isExpired()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'EXPIRED_COUPON',
                    'message' => 'This coupon pass has expired and is no longer valid.',
                    'expires_at' => $coupon->expires_at?->toIso8601String(),
                ],
            ], 422);
        }

        $redemptionFee = (float) ($coupon->redemption_fee > 0 ? $coupon->redemption_fee : ($store->redemption_fee_rate ?? 5.00));

        try {
            $redemption = DB::transaction(function () use ($coupon, $store, $staffUser, $redemptionFee, $qrTokenInput) {
                // Fetch & lock merchant wallet
                $wallet = $store->getOrCreateWallet();

                // Check wallet balance for redemption fee
                if ((float) $wallet->balance < $redemptionFee) {
                    throw new Exception('INSUFFICIENT_MERCHANT_BALANCE');
                }

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

                // Award loyalty points to customer
                if ($coupon->user) {
                    $coupon->user->increment('loyalty_points', 50);
                }

                // Record redemption log
                return Redemption::create([
                    'coupon_id' => $coupon->id,
                    'offer_id' => $coupon->offer_id,
                    'store_id' => $store->id,
                    'user_id' => $coupon->user_id ?? 1,
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
            ]);

        } catch (Exception $e) {
            if ($e->getMessage() === 'INSUFFICIENT_MERCHANT_BALANCE') {
                return response()->json([
                    'success' => false,
                    'error' => [
                        'code' => 'INSUFFICIENT_MERCHANT_BALANCE',
                        'message' => "Merchant wallet balance is insufficient for redemption fee of {$redemptionFee} D.L.",
                        'required_amount' => $redemptionFee,
                        'current_balance' => (float) ($store->wallet->balance ?? $store->balance ?? 0.00),
                    ],
                ], 422);
            }

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'REDEMPTION_FAILED',
                    'message' => $e->getMessage(),
                ],
            ], 500);
        }
    }
}
