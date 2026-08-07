<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  ...$roles
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Unauthenticated user context.',
                ],
            ], 401);
        }

        $userRole = strtolower($user->role ?? 'customer');

        foreach ($roles as $role) {
            $normalizedRole = strtolower($role);

            if ($normalizedRole === 'customer' || $normalizedRole === 'user') {
                if ($user->isCustomer() || in_array($userRole, ['customer', 'user'])) {
                    return $next($request);
                }
            }

            if ($normalizedRole === 'merchant_staff' || $normalizedRole === 'merchant' || $normalizedRole === 'store_owner') {
                if ($user->isMerchant() || in_array($userRole, ['merchant', 'merchant_staff', 'store_owner'])) {
                    return $next($request);
                }
            }

            if ($normalizedRole === 'admin') {
                if ($user->isAdmin() || in_array($userRole, ['admin', 'national_admin'])) {
                    return $next($request);
                }
            }

            if ($userRole === $normalizedRole) {
                return $next($request);
            }
        }

        return response()->json([
            'success' => false,
            'error' => [
                'code' => 'FORBIDDEN',
                'message' => 'User does not possess required role permission [' . implode(', ', $roles) . '].',
            ],
        ], 403);
    }
}
