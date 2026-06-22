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
        // Add visible_for_products column to medicine_categories
        Schema::table('medicine_categories', function (Blueprint $table) {
            $table->boolean('visible_for_products')->default(false)->after('is_active');
        });

        // Add visible_for_products column to medicine_subcategories
        Schema::table('medicine_subcategories', function (Blueprint $table) {
            $table->boolean('visible_for_products')->default(false)->after('is_active');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('medicine_categories', function (Blueprint $table) {
            $table->dropColumn('visible_for_products');
        });

        Schema::table('medicine_subcategories', function (Blueprint $table) {
            $table->dropColumn('visible_for_products');
        });
    }
};
