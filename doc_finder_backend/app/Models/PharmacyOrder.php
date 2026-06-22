<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PharmacyOrder extends Model
{
    protected $fillable = [
        'user_id',
        'order_ref',
        'customer_name',
        'customer_phone',
        'delivery_address',
        'delivery_city',
        'delivery_option',
        'delivery_fee',
        'subtotal',
        'total',
        'notes',
        'items',
        'status',
        'dpo_trans_token',
        'dpo_trans_ref',
        'company_ref',
    ];

    protected $casts = [
        'items'        => 'array',
        'delivery_fee' => 'decimal:2',
        'subtotal'     => 'decimal:2',
        'total'        => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
