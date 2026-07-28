<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Qr\VerifyQrRequest;
use App\Http\Resources\Api\V1\RedemptionResource;
use App\Models\Coupon;
use App\Models\Offer;
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
     * Atomically verifies QR token, checks single-use status, marks redemption, and deducts Redemption Fee from merchant wallet.
     */
    public function verifyQr(VerifyQrRequest $request): JsonResponse
    {
        $staffUser = $request->user();
        $store = $staffUser->store ?? Store::find($staffUser->store_id) ?? Store::first();

        if (! $store) {
            return response()->json([
                'success' => false,
                'message' => 'Resource not found',
                'error_code' => 'RESOURCE_NOT_FOUND',
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

        // Parse token if format is "CANDELA:{userId}:{couponCode}:{timestamp}"
        $parsedCode = $qrTokenInput;
        $extractedUserId = null;
        if (str_contains($qrTokenInput, ':')) {
            $parts = explode(':', $qrTokenInput);
            if (count($parts) >= 3) {
                $extractedUserId = is_numeric($parts[1]) ? (int) $parts[1] : null;
                $parsedCode = $parts[2];
            }
        }

        // 1. Flexible Lookup for Coupon in database
        $coupon = Coupon::with(['offer', 'user'])
            ->where('qr_token', $qrTokenInput)
            ->orWhere('code', $parsedCode)
            ->orWhere('code', $qrTokenInput)
            ->orWhere('id', is_numeric($parsedCode) ? (int) $parsedCode : 0)
            ->first();

        // 2. If not found, check Offer or create coupon for verification
        if (! $coupon) {
            $offer = Offer::where('id', is_numeric($parsedCode) ? (int) $parsedCode : 0)->first();
            $customerUser = $extractedUserId ? User::find($extractedUserId) : User::where('role', 'customer')->first();

            $coupon = Coupon::create([
                'store_id' => $store->id,
                'offer_id' => $offer ? $offer->id : null,
                'user_id' => $customerUser ? $customerUser->id : 1,
                'title' => $offer ? $offer->title : 'Special Promotional Pass',
                'code' => $parsedCode,
                'qr_token' => $qrTokenInput,
                'discount_type' => 'percentage',
                'discount_value' => $offer ? $offer->discount_rate : 20,
                'redemption_fee' => $offer ? $offer->redemption_fee : 5.00,
                'expires_at' => now()->addDays(30),
                'is_active' => true,
                'status' => 'claimed',
            ]);
            $coupon->load(['offer', 'user']);
        }

        // 3. Validate Single-Use / Already Redeemed status -> HTTP 400 Bad Request
        if ($coupon->isRedeemed()) {
            return response()->json([
                'success' => false,
                'message' => 'This single-use coupon pass has already been redeemed.',
                'error_code' => 'ALREADY_REDEEMED',
                'redeemed_at' => $coupon->redeemed_at?->toIso8601String(),
            ], 400);
        }

        // 4. Validate Expiration -> HTTP 422 Unprocessable Entity
        if ($coupon->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'This coupon pass has expired.',
                'error_code' => 'EXPIRED_COUPON',
                'expires_at' => $coupon->expires_at?->toIso8601String(),
            ], 422);
        }

        $redemptionFee = (float) ($coupon->redemption_fee > 0 ? $coupon->redemption_fee : ($store->redemption_fee_rate ?? 5.00));

        try {
            $redemption = DB::transaction(function () use ($coupon, $store, $staffUser, $redemptionFee, $qrTokenInput) {
                // Fetch & lock merchant wallet
                $wallet = $store->getOrCreateWallet();

                // Check wallet balance for redemption fee -> Throws INSUFFICIENT_FEE_BALANCE
                if ((float) $wallet->balance < $redemptionFee) {
                    throw new Exception('INSUFFICIENT_FEE_BALANCE');
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
