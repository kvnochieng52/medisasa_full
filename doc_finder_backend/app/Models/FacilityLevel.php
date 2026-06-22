<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FacilityLevel extends Model
{
    use HasFactory;

    protected $table = 'facility_levels';

    protected $fillable = [
        'name',
        'slug',
        'description',
        'level_number',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'level_number' => 'integer',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('level_number')->orderBy('sort_order');
    }

    public function scopeByLevel($query, $levelNumber)
    {
        return $query->where('level_number', $levelNumber);
    }

    public function facilities()
    {
        return $this->hasMany(Facility::class, 'facility_level_id');
    }
}
