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
        Schema::table('medicines', function (Blueprint $table) {
            // Remove unique constraint from medicine_number
            $table->dropUnique(['medicine_number']);

            // Remove unique constraint from slug
            $table->dropUnique(['slug']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('medicines', function (Blueprint $table) {
            // Restore unique constraints if needed
            $table->unique('medicine_number');
            $table->unique('slug');
        });
    }
};
