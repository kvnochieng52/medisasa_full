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
        Schema::table('appointments', function (Blueprint $table) {
            $table->string('google_meet_link')->nullable()->after('notes');
            $table->string('google_event_id')->nullable()->after('google_meet_link');
            $table->string('doctor_calendar_event_id')->nullable()->after('google_event_id');
            $table->string('patient_calendar_event_id')->nullable()->after('doctor_calendar_event_id');
            $table->timestamp('meet_created_at')->nullable()->after('patient_calendar_event_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->dropColumn([
                'google_meet_link',
                'google_event_id',
                'doctor_calendar_event_id',
                'patient_calendar_event_id',
                'meet_created_at'
            ]);
        });
    }
};
