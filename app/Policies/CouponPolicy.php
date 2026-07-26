<?php

namespace App\Policies;

use App\Models\Coupon;
use App\Models\User;

class CouponPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function view(User $user, Coupon $coupon): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function create(User $user): bool
    {
        return $user->isNationalAdmin();
    }

    public function update(User $user, Coupon $coupon): bool
    {
        return $user->isNationalAdmin();
    }

    public function delete(User $user, Coupon $coupon): bool
    {
        return $user->isNationalAdmin();
    }

    public function restore(User $user, Coupon $coupon): bool
    {
        return $user->isNationalAdmin();
    }

    public function forceDelete(User $user, Coupon $coupon): bool
    {
        return $user->isNationalAdmin();
    }
}
