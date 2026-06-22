<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscription_packages', function (Blueprint $table) {
            $table->unsignedInteger('max_appointments_per_month')->nullable()->after('features');
            $table->unsignedInteger('max_facilities')->nullable()->after('max_appointments_per_month');
            $table->unsignedInteger('max_hospitals')->nullable()->after('max_facilities');
        });
    }

    public function down(): void
    {
        Schema::table('subscription_packages', function (Blueprint $table) {
            $table->dropColumn(['max_appointments_per_month', 'max_facilities', 'max_hospitals']);
        });
    }
};
