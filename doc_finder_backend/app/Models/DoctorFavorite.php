<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DoctorFavorite extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'doctor_id',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'doctor_id' => 'integer',
    ];

    /**
     * Get the user who favorited the doctor.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Get the doctor that was favorited.
     */
    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}
