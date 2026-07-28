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
        $query = User::query();
        if ($request->filled('email')) {
            $query->where('email', strtolower($request->email));
        } else {
            $query->where('phone', $request->phone);
        }

        $user = $query->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Invalid authentication credentials provided.',
                ],
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'ACCOUNT_SUSPENDED',
                    'message' => 'User account has been deactivated.',
                ],
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
        ]);
    }

    /**
     * Merchant Staff & Store Owner Login.
     */
    public function loginMerchant(MerchantLoginRequest $request): JsonResponse
    {
        $query = User::query();
        if ($request->filled('email')) {
            $query->where('email', strtolower($request->email));
        } else {
            $query->where('phone', $request->phone);
        }

        $user = $query->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Invalid merchant credentials.',
                ],
            ], 401);
        }

        if (! $user->isMerchant()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UNAUTHORIZED_MERCHANT',
                    'message' => 'User is not registered as a merchant staff or owner.',
                ],
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
        ]);
    }
}
