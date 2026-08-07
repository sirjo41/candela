<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offers', function (Blueprint $table) {
            $table->decimal('original_price', 10, 2)->nullable()->change();
            $table->decimal('discount_rate', 5, 2)->nullable()->change();
            $table->decimal('final_price', 10, 2)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('offers', function (Blueprint $table) {
            $table->decimal('original_price', 10, 2)->nullable(false)->change();
            $table->decimal('discount_rate', 5, 2)->nullable(false)->change();
            $table->decimal('final_price', 10, 2)->nullable(false)->change();
        });
    }
};
