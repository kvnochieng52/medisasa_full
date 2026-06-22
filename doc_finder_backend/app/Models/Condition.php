<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Condition extends Model
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
     * Get the specializations associated with this condition
     */
    public function specializations()
    {
        return $this->belongsToMany(
            Specialization::class,
            'condition_specialization_mappings',
            'condition_id',
            'specialization_id'
        )->withPivot('priority')->withTimestamps();
    }

    /**
     * Scope for active conditions
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}