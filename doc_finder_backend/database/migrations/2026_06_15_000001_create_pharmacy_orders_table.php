<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pharmacy_orders', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('order_ref')->unique();
            $table->string('customer_name');
            $table->string('customer_phone');
            $table->string('delivery_address')->nullable();
            $table->string('delivery_city')->nullable();
            $table->string('delivery_option'); // standard/express/pickup
            $table->decimal('delivery_fee', 10, 2)->default(0);
            $table->decimal('subtotal', 10, 2);
            $table->decimal('total', 10, 2);
            $table->text('notes')->nullable();
            $table->json('items'); // array of {id, name, price, quantity, type}
            $table->string('status')->default('pending'); // pending/paid/failed/cancelled
            $table->string('dpo_trans_token')->nullable();
            $table->string('dpo_trans_ref')->nullable();
            $table->string('company_ref')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pharmacy_orders');
    }
};
