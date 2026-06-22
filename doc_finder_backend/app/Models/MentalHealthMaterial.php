<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MentalHealthMaterial extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'description', 'image_path', 'file_path',
        'file_type', 'is_free', 'price', 'is_active', 'created_by', 'survey_id',
    ];

    protected $casts = [
        'is_free'   => 'boolean',
        'is_active' => 'boolean',
        'price'     => 'float',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function survey()
    {
        return $this->belongsTo(Survey::class, 'survey_id');
    }
}
