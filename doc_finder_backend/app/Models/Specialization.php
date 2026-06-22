<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Specialization extends Model
{
    use HasFactory;

    protected $fillable = [
        'specialization_name',
        'specialization_description',
        'is_active',
        'is_active_for_facility',
    ];

    /**
     * Get the facilities that have this specialization
     */
    public function facilities()
    {
        return $this->belongsToMany(
            Facility::class,
            'facility_specialities',
            'speciality_id',
            'facility_id'
        );
    }
}
