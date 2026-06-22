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
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('doctor_id');
            $table->string('patient_name');
            $table->string('patient_email');
            $table->string('patient_telephone');
            $table->string('patient_location')->nullable();
            $table->date('appointment_date');
            $table->time('appointment_time');
            $table->enum('consultation_type', ['in_person', 'online'])->default('in_person');
            $table->enum('status', ['pending', 'confirmed', 'cancelled', 'completed'])->default('pending');
            $table->text('notes')->nullable();
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('doctor_id')->references('id')->on('users')->onDelete('cascade');

            // Indexes
            $table->index(['doctor_id']);
            $table->index(['appointment_date']);
            $table->index(['status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};