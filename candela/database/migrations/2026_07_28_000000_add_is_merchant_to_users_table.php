<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'is_merchant')) {
            Schema::table('users', function (Blueprint $table) {
                $table->boolean('is_merchant')->default(false)->after('role');
            });
        }

        // Sync existing user records where store_id is set
        DB::table('users')
            ->whereNotNull('store_id')
            ->update([
                'role' => 'merchant',
                'is_merchant' => true,
            ]);

        // Sync existing users whose role is merchant or store_owner
        DB::table('users')
            ->whereIn('role', ['merchant', 'store_owner'])
            ->update([
                'is_merchant' => true,
            ]);
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'is_merchant')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('is_merchant');
            });
        }
    }
};
