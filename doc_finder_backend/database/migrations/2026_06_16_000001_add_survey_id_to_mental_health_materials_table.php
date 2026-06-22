<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('mental_health_materials', function (Blueprint $table) {
            $table->foreignId('survey_id')
                  ->nullable()
                  ->after('created_by')
                  ->constrained('surveys')
                  ->nullOnDelete();

            $table->index('survey_id');
        });
    }

    public function down(): void
    {
        Schema::table('mental_health_materials', function (Blueprint $table) {
            $table->dropForeign(['survey_id']);
            $table->dropIndex(['survey_id']);
            $table->dropColumn('survey_id');
        });
    }
};
