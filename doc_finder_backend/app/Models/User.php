<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
    use \Spatie\Permission\Traits\HasRoles;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */


    protected $fillable = [
        'name',
        'email',
        'password',
        'telephone',
        'id_number',
        'address',
        'dob',
        'account_type',
        'profile_image',
        'is_active',
        'verification_code',
        'first_login',
        'sp_approved',
        'licence_number',
        'professional_bio',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    /**
     * Get the specializations for the user (doctor)
     */
    public function specializations()
    {
        return $this->belongsToMany(Specialization::class, 'user_specializations');
    }

    /**
     * Get appointments for this doctor
     */
    public function appointments()
    {
        return $this->hasMany(Appointment::class, 'doctor_id');
    }

    /**
     * Get the documents for the user
     */
    public function documents()
    {
        return $this->hasMany(UserDocument::class);
    }

    /**
     * Get the user role name
     */
    public function getRoleNameAttribute()
    {
        switch ($this->account_type) {
            case 1:
                return 'Standard';
            case 2:
                return 'Service Provider';
            case 3:
                return 'Admin';
            default:
                return 'Unknown';
        }
    }

    /**
     * Check if user is admin
     */
    public function isAdmin()
    {
        return $this->account_type == 3;
    }

    /**
     * Check if user is service provider
     */
    public function isServiceProvider()
    {
        return $this->account_type == 2;
    }

    /**
     * Check if user is standard user
     */
    public function isStandard()
    {
        return $this->account_type == 1;
    }

    /**
     * Scope to get only approved doctors
     */
    public function scopeApprovedDoctors($query)
    {
        return $query->where('account_type', 2)
                    ->where('sp_approved', 1)
                    ->where('is_active', 1);
    }

    /**
     * Ratings that this user (doctor) has received
     */
    public function ratingsReceived()
    {
        return $this->morphMany(Rating::class, 'rateable');
    }

    /**
     * Ratings that this user has given to others
     */
    public function ratingsGiven()
    {
        return $this->hasMany(Rating::class, 'user_id');
    }

    /**
     * Get average rating for this doctor
     */
    public function getAverageRatingAttribute()
    {
        return $this->ratingsReceived()->avg('overall_rating') ?? 0;
    }

    /**
     * Get total number of ratings for this doctor
     */
    public function getTotalRatingsAttribute()
    {
        return $this->ratingsReceived()->count();
    }

    /**
     * Get star display for doctor rating
     */
    public function getStarDisplayAttribute()
    {
        $rating = round($this->average_rating);
        return str_repeat('★', $rating) . str_repeat('☆', 5 - $rating);
    }

    /**
     * Get detailed rating statistics for doctor
     */
    public function getRatingStatsAttribute()
    {
        $ratings = $this->ratingsReceived;

        if ($ratings->isEmpty()) {
            return [
                'average_rating' => 0,
                'total_ratings' => 0,
                'star_distribution' => [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0],
                'detailed_averages' => [
                    'communication' => 0,
                    'bedside_manner' => 0,
                    'waiting_time' => 0,
                    'knowledge' => 0,
                ],
                'recommendation_percentage' => 0
            ];
        }

        $totalRatings = $ratings->count();
        $averageRating = round($ratings->avg('overall_rating'), 2);

        // Star distribution
        $starDistribution = [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0];
        foreach ($ratings as $rating) {
            $starDistribution[$rating->overall_rating]++;
        }

        // Detailed averages
        $detailedAverages = [
            'communication' => round($ratings->whereNotNull('communication_rating')->avg('communication_rating'), 2),
            'bedside_manner' => round($ratings->whereNotNull('bedside_manner_rating')->avg('bedside_manner_rating'), 2),
            'waiting_time' => round($ratings->whereNotNull('waiting_time_rating')->avg('waiting_time_rating'), 2),
            'knowledge' => round($ratings->whereNotNull('knowledge_rating')->avg('knowledge_rating'), 2),
        ];

        // Recommendation percentage
        $recommendationCount = $ratings->where('recommendation', 'yes')->count();
        $recommendationPercentage = $totalRatings > 0 ? round(($recommendationCount / $totalRatings) * 100, 1) : 0;

        return [
            'average_rating' => $averageRating,
            'total_ratings' => $totalRatings,
            'star_distribution' => $starDistribution,
            'detailed_averages' => $detailedAverages,
            'recommendation_percentage' => $recommendationPercentage
        ];
    }

    /**
     * Check if user can rate this doctor (must have completed appointment)
     */
    public function canBeRatedBy($userId)
    {
        if (!$this->isServiceProvider()) {
            return false;
        }

        // Check if user has completed appointment with this doctor
        return Appointment::where('user_id', $userId)
            ->where('doctor_id', $this->id)
            ->where('status', 'completed')
            ->exists();
    }

    /**
     * Scope to get doctors ordered by rating
     */
    public function scopeOrderByRating($query, $direction = 'desc')
    {
        return $query->withAvg('ratingsReceived', 'overall_rating')
                    ->orderBy('ratings_received_avg_overall_rating', $direction);
    }
}
