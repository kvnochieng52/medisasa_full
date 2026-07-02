<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Radiology prescription tables — mirror the lab prescription structure but
 * capture imaging-specific fields per item (modality, body part, contrast,
 * urgency, clinical indication).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('radiology_prescriptions', function (Blueprint $table) {
            $table->id();
            $table->string('prescription_number')->unique();
            $table->unsignedBigInteger('doctor_id');
            $table->unsignedBigInteger('appointment_id')->nullable();

            // Prescriber snapshot
            $table->string('prescriber_name');
            $table->string('prescriber_licence_number')->nullable();
            $table->string('prescriber_phone')->nullable();
            $table->string('prescriber_email')->nullable();
            $table->string('clinic_name')->nullable();
            $table->string('clinic_address')->nullable();

            // Patient snapshot
            $table->string('patient_name');
            $table->string('patient_email')->nullable();
            $table->string('patient_phone')->nullable();
            $table->date('patient_dob')->nullable();
            $table->unsignedSmallInteger('patient_age')->nullable();
            $table->enum('patient_sex', ['male', 'female', 'other'])->nullable();

            $table->date('issued_date');
            $table->text('clinical_information')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('doctor_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('appointment_id')->references('id')->on('appointments')->nullOnDelete();
            $table->index(['doctor_id']);
            $table->index(['patient_email']);
        });

        Schema::create('radiology_prescription_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('radiology_prescription_id');

            $table->string('study_name');                          // e.g. Chest X-Ray
            $table->string('modality')->nullable();                // X-Ray, CT, MRI, Ultrasound, Mammogram, PET, DEXA
            $table->string('body_part')->nullable();               // e.g. Chest, Abdomen, Lumbar spine
            $table->string('side')->nullable();                    // left / right / bilateral
            $table->enum('contrast', ['none', 'with', 'without', 'oral'])->default('none');
            $table->enum('urgency', ['routine', 'urgent', 'stat'])->default('routine');
            $table->text('clinical_indication')->nullable();       // "R/O pneumonia", "Post-op eval", etc.
            $table->text('notes')->nullable();

            $table->timestamps();
            $table->foreign('radiology_prescription_id', 'rad_rx_item_rx_id_fk')
                ->references('id')->on('radiology_prescriptions')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('radiology_prescription_items');
        Schema::dropIfExists('radiology_prescriptions');
    }
};
