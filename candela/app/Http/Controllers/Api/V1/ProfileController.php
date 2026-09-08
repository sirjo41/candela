<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /**
     * Get authenticated user profile details.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'user' => (new UserResource($user))->resolve(),
            'data' => (new UserResource($user))->resolve(),
        ], 200);
    }

    /**
     * Update authenticated user personal details.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:30', Rule::unique('users', 'phone')->ignore($user->id)],
        ], [
            'name.required' => 'الاسم الكامل مطلوب.',
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'email.unique' => 'هذا البريد الإلكتروني مسجل مسبقاً.',
            'phone.unique' => 'رقم الهاتف مسجل مسبقاً لمستخدم آخر.',
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => strtolower($validated['email']),
            'phone' => $validated['phone'] ?? $user->phone,
        ]);

        $userResource = new UserResource($user->fresh());

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث البيانات الشخصية بنجاح.',
            'user' => $userResource->resolve(),
            'data' => $userResource->resolve(),
        ], 200);
    }

    /**
     * Change authenticated user password securely.
     */
    public function changePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:6', 'confirmed'],
        ], [
            'current_password.required' => 'يرجى إدخال كلمة المرور الحالية.',
            'new_password.required' => 'يرجى إدخال كلمة المرور الجديدة.',
            'new_password.min' => 'يجب أن لا تقل كلمة المرور عن 6 أحرف.',
            'new_password.confirmed' => 'تأكيد كلمة المرور الجديدة غير متطابق.',
        ]);

        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'كلمة المرور الحالية غير صحيحة.',
                'error_code' => 'INVALID_CURRENT_PASSWORD',
                'errors' => [
                    'current_password' => ['كلمة المرور الحالية غير مطابقة للسجلات.'],
                ],
            ], 422);
        }

        $user->password = $validated['new_password']; // Hashed automatically by cast
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'تم تغيير كلمة المرور بنجاح.',
        ], 200);
    }
}
