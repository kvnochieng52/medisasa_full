<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RadiologyPrescriptionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'radiology_prescription_id',
        'study_name',
        'modality',
        'body_part',
        'side',
        'contrast',
        'urgency',
        'clinical_indication',
        'notes',
    ];

    public function prescription()
    {
        return $this->belongsTo(RadiologyPrescription::class, 'radiology_prescription_id');
    }
}
