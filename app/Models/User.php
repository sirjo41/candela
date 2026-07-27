<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\HasApiTokens;

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
#[Fillable(['name', 'email', 'phone', 'loyalty_points', 'is_active', 'role', 'is_merchant', 'store_id', 'password'])]
#[Hidden(['password', 'two_factor_secret', 'two_factor_recovery_codes', 'remember_token'])]
class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The accessors to append to the model's array form.
     *
     * @var array<int, string>
     */
    protected $appends = [
        'is_customer',
        'is_merchant',
        'is_admin',
    ];

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
            'is_merchant' => 'boolean',
            'loyalty_points' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (User $user) {
            if (! empty($user->store_id)) {
                if ($user->role === 'customer' || empty($user->role)) {
                    $user->role = 'merchant';
                }
                $user->is_merchant = true;
            } elseif ($user->role === 'merchant' || $user->role === 'store_owner') {
                $user->is_merchant = true;
            }
        });
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function claimedCoupons(): HasMany
    {
        return $this->hasMany(ClaimedCoupon::class);
    }

    public function coupons(): BelongsToMany
    {
        return $this->belongsToMany(Coupon::class, 'claimed_coupons')
            ->withPivot(['id', 'status', 'claimed_at', 'redeemed_at'])
            ->withTimestamps();
    }

    public function canAccessPanel(Panel $panel): bool
    {
        if ($panel->getId() === 'admin') {
            return $this->isAdmin();
        }

        if ($panel->getId() === 'owner') {
            return $this->isMerchant() && (bool) $this->is_active && ! empty($this->store_id);
        }

        return false;
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin' || $this->role === 'national_admin';
    }

    public function isMerchant(): bool
    {
        return $this->role === 'merchant' || $this->role === 'store_owner' || (bool) ($this->attributes['is_merchant'] ?? false) || ! empty($this->store_id);
    }

    public function isStoreOwner(): bool
    {
        return $this->isMerchant();
    }

    public function isCustomer(): bool
    {
        return ! $this->isAdmin() && ! $this->isMerchant();
    }

    public function isNationalAdmin(): bool
    {
        return $this->isAdmin();
    }

    public function getIsCustomerAttribute(): bool
    {
        return $this->isCustomer();
    }

    public function getIsMerchantAttribute(): bool
    {
        return $this->isMerchant();
    }

    public function getIsAdminAttribute(): bool
    {
        return $this->isAdmin();
    }

    public function scopeCustomers($query)
    {
        return $query->where(fn ($q) => $q->whereNull('role')->orWhereIn('role', ['customer']));
    }

    public function scopeAdmins($query)
    {
        return $query->whereIn('role', ['admin', 'national_admin']);
    }

    public function scopeMerchants($query)
    {
        return $query->whereIn('role', ['merchant', 'store_owner']);
    }

    public function scopeStoreOwners($query)
    {
        return $this->scopeMerchants($query);
    }
}