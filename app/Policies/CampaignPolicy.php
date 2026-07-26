<?php

namespace App\Policies;

use App\Models\Campaign;
use App\Models\User;

class CampaignPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function view(User $user, Campaign $campaign): bool
    {
        return $user->isNationalAdmin() || $user->isMerchant();
    }

    public function create(User $user): bool
    {
        return $user->isNationalAdmin();
    }

    public function update(User $user, Campaign $campaign): bool
    {
        return $user->isNationalAdmin();
    }

    public function delete(User $user, Campaign $campaign): bool
    {
        return $user->isNationalAdmin();
    }

    public function restore(User $user, Campaign $campaign): bool
    {
        return $user->isNationalAdmin();
    }

    public function forceDelete(User $user, Campaign $campaign): bool
    {
        return $user->isNationalAdmin();
    }
}
