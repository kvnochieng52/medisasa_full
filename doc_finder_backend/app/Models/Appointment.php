<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    use HasFactory;

    protected $fillable = [
        'doctor_id',
        'patient_name',
        'patient_email',
        'patient_telephone',
        'patient_location',
        'appointment_date',
        'appointment_time',
        'consultation_type',
        'status',
        'notes',
        'google_meet_link',
        'google_event_id',
        'doctor_calendar_event_id',
        'patient_calendar_event_id',
        'meet_created_at',
    ];

    protected $casts = [
        'appointment_date' => 'date',
        'appointment_time' => 'datetime:H:i',
        'meet_created_at' => 'datetime',
    ];

    /**
     * Get the doctor that owns the appointment
     */
    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}