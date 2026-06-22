<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DoctorSubscription extends Model
{
    protected $fillable = [
        'user_id',
        'plan',
        'amount',
        'currency',
        'payment_method',
        'status',
        'dpo_trans_token',
        'dpo_trans_ref',
        'dpo_transaction_id',
        'company_ref',
        'subscription_starts_at',
        'subscription_ends_at',
    ];

    protected $casts = [
        'subscription_starts_at' => 'datetime',
        'subscription_ends_at'   => 'datetime',
        'amount'                 => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'paid'
            && $this->subscription_ends_at !== null
            && $this->subscription_ends_at->isFuture();
    }
}
