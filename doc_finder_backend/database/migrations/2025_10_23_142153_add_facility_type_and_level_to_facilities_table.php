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
        Schema::table('facilities', function (Blueprint $table) {
            $table->unsignedBigInteger('facility_type_id')->nullable()->after('facility_email');
            $table->unsignedBigInteger('facility_level_id')->nullable()->after('facility_type_id');

            // Foreign key constraints
            $table->foreign('facility_type_id')->references('id')->on('facility_types')->onDelete('set null');
            $table->foreign('facility_level_id')->references('id')->on('facility_levels')->onDelete('set null');

            // Indexes
            $table->index('facility_type_id');
            $table->index('facility_level_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('facilities', function (Blueprint $table) {
            $table->dropForeign(['facility_type_id']);
            $table->dropForeign(['facility_level_id']);
            $table->dropIndex(['facility_type_id']);
            $table->dropIndex(['facility_level_id']);
            $table->dropColumn(['facility_type_id', 'facility_level_id']);
        });
    }
};
