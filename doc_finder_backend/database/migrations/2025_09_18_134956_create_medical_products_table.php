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
        Schema::create('medical_products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('batch_no');
            $table->string('category');
            $table->string('photo')->nullable();
            $table->decimal('cost', 10, 2);
            $table->integer('stock_quantity')->default(0);
            $table->string('manufacturer')->nullable();
            $table->date('manufacturing_date')->nullable();
            $table->date('expiry_date')->nullable();
            $table->boolean('needs_prescription')->default(false);
            $table->boolean('is_available')->default(true);
            $table->string('dosage_form')->nullable(); // tablet, syrup, injection, etc.
            $table->string('strength')->nullable(); // 500mg, 10ml, etc.
            $table->json('side_effects')->nullable();
            $table->json('conditions')->nullable(); // conditions it treats
            $table->json('ingredients')->nullable();
            $table->string('storage_conditions')->nullable();
            $table->text('usage_instructions')->nullable();
            $table->string('barcode')->nullable();
            $table->decimal('weight', 8, 3)->nullable(); // in grams
            $table->string('unit_of_measure')->default('pieces'); // pieces, ml, grams, etc.
            $table->integer('minimum_stock_level')->default(10);
            $table->string('supplier')->nullable();
            $table->decimal('purchase_price', 10, 2)->nullable();
            $table->string('status')->default('active'); // active, discontinued, out_of_stock
            $table->timestamps();

            // Indexes for better performance
            $table->index(['category']);
            $table->index(['batch_no']);
            $table->index(['is_available']);
            $table->index(['expiry_date']);
            $table->unique(['batch_no', 'name']); // Ensure unique batch number per product
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('medical_products');
    }
};
