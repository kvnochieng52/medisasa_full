<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SurveyResponse extends Model
{
    use HasFactory;

    protected $fillable = [
        'survey_id', 'user_id', 'total_score', 'band_id', 'answers', 'ip_address',
    ];

    protected $casts = [
        'answers'     => 'array',
        'total_score' => 'integer',
    ];

    public function survey(): BelongsTo
    {
        return $this->belongsTo(Survey::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function band(): BelongsTo
    {
        return $this->belongsTo(SurveyResultBand::class, 'band_id');
    }
}
