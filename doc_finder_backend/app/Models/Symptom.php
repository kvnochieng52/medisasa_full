<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Symptom extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the specializations associated with this symptom
     */
    public function specializations()
    {
        return $this->belongsToMany(
            Specialization::class,
            'symptom_specialization_mappings',
            'symptom_id',
            'specialization_id'
        )->withPivot('priority')->withTimestamps();
    }

    /**
     * Scope for active symptoms
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}