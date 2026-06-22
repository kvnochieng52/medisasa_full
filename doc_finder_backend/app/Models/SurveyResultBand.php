<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class SurveyResultBand extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'survey_id', 'label', 'min_score', 'max_score',
        'message', 'result_type', 'show_therapist_cta', 'order_index',
    ];

    protected $casts = [
        'min_score'          => 'integer',
        'max_score'          => 'integer',
        'order_index'        => 'integer',
        'show_therapist_cta' => 'boolean',
    ];

    public function survey(): BelongsTo
    {
        return $this->belongsTo(Survey::class);
    }

    public function materials(): BelongsToMany
    {
        return $this->belongsToMany(MentalHealthMaterial::class, 'survey_band_materials', 'band_id', 'material_id');
    }
}
