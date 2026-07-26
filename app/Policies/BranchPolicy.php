<?php

namespace App\Policies;

use App\Models\Branch;
use App\Models\User;

class BranchPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function view(User $user, Branch $branch): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function create(User $user): bool
    {
        return $user->isNationalAdmin();
    }

    public function update(User $user, Branch $branch): bool
    {
        return $user->isNationalAdmin();
    }

    public function delete(User $user, Branch $branch): bool
    {
        return $user->isNationalAdmin();
    }

    public function restore(User $user, Branch $branch): bool
    {
        return $user->isNationalAdmin();
    }

    public function forceDelete(User $user, Branch $branch): bool
    {
        return $user->isNationalAdmin();
    }
}
