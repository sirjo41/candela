<?php

namespace App\Policies;

use App\Models\Branch;
use App\Models\User;

class BranchPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isMerchant();
    }

    public function view(User $user, Branch $branch): bool
    {
        return $user->isAdmin() || ($user->isMerchant() && $branch->store_id === $user->store_id);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin() || $user->isMerchant();
    }

    public function update(User $user, Branch $branch): bool
    {
        return $user->isAdmin() || ($user->isMerchant() && $branch->store_id === $user->store_id);
    }

    public function delete(User $user, Branch $branch): bool
    {
        return $user->isAdmin() || ($user->isMerchant() && $branch->store_id === $user->store_id);
    }

    public function restore(User $user, Branch $branch): bool
    {
        return $user->isAdmin() || ($user->isMerchant() && $branch->store_id === $user->store_id);
    }

    public function forceDelete(User $user, Branch $branch): bool
    {
        return $user->isAdmin();
    }
}
