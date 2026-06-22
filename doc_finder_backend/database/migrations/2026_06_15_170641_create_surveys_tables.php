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
        Schema::create('surveys', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->text('instructions')->nullable();
            $table->string('slug')->unique();
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('survey_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('survey_id')->constrained()->cascadeOnDelete();
            $table->text('question_text');
            $table->string('hint')->nullable();
            $table->unsignedSmallInteger('order_index')->default(0);
            $table->timestamps();
        });

        Schema::create('survey_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_id')->constrained('survey_questions')->cascadeOnDelete();
            $table->string('label');
            $table->unsignedTinyInteger('score_value');
            $table->string('color')->default('green');
            $table->unsignedTinyInteger('order_index')->default(0);
        });

        Schema::create('survey_result_bands', function (Blueprint $table) {
            $table->id();
            $table->foreignId('survey_id')->constrained()->cascadeOnDelete();
            $table->string('label');
            $table->unsignedSmallInteger('min_score');
            $table->unsignedSmallInteger('max_score');
            $table->text('message');
            $table->string('result_type')->default('low'); // low|moderate|high
            $table->boolean('show_therapist_cta')->default(false);
            $table->unsignedTinyInteger('order_index')->default(0);
        });

        Schema::create('survey_band_materials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('band_id')->constrained('survey_result_bands')->cascadeOnDelete();
            $table->foreignId('material_id')->constrained('mental_health_materials')->cascadeOnDelete();
        });

        Schema::create('survey_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('survey_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedSmallInteger('total_score');
            $table->foreignId('band_id')->nullable()->constrained('survey_result_bands')->nullOnDelete();
            $table->json('answers');
            $table->string('ip_address')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('survey_responses');
        Schema::dropIfExists('survey_band_materials');
        Schema::dropIfExists('survey_result_bands');
        Schema::dropIfExists('survey_options');
        Schema::dropIfExists('survey_questions');
        Schema::dropIfExists('surveys');
    }
};
