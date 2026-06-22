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

    // Expose `name` (and `description`) on serialised output so API consumers
    // can read a single canonical field name. The DB columns remain
    // `specialization_name` / `specialization_description`.
    protected $appends = ['name', 'description'];

    public function getNameAttribute(): ?string
    {
        return $this->specialization_name;
    }

    public function getDescriptionAttribute(): ?string
    {
        return $this->specialization_description;
    }

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
