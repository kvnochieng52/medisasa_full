<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('symptom_specialization_mappings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('symptom_id');
            $table->unsignedBigInteger('specialization_id');
            $table->integer('priority')->default(1); // 1=primary, 2=secondary
            $table->timestamps();

            $table->foreign('symptom_id')->references('id')->on('symptoms')->onDelete('cascade');
            $table->foreign('specialization_id')->references('id')->on('specializations')->onDelete('cascade');

            $table->unique(['symptom_id', 'specialization_id'], 'symptom_spec_unique');
            $table->index(['symptom_id']);
            $table->index(['specialization_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('symptom_specialization_mappings');
    }
};