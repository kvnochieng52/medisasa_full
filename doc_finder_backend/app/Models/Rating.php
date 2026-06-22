<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'rateable_type',
        'rateable_id',
        'overall_rating',
        'communication_rating',
        'bedside_manner_rating',
        'waiting_time_rating',
        'knowledge_rating',
        'cleanliness_rating',
        'staff_rating',
        'facilities_rating',
        'accessibility_rating',
        'comment',
        'is_verified',
        'appointment_id',
        'is_anonymous',
        'recommendation'
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'is_anonymous' => 'boolean',
        'overall_rating' => 'integer',
        'communication_rating' => 'integer',
        'bedside_manner_rating' => 'integer',
        'waiting_time_rating' => 'integer',
        'knowledge_rating' => 'integer',
        'cleanliness_rating' => 'integer',
        'staff_rating' => 'integer',
        'facilities_rating' => 'integer',
        'accessibility_rating' => 'integer',
    ];

    /**
     * Get the parent rateable model (Doctor or Facility).
     */
    public function rateable()
    {
        return $this->morphTo();
    }

    /**
     * Get the user who made the rating.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the appointment associated with this rating.
     */
    public function appointment()
    {
        return $this->belongsTo(Appointment::class);
    }

    /**
     * Scope to get only verified ratings.
     */
    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    /**
     * Scope to get ratings for doctors.
     */
    public function scopeForDoctors($query)
    {
        return $query->where('rateable_type', User::class);
    }

    /**
     * Scope to get ratings for facilities.
     */
    public function scopeForFacilities($query)
    {
        return $query->where('rateable_type', 'App\\Models\\Facility');
    }

    /**
     * Get doctor-specific ratings as an array.
     */
    public function getDoctorRatingsAttribute()
    {
        if ($this->rateable_type !== User::class) {
            return null;
        }

        return [
            'communication' => $this->communication_rating,
            'bedside_manner' => $this->bedside_manner_rating,
            'waiting_time' => $this->waiting_time_rating,
            'knowledge' => $this->knowledge_rating,
        ];
    }

    /**
     * Get facility-specific ratings as an array.
     */
    public function getFacilityRatingsAttribute()
    {
        if ($this->rateable_type !== 'App\\Models\\Facility') {
            return null;
        }

        return [
            'cleanliness' => $this->cleanliness_rating,
            'staff' => $this->staff_rating,
            'facilities' => $this->facilities_rating,
            'accessibility' => $this->accessibility_rating,
        ];
    }

    /**
     * Get star rating display (for 1-5 stars).
     */
    public function getStarDisplayAttribute()
    {
        return str_repeat('★', $this->overall_rating) . str_repeat('☆', 5 - $this->overall_rating);
    }

    /**
     * Check if rating is for a doctor.
     */
    public function isDoctorRating()
    {
        return $this->rateable_type === User::class;
    }

    /**
     * Check if rating is for a facility.
     */
    public function isFacilityRating()
    {
        return $this->rateable_type === 'App\\Models\\Facility';
    }

    /**
     * Get display name for the rater (considering anonymity).
     */
    public function getRaterNameAttribute()
    {
        if ($this->is_anonymous) {
            return 'Anonymous User';
        }

        return $this->user->name ?? 'Unknown User';
    }
}
