<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LabPrescriptionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'lab_prescription_id',
        'test_name',
        'specimen_type',
        'urgency',
        'notes',
    ];

    public function prescription()
    {
        return $this->belongsTo(LabPrescription::class, 'lab_prescription_id');
    }
}
