<?php

namespace App\Policies;

use App\Models\Store;
use App\Models\User;

class StorePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isStoreOwner();
    }

    public function view(User $user, Store $store): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $store->id === $user->store_id);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    public function update(User $user, Store $store): bool
    {
        return $user->isAdmin() || ($user->isStoreOwner() && $store->id === $user->store_id);
    }

    public function delete(User $user, Store $store): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Store $store): bool
    {
        return $user->isAdmin();
    }

    public function forceDelete(User $user, Store $store): bool
    {
        return $user->isAdmin();
    }
}
