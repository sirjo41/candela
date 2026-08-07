<?php

namespace App\Policies;

use App\Models\Redemption;
use App\Models\User;

class RedemptionPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isMerchant();
    }

    public function view(User $user, Redemption $redemption): bool
    {
        return $user->isAdmin() || ($user->isMerchant() && $redemption->branch?->store_id === $user->store_id);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    public function update(User $user, Redemption $redemption): bool
    {
        return $user->isAdmin();
    }

    public function delete(User $user, Redemption $redemption): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Redemption $redemption): bool
    {
        return $user->isAdmin();
    }

    public function forceDelete(User $user, Redemption $redemption): bool
    {
        return $user->isAdmin();
    }
}
