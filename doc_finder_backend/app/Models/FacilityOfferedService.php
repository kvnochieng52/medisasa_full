<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * A specific service that a facility offers, with its own title/description
 * and amount. Optionally links back to a FacilityService (the reference row)
 * when the facility picked a catalogued service; null when it's custom.
 */
class FacilityOfferedService extends Model
{
    use HasFactory;

    protected $fillable = [
        'facility_id',
        'facility_service_id',
        'title',
        'description',
        'amount',
        'currency',
        'is_active',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function facility()
    {
        return $this->belongsTo(Facility::class);
    }

    public function service()
    {
        return $this->belongsTo(FacilityService::class, 'facility_service_id');
    }
}
