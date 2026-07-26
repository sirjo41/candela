<?php

namespace App\Policies;

use App\Models\Coupon;
use App\Models\User;

class CouponPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isStoreOwner();
    }

    public function view(User $user, Coupon $coupon): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $coupon->store_id === $user->store_id);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin() || $user->isStoreOwner();
    }

    public function update(User $user, Coupon $coupon): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $coupon->store_id === $user->store_id);
    }

    public function delete(User $user, Coupon $coupon): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $coupon->store_id === $user->store_id);
    }

    public function restore(User $user, Coupon $coupon): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $coupon->store_id === $user->store_id);
    }

    public function forceDelete(User $user, Coupon $coupon): bool
    {
        return $user->isAdmin();
    }
}
