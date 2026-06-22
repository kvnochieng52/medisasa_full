<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_packages', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();         // monthly, quarterly, annually
            $table->string('name');                   // Monthly, Quarterly, Annual
            $table->decimal('amount', 10, 2);         // price in KES
            $table->string('currency', 3)->default('KES');
            $table->integer('duration_days');         // 30, 90, 365
            $table->text('description')->nullable();
            $table->json('features')->nullable();     // list of feature strings
            $table->boolean('is_popular')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_packages');
    }
};
