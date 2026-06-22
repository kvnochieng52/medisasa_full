<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SubscriptionPackage extends Model
{
    protected $fillable = [
        'slug',
        'name',
        'amount',
        'currency',
        'duration_days',
        'description',
        'features',
        'is_popular',
        'is_active',
    ];

    protected $casts = [
        'amount'     => 'decimal:2',
        'features'   => 'array',
        'is_popular' => 'boolean',
        'is_active'  => 'boolean',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(DoctorSubscription::class, 'package_slug', 'slug');
    }
}
