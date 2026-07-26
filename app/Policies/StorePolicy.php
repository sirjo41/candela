<?php

namespace App\Policies;

use App\Models\Store;
use App\Models\User;

class StorePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function view(User $user, Store $store): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function create(User $user): bool
    {
        return $user->isNationalAdmin();
    }

    public function update(User $user, Store $store): bool
    {
        return $user->isNationalAdmin();
    }

    public function delete(User $user, Store $store): bool
    {
        return $user->isNationalAdmin();
    }

    public function restore(User $user, Store $store): bool
    {
        return $user->isNationalAdmin();
    }

    public function forceDelete(User $user, Store $store): bool
    {
        return $user->isNationalAdmin();
    }
}
