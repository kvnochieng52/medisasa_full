<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('condition_specialization_mappings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('condition_id');
            $table->unsignedBigInteger('specialization_id');
            $table->integer('priority')->default(1); // 1=primary, 2=secondary
            $table->timestamps();

            $table->foreign('condition_id')->references('id')->on('conditions')->onDelete('cascade');
            $table->foreign('specialization_id')->references('id')->on('specializations')->onDelete('cascade');

            $table->unique(['condition_id', 'specialization_id'], 'condition_spec_unique');
            $table->index(['condition_id']);
            $table->index(['specialization_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('condition_specialization_mappings');
    }
};