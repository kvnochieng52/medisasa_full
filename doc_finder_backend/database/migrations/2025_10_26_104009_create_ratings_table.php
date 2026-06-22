<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Who is rating
            $table->string('rateable_type'); // 'App\Models\User' for doctors or 'App\Models\Facility'
            $table->unsignedBigInteger('rateable_id'); // ID of doctor or facility
            $table->tinyInteger('overall_rating')->unsigned(); // 1-5 stars overall

            // Detailed ratings for doctors
            $table->tinyInteger('communication_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('bedside_manner_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('waiting_time_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('knowledge_rating')->unsigned()->nullable(); // 1-5 stars

            // Detailed ratings for facilities
            $table->tinyInteger('cleanliness_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('staff_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('facilities_rating')->unsigned()->nullable(); // 1-5 stars
            $table->tinyInteger('accessibility_rating')->unsigned()->nullable(); // 1-5 stars

            $table->text('comment')->nullable(); // Optional comment
            $table->boolean('is_verified')->default(false); // If rating is from actual appointment
            $table->foreignId('appointment_id')->nullable()->constrained()->onDelete('set null'); // Link to appointment if applicable
            $table->boolean('is_anonymous')->default(false); // If user wants to stay anonymous
            $table->enum('recommendation', ['yes', 'no', 'maybe'])->nullable(); // Would recommend?

            $table->timestamps();

            // Indexes
            $table->index(['rateable_type', 'rateable_id']);
            $table->index(['user_id', 'rateable_type', 'rateable_id']);
            $table->unique(['user_id', 'appointment_id']); // One rating per appointment
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ratings');
    }
};
