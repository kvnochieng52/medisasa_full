<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MedicationPrescription extends Model
{
    use HasFactory;

    protected $fillable = [
        'prescription_number',
        'doctor_id',
        'appointment_id',
        'prescriber_name',
        'prescriber_licence_number',
        'prescriber_phone',
        'prescriber_email',
        'clinic_name',
        'clinic_address',
        'patient_name',
        'patient_email',
        'patient_phone',
        'patient_dob',
        'patient_age',
        'issued_date',
        'diagnosis',
        'notes',
    ];

    protected $casts = [
        'issued_date' => 'date',
        'patient_dob' => 'date',
    ];

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function appointment()
    {
        return $this->belongsTo(Appointment::class);
    }

    public function items()
    {
        return $this->hasMany(MedicationPrescriptionItem::class);
    }
}
