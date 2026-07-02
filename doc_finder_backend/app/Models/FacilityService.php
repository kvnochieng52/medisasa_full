<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Reference / catalogue of medical services a facility may offer.
 * Admin-editable; facilities pick from this list or add a custom entry.
 */
class FacilityService extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function offerings()
    {
        return $this->hasMany(FacilityOfferedService::class);
    }
}
