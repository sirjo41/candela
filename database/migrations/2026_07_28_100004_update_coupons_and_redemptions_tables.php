<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('coupons', function (Blueprint $table) {
            if (!Schema::hasColumn('coupons', 'offer_id')) {
                $table->foreignId('offer_id')->nullable()->after('store_id')->constrained('offers')->nullOnDelete();
            }
            if (!Schema::hasColumn('coupons', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('offer_id')->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('coupons', 'qr_token')) {
                $table->string('qr_token')->nullable()->unique()->after('code');
            }
            if (!Schema::hasColumn('coupons', 'status')) {
                $table->string('status', 30)->default('active')->after('qr_token');
            }
            if (!Schema::hasColumn('coupons', 'redeemed_at')) {
                $table->timestamp('redeemed_at')->nullable()->after('expires_at');
            }
        });

        Schema::table('redemptions', function (Blueprint $table) {
            if (!Schema::hasColumn('redemptions', 'store_id')) {
                $table->foreignId('store_id')->nullable()->after('coupon_id')->constrained('stores')->cascadeOnDelete();
            }
            if (!Schema::hasColumn('redemptions', 'staff_user_id')) {
                $table->foreignId('staff_user_id')->nullable()->after('user_id')->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('redemptions', 'qr_token')) {
                $table->string('qr_token')->nullable()->after('qr_code_hash');
            }
            if (!Schema::hasColumn('redemptions', 'status')) {
                $table->string('status', 30)->default('completed')->after('charged_fee');
            }
        });
    }

    public function down(): void
    {
        Schema::table('coupons', function (Blueprint $table) {
            $table->dropColumn(['offer_id', 'user_id', 'qr_token', 'status', 'redeemed_at']);
        });

        Schema::table('redemptions', function (Blueprint $table) {
            $table->dropColumn(['store_id', 'staff_user_id', 'qr_token', 'status']);
        });
    }
};
