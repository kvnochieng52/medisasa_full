<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('doctors', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone');
            $table->string('specialty');
            $table->string('location');
            $table->text('bio')->nullable();
            $table->string('image')->nullable();
            $table->decimal('rating', 2, 1)->default(4.5);
            $table->json('available_days')->nullable(); // ['Monday', 'Tuesday', etc.]
            $table->string('start_time')->default('09:00');
            $table->string('end_time')->default('17:00');
            $table->decimal('consultation_fee', 8, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('doctors');
    }
};