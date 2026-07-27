<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new customer.
     */
    public function registerCustomer(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'string', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:50', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'] ?? $validated['phone'].'@candela.local',
            'phone' => $validated['phone'],
            'password' => Hash::make($validated['password']),
            'role' => 'customer',
            'is_active' => true,
            'loyalty_points' => 0,
        ]);

        $token = $user->createToken('customer-api-token', ['role:customer'])->plainTextToken;

        return response()->json([
            'message' => 'Customer registered successfully',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'is_customer' => $user->is_customer,
                'is_merchant' => $user->is_merchant,
                'is_admin' => $user->is_admin,
                'loyalty_points' => $user->loyalty_points,
            ],
        ], 201);
    }

    /**
     * Unified login method for both customer and merchant accounts.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => ['nullable', 'string'],
            'phone' => ['nullable', 'string'],
            'email' => ['nullable', 'string'],
            'password' => ['required', 'string'],
        ]);

        $loginInput = $validated['login'] ?? $validated['phone'] ?? $validated['email'] ?? null;

        if (! $loginInput) {
            throw ValidationException::withMessages([
                'login' => ['Please provide a phone number or email address.'],
            ]);
        }

        $user = User::query()
            ->with('store')
            ->where(function ($query) use ($loginInput) {
                $query->where('phone', $loginInput)
                    ->orWhere('email', $loginInput);
            })
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Invalid credentials',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'message' => 'User account is deactivated',
            ], 403);
        }

        // Assign token abilities dynamically based on role/flags
        $abilities = [];
        if ($user->is_merchant) {
            $abilities[] = 'role:merchant';
        }
        if ($user->is_customer) {
            $abilities[] = 'role:customer';
        }
        if ($user->is_admin) {
            $abilities[] = 'role:admin';
        }

        $token = $user->createToken('auth-api-token', $abilities)->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'is_customer' => $user->is_customer,
                'is_merchant' => $user->is_merchant,
                'is_admin' => $user->is_admin,
                'store_id' => $user->store_id,
                'store_name' => $user->store?->name,
                'loyalty_points' => $user->loyalty_points,
            ],
            'store' => $user->store ? [
                'id' => $user->store->id,
                'name' => $user->store->name,
                'is_active' => $user->store->is_active,
            ] : null,
        ]);
    }

    /**
     * Customer login alias.
     */
    public function loginCustomer(Request $request): JsonResponse
    {
        return $this->login($request);
    }

    /**
     * Merchant login alias.
     */
    public function loginMerchant(Request $request): JsonResponse
    {
        return $this->login($request);
    }
}
