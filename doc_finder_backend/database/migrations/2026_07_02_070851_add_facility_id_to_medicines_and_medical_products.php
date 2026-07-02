<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Associate medicines and medical products with the facility that supplies /
 * stocks them. Nullable for now (existing rows have no facility).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('medicines', function (Blueprint $table) {
            $table->unsignedBigInteger('facility_id')->nullable()->after('subcategory_id');
            $table->foreign('facility_id')->references('id')->on('facilities')->nullOnDelete();
            $table->index('facility_id');
        });

        Schema::table('medical_products', function (Blueprint $table) {
            $table->unsignedBigInteger('facility_id')->nullable()->after('id');
            $table->foreign('facility_id')->references('id')->on('facilities')->nullOnDelete();
            $table->index('facility_id');
        });
    }

    public function down(): void
    {
        Schema::table('medicines', function (Blueprint $table) {
            $table->dropForeign(['facility_id']);
            $table->dropIndex(['facility_id']);
            $table->dropColumn('facility_id');
        });

        Schema::table('medical_products', function (Blueprint $table) {
            $table->dropForeign(['facility_id']);
            $table->dropIndex(['facility_id']);
            $table->dropColumn('facility_id');
        });
    }
};
