<?php

namespace App\Policies;

use App\Models\Redemption;
use App\Models\User;

class RedemptionPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function view(User $user, Redemption $redemption): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Redemption $redemption): bool
    {
        return false;
    }

    public function delete(User $user, Redemption $redemption): bool
    {
        return false;
    }

    public function restore(User $user, Redemption $redemption): bool
    {
        return false;
    }

    public function forceDelete(User $user, Redemption $redemption): bool
    {
        return false;
    }
}
