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
     * Customer login via phone/email and password.
     */
    public function loginCustomer(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['nullable', 'string'],
            'email' => ['nullable', 'string', 'email'],
            'login' => ['nullable', 'string'],
            'password' => ['required', 'string'],
        ]);

        $loginInput = $validated['login'] ?? $validated['phone'] ?? $validated['email'] ?? null;

        if (! $loginInput) {
            throw ValidationException::withMessages([
                'login' => ['Please provide a phone number or email address.'],
            ]);
        }

        $user = User::query()
            ->where(function ($query) use ($loginInput) {
                $query->where('phone', $loginInput)
                    ->orWhere('email', $loginInput);
            })
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password) || ! $user->isCustomer()) {
            return response()->json([
                'message' => 'Invalid customer credentials',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'message' => 'Customer account is deactivated',
            ], 403);
        }

        $token = $user->createToken('customer-api-token', ['role:customer'])->plainTextToken;

        return response()->json([
            'message' => 'Customer login successful',
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
        ]);
    }

    /**
     * Merchant login via email/phone and password.
     */
    public function loginMerchant(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['nullable', 'string'],
            'phone' => ['nullable', 'string'],
            'login' => ['nullable', 'string'],
            'password' => ['required', 'string'],
        ]);

        $loginInput = $validated['login'] ?? $validated['email'] ?? $validated['phone'] ?? null;

        if (! $loginInput) {
            throw ValidationException::withMessages([
                'login' => ['Please provide an email address or phone number.'],
            ]);
        }

        $user = User::query()
            ->where(function ($query) use ($loginInput) {
                $query->where('email', $loginInput)
                    ->orWhere('phone', $loginInput);
            })
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password) || ! $user->isMerchant()) {
            return response()->json([
                'message' => 'Invalid merchant credentials',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'message' => 'Merchant account is deactivated',
            ], 403);
        }

        $token = $user->createToken('merchant-api-token', ['role:merchant'])->plainTextToken;

        return response()->json([
            'message' => 'Merchant login successful',
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
            ],
            'store' => $user->store ? [
                'id' => $user->store->id,
                'name' => $user->store->name,
                'is_active' => $user->store->is_active,
            ] : null,
        ]);
    }
}
