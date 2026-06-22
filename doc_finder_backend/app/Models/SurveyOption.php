<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SurveyOption extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'question_id', 'label', 'score_value', 'color', 'order_index',
    ];

    protected $casts = [
        'score_value' => 'integer',
        'order_index' => 'integer',
    ];

    public function question(): BelongsTo
    {
        return $this->belongsTo(SurveyQuestion::class, 'question_id');
    }
}
