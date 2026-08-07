<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('notifications')) {
            Schema::create('notifications', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->string('type');
                $table->morphs('notifiable');
                $table->text('data');
                $table->timestamp('read_at')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('broadcast_ads')) {
            Schema::create('broadcast_ads', function (Blueprint $table) {
                $table->id();
                $table->string('title');
                $table->text('message');
                $table->string('target_role')->default('all'); // all, customer, merchant
                $table->string('banner_image')->nullable();
                $table->string('action_url')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('broadcast_ads');
        Schema::dropIfExists('notifications');
    }
};
