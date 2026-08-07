<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('category')->default('Restaurants'); // Restaurants, Cafes, Shopping, Hot Deals
            $table->decimal('original_price', 10, 2);
            $table->decimal('discount_rate', 5, 2); // e.g. 30.00 for 30%
            $table->decimal('final_price', 10, 2);
            $table->decimal('creation_fee', 10, 2)->default(50.00); // Creation fee deducted from merchant wallet
            $table->decimal('redemption_fee', 10, 2)->default(5.00); // Fee per redemption
            $table->string('discount_badge')->nullable(); // e.g. "-30%" or "BUY 1 GET 1"
            $table->string('banner_image')->nullable();
            $table->string('branch_location')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->dateTime('valid_until');
            $table->boolean('is_active')->default(true);
            $table->softDeletes();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('offers');
    }
};
