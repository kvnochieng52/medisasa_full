<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Reference / lookup: catalogue of common medical services a facility
        // may offer (Consultation, X-Ray, Blood Test, …). Admin-editable.
        Schema::create('facility_services', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
            $table->index(['is_active', 'sort_order']);
        });

        // Each facility's actual services with their own title, description
        // and amount. `facility_service_id` is nullable so a facility can
        // list a custom service that isn't in the reference catalogue.
        Schema::create('facility_offered_services', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('facility_id');
            $table->unsignedBigInteger('facility_service_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->decimal('amount', 12, 2)->nullable();
            $table->string('currency', 8)->default('KES');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('facility_id')->references('id')->on('facilities')->onDelete('cascade');
            $table->foreign('facility_service_id')->references('id')->on('facility_services')->nullOnDelete();
            $table->index(['facility_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('facility_offered_services');
        Schema::dropIfExists('facility_services');
    }
};
