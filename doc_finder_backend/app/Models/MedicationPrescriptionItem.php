<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MedicationPrescriptionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'medication_prescription_id',
        'drug_name',
        'dosage_form',
        'strength',
        'frequency',
        'route',
        'duration',
        'quantity',
        'refills',
        'instructions',
    ];

    protected $casts = [
        'refills' => 'integer',
    ];

    public function prescription()
    {
        return $this->belongsTo(MedicationPrescription::class, 'medication_prescription_id');
    }
}
