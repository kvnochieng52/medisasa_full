<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Facility extends Model
{
    use HasFactory;

    protected $fillable = [
        'facility_name',
        'facility_profile',
        'facility_cover_image',
        'facility_logo',
        'facility_phone',
        'facility_email',
        'facility_location',
        'facility_website',
        'facility_type_id',
        'facility_level_id',
        'is_active',
        'created_by',
        'updated_by',
    ];

    /**
     * Get the specialties for the facility through the pivot table
     */
    public function specialties()
    {
        return $this->belongsToMany(
            Specialization::class,
            'facility_specialities', // pivot table name
            'facility_id', // foreign key on pivot table for this model
            'speciality_id' // foreign key on pivot table for related model
        );
    }

    /**
     * Get the user who created this facility
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get the user who last updated this facility
     */
    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /**
     * Get the facility type
     */
    public function facilityType()
    {
        return $this->belongsTo(FacilityType::class, 'facility_type_id');
    }

    /**
     * Get the facility level
     */
    public function facilityLevel()
    {
        return $this->belongsTo(FacilityLevel::class, 'facility_level_id');
    }

    /**
     * Get the insurances accepted by this facility
     */
    public function insurances()
    {
        return $this->belongsToMany(
            Insurance::class,
            'facility_insurances',
            'facility_id',
            'insurance_id'
        )->withTimestamps()->withPivot('created_by', 'updated_by');
    }

    /**
     * Services this facility offers, with prices.
     */
    public function offeredServices()
    {
        return $this->hasMany(FacilityOfferedService::class);
    }
}
