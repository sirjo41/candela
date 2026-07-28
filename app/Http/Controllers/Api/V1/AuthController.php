<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Requests\Api\V1\Auth\MerchantLoginRequest;
use App\Http\Requests\Api\V1\Auth\RegisterCustomerRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Register a new Customer End-User.
     */
    public function registerCustomer(RegisterCustomerRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->name,
            'email' => strtolower($request->email),
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => 'customer',
            'is_merchant' => false,
            'is_active' => true,
            'loyalty_points' => 100, // 100 bonus welcome points
        ]);

        $token = $user->createToken('customer_token', ['role:customer'])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Customer account registered successfully.',
            'data' => [
                'user' => new UserResource($user),
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    /**
     * General Authentication Login (Customers or Admins).
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $input = trim($request->login ?? $request->email ?? $request->phone ?? '');

        if (empty($input)) {
            return response()->json([
                'success' => false,
                'message' => 'Email or phone number is required.',
                'error_code' => 'VALIDATION_ERROR',
            ], 422);
        }

        $user = User::where('email', strtolower($input))
            ->orWhere('phone', $input)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email/phone or password.',
                'error_code' => 'INVALID_CREDENTIALS',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'User account has been deactivated.',
                'error_code' => 'ACCOUNT_SUSPENDED',
            ], 403);
        }

        $roleAbility = 'role:' . ($user->role ?? 'customer');
        $token = $user->createToken($request->device_name ?? 'mobile_device', [$roleAbility])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Authentication successful.',
            'data' => [
                'user' => new UserResource($user),
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 200);
    }

    /**
     * Merchant Staff & Store Owner Login.
     */
    public function loginMerchant(MerchantLoginRequest $request): JsonResponse
    {
        $input = trim($request->login ?? $request->email ?? $request->phone ?? '');

        if (empty($input)) {
            return response()->json([
                'success' => false,
                'message' => 'Email or phone number is required.',
                'error_code' => 'VALIDATION_ERROR',
            ], 422);
        }

        $user = User::where('email', strtolower($input))
            ->orWhere('phone', $input)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid merchant email/phone or password.',
                'error_code' => 'INVALID_CREDENTIALS',
            ], 401);
        }

        if (! $user->isMerchant()) {
            return response()->json([
                'success' => false,
                'message' => 'User is not registered as a merchant staff or owner.',
                'error_code' => 'UNAUTHORIZED_MERCHANT',
            ], 403);
        }

        $token = $user->createToken($request->device_name ?? 'merchant_terminal', ['role:merchant_staff', 'role:merchant'])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Merchant terminal login successful.',
            'data' => [
                'user' => new UserResource($user),
                'store' => $user->store ? [
                    'id' => $user->store->id,
                    'name' => $user->store->name,
                    'balance' => (float) ($user->store->wallet->balance ?? $user->store->balance ?? 0.00),
                    'currency' => 'D.L',
                ] : null,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 200);
    }
}
