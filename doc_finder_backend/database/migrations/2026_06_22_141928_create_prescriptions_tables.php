<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('medication_prescriptions', function (Blueprint $table) {
            $table->id();
            $table->string('prescription_number')->unique();
            $table->unsignedBigInteger('doctor_id');
            $table->unsignedBigInteger('appointment_id')->nullable();

            // Snapshot of prescriber info at issue time (in case doctor profile changes later)
            $table->string('prescriber_name');
            $table->string('prescriber_licence_number')->nullable();
            $table->string('prescriber_phone')->nullable();
            $table->string('prescriber_email')->nullable();
            $table->string('clinic_name')->nullable();
            $table->string('clinic_address')->nullable();

            // Patient details (snapshot)
            $table->string('patient_name');
            $table->string('patient_email')->nullable();
            $table->string('patient_phone')->nullable();
            $table->date('patient_dob')->nullable();
            $table->unsignedSmallInteger('patient_age')->nullable();

            $table->date('issued_date');
            $table->text('diagnosis')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('doctor_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('appointment_id')->references('id')->on('appointments')->nullOnDelete();
            $table->index(['doctor_id']);
            $table->index(['patient_email']);
        });

        Schema::create('medication_prescription_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('medication_prescription_id');

            $table->string('drug_name');
            $table->string('dosage_form')->nullable();   // tablets, syrup, capsule, injection
            $table->string('strength')->nullable();       // 500mg
            $table->string('frequency')->nullable();      // BID, 3x daily, every 6 hours
            $table->string('route')->nullable();          // by mouth, IM, IV
            $table->string('duration')->nullable();       // 7 days
            $table->string('quantity')->nullable();       // 21 tablets
            $table->unsignedSmallInteger('refills')->default(0);
            $table->text('instructions')->nullable();

            $table->timestamps();
            $table->foreign('medication_prescription_id', 'med_rx_item_rx_id_fk')
                ->references('id')->on('medication_prescriptions')->onDelete('cascade');
        });

        Schema::create('lab_prescriptions', function (Blueprint $table) {
            $table->id();
            $table->string('prescription_number')->unique();
            $table->unsignedBigInteger('doctor_id');
            $table->unsignedBigInteger('appointment_id')->nullable();

            $table->string('prescriber_name');
            $table->string('prescriber_licence_number')->nullable();
            $table->string('prescriber_phone')->nullable();
            $table->string('prescriber_email')->nullable();
            $table->string('clinic_name')->nullable();
            $table->string('clinic_address')->nullable();

            $table->string('patient_name');
            $table->string('patient_email')->nullable();
            $table->string('patient_phone')->nullable();
            $table->date('patient_dob')->nullable();
            $table->unsignedSmallInteger('patient_age')->nullable();

            $table->date('issued_date');
            $table->text('clinical_information')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('doctor_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('appointment_id')->references('id')->on('appointments')->nullOnDelete();
            $table->index(['doctor_id']);
            $table->index(['patient_email']);
        });

        Schema::create('lab_prescription_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lab_prescription_id');

            $table->string('test_name');
            $table->string('specimen_type')->nullable();              // blood, urine, stool, swab
            $table->enum('urgency', ['routine', 'urgent', 'stat'])->default('routine');
            $table->text('notes')->nullable();

            $table->timestamps();
            $table->foreign('lab_prescription_id', 'lab_rx_item_rx_id_fk')
                ->references('id')->on('lab_prescriptions')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lab_prescription_items');
        Schema::dropIfExists('lab_prescriptions');
        Schema::dropIfExists('medication_prescription_items');
        Schema::dropIfExists('medication_prescriptions');
    }
};
