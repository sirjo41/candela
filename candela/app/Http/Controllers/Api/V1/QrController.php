<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\ClaimedCoupon;
use App\Models\Coupon;
use App\Models\Redemption;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QrController extends Controller
{
    /**
     * Generate a dynamic, time-sensitive encrypted HMAC-SHA256 QR code hash valid for 30–60 seconds.
     */
    public function generate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'coupon_id' => ['required', 'integer', 'exists:coupons,id'],
            'valid_seconds' => ['nullable', 'integer', 'min:30', 'max:120'],
        ]);

        $user = $request->user();
        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $couponId = $validated['coupon_id'];
        $validSeconds = $validated['valid_seconds'] ?? 45; // 30–60 second window anti-fraud
        $validSeconds = max(30, min(60, $validSeconds));

        $coupon = Coupon::query()
            ->where('is_active', true)
            ->where('expires_at', '>', now())
            ->findOrFail($couponId);

        if ($coupon->max_uses !== null && $coupon->uses_count >= $coupon->max_uses) {
            return response()->json([
                'success' => false,
                'message' => 'كوبون وصل للحد الأقصى للاستخدام.',
                'error_code' => 'MAX_USES_REACHED',
            ], 422);
        }

        $claimed = ClaimedCoupon::where('user_id', $user->id)
            ->where('coupon_id', $coupon->id)
            ->first();

        if (! $claimed || in_array($claimed->status, ['redeemed', 'used'], true) || $coupon->isRedeemed()) {
            return response()->json([
                'success' => false,
                'message' => $claimed && in_array($claimed->status, ['redeemed', 'used'], true)
                    ? 'هذا الكوبون تم استخدامه واستبداله مسبقاً.'
                    : 'هذا الكوبون غير موجود في محفظتك.',
                'error_code' => $claimed ? 'ALREADY_REDEEMED' : 'NOT_IN_WALLET',
            ], 422);
        }

        $now = now();
        $expiresAt = $now->copy()->addSeconds($validSeconds);
        $nonce = Str::random(16);
        $secretKey = config('app.key', 'CandelaSmartAntiFraudSecretKey2026');

        $payload = [
            'user_id' => $user->id,
            'coupon_id' => $coupon->id,
            'claimed_id' => $claimed->id,
            'created_at' => $now->timestamp,
            'expires_at' => $expiresAt->timestamp,
            'nonce' => $nonce,
        ];

        $payloadJson = json_encode($payload);
        $hmacSignature = hash_hmac('sha256', $payloadJson, $secretKey);

        $qrCodePayload = [
            'payload' => $payload,
            'hmac' => $hmacSignature,
            'v' => 2,
        ];

        $qrCodeHash = base64_encode(json_encode($qrCodePayload));

        return response()->json([
            'success' => true,
            'qr_code_hash' => $qrCodeHash,
            'qr_token' => $qrCodeHash,
            'coupon_id' => $coupon->id,
            'expires_at' => $expiresAt->toIso8601String(),
            'expires_timestamp' => $expiresAt->timestamp,
            'valid_seconds' => $validSeconds,
        ], 200);
    }

    /**
     * Merchant scanner endpoint to validate customer QR pass, decrement uses, award loyalty points, deduct fee, and log audit.
     */
    public function validateQr(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'qr_code_hash' => ['nullable', 'string'],
            'qr_token' => ['nullable', 'string'],
            'coupon_code' => ['nullable', 'string'],
            'branch_id' => ['nullable', 'integer', 'exists:branches,id'],
        ]);

        $staffUser = $request->user();
        if (! $staffUser) {
            return response()->json([
                'success' => false,
                'message' => 'Authentication required.',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }

        $inputRaw = trim($validated['qr_code_hash'] ?? $validated['qr_token'] ?? $validated['coupon_code'] ?? '');
        if (empty($inputRaw)) {
            return response()->json([
                'success' => false,
                'message' => 'QR code token or hash is required.',
                'error_code' => 'INVALID_INPUT',
            ], 422);
        }

        $secretKey = config('app.key', 'CandelaSmartAntiFraudSecretKey2026');
        $payload = null;
        $extractedCouponId = null;
        $extractedUserId = null;
        $expiresAtTimestamp = null;

        // 1. Try Base64 JSON HMAC format
        $decodedJson = @json_decode(@base64_decode($inputRaw), true) ?? @json_decode($inputRaw, true);
        if (is_array($decodedJson) && isset($decodedJson['payload'], $decodedJson['hmac'])) {
            $calcHmac = hash_hmac('sha256', json_encode($decodedJson['payload']), $secretKey);
            if (! hash_equals($calcHmac, $decodedJson['hmac'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'رمز QR غير صالح أو تم التلاعب به (فشل التحقق الأمني HMAC).',
                    'error_code' => 'SECURITY_HASH_MISMATCH',
                ], 422);
            }
            $payload = $decodedJson['payload'];
            $extractedCouponId = (int) ($payload['coupon_id'] ?? 0);
            $extractedUserId = (int) ($payload['user_id'] ?? 0);
            $expiresAtTimestamp = (int) ($payload['expires_at'] ?? 0);
        } elseif (is_array($decodedJson) && isset($decodedJson['coupon_id'])) {
            // Format from CustomerController::showQrPass
            $extractedCouponId = (int) $decodedJson['coupon_id'];
            $extractedUserId = (int) ($decodedJson['user_id'] ?? 0);
            $timestamp = (int) ($decodedJson['timestamp'] ?? 0);
            $expiresAtTimestamp = $timestamp + 60; // 60-second window
            $payload = [
                'coupon_id' => $extractedCouponId,
                'user_id' => $extractedUserId,
                'expires_at' => $expiresAtTimestamp,
            ];
        } elseif (str_contains($inputRaw, ':')) {
            // Format: CANDELA:{userId}:{couponCode}:{timestamp}
            $parts = explode(':', $inputRaw);
            if (count($parts) >= 3) {
                $extractedUserId = is_numeric($parts[1]) ? (int) $parts[1] : null;
                $codeOrId = $parts[2];
                $extractedCouponId = is_numeric($codeOrId) ? (int) $codeOrId : null;
                $timestamp = isset($parts[3]) && is_numeric($parts[3]) ? (int) $parts[3] : now()->timestamp;
                $expiresAtTimestamp = $timestamp + 120;
                $payload = [
                    'coupon_id' => $extractedCouponId,
                    'coupon_code' => $codeOrId,
                    'user_id' => $extractedUserId,
                    'expires_at' => $expiresAtTimestamp,
                ];
            }
        } else {
            // Try Laravel Crypt decrypt
            try {
                $decrypted = Crypt::decrypt($inputRaw);
                $cryptPayload = json_decode($decrypted, true);
                if (is_array($cryptPayload) && isset($cryptPayload['coupon_id'])) {
                    $payload = $cryptPayload;
                    $extractedCouponId = (int) $cryptPayload['coupon_id'];
                    $extractedUserId = (int) ($cryptPayload['user_id'] ?? 0);
                    $expiresAtTimestamp = (int) ($cryptPayload['expires_at'] ?? 0);
                }
            } catch (\Throwable $e) {
                // Not encrypted string
            }
        }

        // 2. Validate Expiration (Prevent screenshot fraud)
        if ($expiresAtTimestamp !== null && now()->timestamp > $expiresAtTimestamp) {
            return response()->json([
                'success' => false,
                'message' => 'انتهت صلاحية رمز QR. يرجى الطلب من العميل تحديث الرمز.',
                'error_code' => 'EXPIRED_QR_TOKEN',
            ], 422);
        }

        // 3. Prevent double-spend on Redemption records
        $hashedToken = hash('sha256', $inputRaw);
        $existingRedemption = Redemption::where('qr_code_hash', $hashedToken)
            ->orWhere('qr_code_hash', $inputRaw)
            ->orWhere('qr_token', $inputRaw)
            ->first();

        if ($existingRedemption) {
            return response()->json([
                'success' => false,
                'message' => 'تم استرداد هذا الكوبون مسبقاً بنفس الرمز.',
                'error_code' => 'ALREADY_REDEEMED',
                'redeemed_at' => $existingRedemption->redeemed_at?->toIso8601String(),
            ], 400);
        }

        // 4. Locate Coupon
        $coupon = Coupon::with(['store.wallet', 'offer', 'user'])
            ->where(function ($q) use ($extractedCouponId, $inputRaw, $payload) {
                if ($extractedCouponId) {
                    $q->where('id', $extractedCouponId);
                }
                $q->orWhere('code', $inputRaw);
                if (isset($payload['coupon_code'])) {
                    $q->orWhere('code', $payload['coupon_code']);
                }
                $q->orWhere('qr_token', $inputRaw);
            })
            ->first();

        if (! $coupon) {
            return response()->json([
                'success' => false,
                'message' => 'الكوبون غير موجود أو الرمز غير صحيح.',
                'error_code' => 'COUPON_NOT_FOUND',
            ], 404);
        }

        if ($coupon->isRedeemed()) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الكوبون تم استخدامه مسبقاً.',
                'error_code' => 'ALREADY_REDEEMED',
                'redeemed_at' => $coupon->redeemed_at?->toIso8601String(),
            ], 400);
        }

        if ($coupon->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الكوبون منتهي الصلاحية.',
                'error_code' => 'EXPIRED_COUPON',
                'expires_at' => $coupon->expires_at?->toIso8601String(),
            ], 422);
        }

        // Store and Branch resolution
        $store = $coupon->store ?? Store::find($staffUser->store_id);
        $branchId = $validated['branch_id'] ?? null;
        if (! $branchId) {
            $branch = $store ? Branch::where('store_id', $store->id)->first() : null;
            $branchId = $branch?->id;
        } else {
            $branch = Branch::where('id', $branchId)->first();
        }

        if (! $store || ! $branchId) {
            return response()->json([
                'success' => false,
                'message' => 'تعذر تحديد المتجر أو الفرع لهذه العملية.',
                'error_code' => 'STORE_NOT_FOUND',
            ], 422);
        }

        $targetUserId = $extractedUserId ?: $coupon->user_id;
        if (! $targetUserId || ! User::where('id', $targetUserId)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'تعذر تحديد العميل صاحب الكوبون.',
                'error_code' => 'CUSTOMER_NOT_FOUND',
            ], 422);
        }

        // Determine charged fee
        $chargedFee = (float) ($coupon->redemption_fee > 0
            ? $coupon->redemption_fee
            : ($store->redemption_fee_rate ?? 5.00));

        // 5. Atomic DB Transaction
        try {
            $result = DB::transaction(function () use ($coupon, $store, $staffUser, $targetUserId, $branchId, $chargedFee, $inputRaw, $hashedToken) {
                // Lock coupon for update
                $lockedCoupon = Coupon::where('id', $coupon->id)->lockForUpdate()->first();

                if ($lockedCoupon->max_uses !== null && $lockedCoupon->uses_count >= $lockedCoupon->max_uses) {
                    throw new \RuntimeException('الكوبون وصل للحد الأقصى لعدد الاستخدامات.');
                }

                // Decrement available coupon uses (record usage)
                $lockedCoupon->increment('uses_count');
                $lockedCoupon->status = 'redeemed';
                $lockedCoupon->redeemed_at = now();
                $lockedCoupon->save();

                // Mark customer's ClaimedCoupon record as redeemed
                ClaimedCoupon::where('user_id', $targetUserId)
                    ->where(function ($q) use ($lockedCoupon) {
                        $q->where('coupon_id', $lockedCoupon->id);
                        if ($lockedCoupon->offer_id) {
                            $q->orWhereHas('coupon', fn ($cq) => $cq->where('offer_id', $lockedCoupon->offer_id));
                        }
                    })
                    ->update([
                        'status' => 'redeemed',
                        'redeemed_at' => now(),
                    ]);

                // Award loyalty points to customer profile
                $pointsAwarded = 50;
                $customer = User::where('id', $targetUserId)->lockForUpdate()->first();
                if ($customer) {
                    $customer->increment('loyalty_points', $pointsAwarded);
                }

                // Deduct redemption fee from merchant wallet if balance exists
                try {
                    $wallet = $store->getOrCreateWallet();
                    $wallet->deduct(
                        $chargedFee,
                        'redemption_fee',
                        $lockedCoupon->id,
                        Coupon::class,
                        "Redemption fee for coupon '{$lockedCoupon->code}'"
                    );
                    $store->balance = $wallet->balance;
                    $store->save();
                } catch (\Throwable $we) {
                    // Fallback to store balance column
                    if ($store->balance >= $chargedFee) {
                        $store->decrement('balance', $chargedFee);
                    }
                }

                // Create permanent, non-deletable Redemption audit record
                $redemption = Redemption::create([
                    'coupon_id' => $lockedCoupon->id,
                    'offer_id' => $lockedCoupon->offer_id,
                    'store_id' => $store->id,
                    'user_id' => $customer?->id ?? $targetUserId,
                    'staff_user_id' => $staffUser->id,
                    'branch_id' => $branchId,
                    'qr_code_hash' => $hashedToken,
                    'qr_token' => $inputRaw,
                    'points_awarded' => $pointsAwarded,
                    'charged_fee' => $chargedFee,
                    'status' => 'completed',
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
                'success' => true,
                'message' => 'تم استرداد الكوبون بنجاح!',
                'redemption' => [
                    'id' => $result['redemption']->id,
                    'points_awarded' => $result['points_awarded'],
                    'charged_fee' => $result['charged_fee'],
                    'branch_id' => $branchId,
                    'redeemed_at' => $result['redemption']->redeemed_at->toIso8601String(),
                ],
                'data' => [
                    'id' => $result['redemption']->id,
                    'customer_name' => $result['customer']?->name ?? 'عميل كانديلا',
                    'customer_phone' => $result['customer']?->phone,
                    'points_awarded' => $result['points_awarded'],
                    'charged_fee' => $result['charged_fee'],
                    'redeemed_at' => $result['redemption']->redeemed_at->toIso8601String(),
                ],
                'discount' => [
                    'coupon_id' => $result['coupon']->id,
                    'title' => $result['coupon']->title,
                    'code' => $result['coupon']->code,
                    'discount_type' => $result['coupon']->discount_type,
                    'discount_value' => (float) $result['coupon']->discount_value,
                    'store_name' => $store->name,
                ],
                'customer' => [
                    'id' => $result['customer']?->id,
                    'name' => $result['customer']?->name,
                    'new_loyalty_points' => $result['customer']?->loyalty_points,
                ],
            ], 200);

        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'error_code' => 'REDEMPTION_FAILED',
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'حدث خطأ أثناء معالجة الاسترداد: ' . $e->getMessage(),
                'error_code' => 'SERVER_ERROR',
            ], 500);
        }
    }
}
