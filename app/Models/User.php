<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string|null $phone
 * @property int $loyalty_points
 * @property bool $is_active
 * @property string $role
 * @property int|null $store_id
 * @property Carbon|null $email_verified_at
 * @property string $password
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property Carbon|null $deleted_at
 */
#[Fillable(['name', 'email', 'phone', 'loyalty_points', 'is_active', 'role', 'store_id', 'password'])]
#[Hidden(['password', 'two_factor_secret', 'two_factor_recovery_codes', 'remember_token'])]
class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
            'loyalty_points' => 'integer',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function canAccessPanel(Panel $panel): bool
    {
        if ($panel->getId() === 'admin') {
            return $this->isAdmin();
        }

        if ($panel->getId() === 'owner') {
            return $this->isStoreOwner() && (bool) $this->is_active && ! empty($this->store_id);
        }

        return false;
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin' || $this->role === 'national_admin';
    }

    public function isStoreOwner(): bool
    {
        return $this->role === 'store_owner' || $this->role === 'merchant';
    }

    public function isCustomer(): bool
    {
        return empty($this->role) || $this->role === 'customer';
    }

    public function isNationalAdmin(): bool
    {
        return $this->isAdmin();
    }

    public function isMerchant(): bool
    {
        return $this->isStoreOwner();
    }

    public function scopeCustomers($query)
    {
        return $query->where(fn ($q) => $q->whereNull('role')->orWhereIn('role', ['customer']));
    }

    public function scopeAdmins($query)
    {
        return $query->whereIn('role', ['admin', 'national_admin']);
    }

    public function scopeStoreOwners($query)
    {
        return $query->whereIn('role', ['store_owner', 'merchant']);
    }
}