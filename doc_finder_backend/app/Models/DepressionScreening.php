<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DepressionScreening extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'q1_score', 'q2_score', 'total_score', 'answers', 'ip_address',
    ];

    protected $casts = [
        'answers'     => 'array',
        'q1_score'    => 'integer',
        'q2_score'    => 'integer',
        'total_score' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
