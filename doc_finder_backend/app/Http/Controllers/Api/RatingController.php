<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rating;
use App\Models\User;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class RatingController extends Controller
{
    /**
     * Submit a rating for a doctor or facility
     */
    public function store(Request $request)
    {
        // Dynamic validation for rateable_id based on rateable_type
        $validationRules = [
            'rateable_type' => 'required|string|in:doctor,facility',
            'rateable_id' => 'required|integer',
            'overall_rating' => 'required|integer|min:1|max:5',
            'appointment_id' => 'nullable|integer|exists:appointments,id',
            'comment' => 'nullable|string|max:1000',
            'is_anonymous' => 'boolean',
            'recommendation' => 'nullable|string|in:yes,no,maybe',

            // Doctor-specific ratings
            'communication_rating' => 'nullable|integer|min:1|max:5',
            'bedside_manner_rating' => 'nullable|integer|min:1|max:5',
            'waiting_time_rating' => 'nullable|integer|min:1|max:5',
            'knowledge_rating' => 'nullable|integer|min:1|max:5',

            // Facility-specific ratings (future use)
            'cleanliness_rating' => 'nullable|integer|min:1|max:5',
            'staff_rating' => 'nullable|integer|min:1|max:5',
            'facilities_rating' => 'nullable|integer|min:1|max:5',
            'accessibility_rating' => 'nullable|integer|min:1|max:5',
        ];

        // Add dynamic validation for rateable_id based on type
        if ($request->rateable_type === 'doctor') {
            $validationRules['rateable_id'] .= '|exists:users,id';
        } elseif ($request->rateable_type === 'facility') {
            $validationRules['rateable_id'] .= '|exists:facilities,id';
        }

        $validator = Validator::make($request->all(), $validationRules);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = Auth::user();

        // Convert rateable_type to model class
        $rateableType = $request->rateable_type === 'doctor' ? User::class : 'App\\Models\\Facility';

        // Check if user has already rated this entity for this appointment
        if ($request->appointment_id) {
            $existingRating = Rating::where('user_id', $user->id)
                ->where('appointment_id', $request->appointment_id)
                ->first();

            if ($existingRating) {
                return response()->json([
                    'success' => false,
                    'message' => 'You have already rated this appointment'
                ], 409);
            }

            // Verify the appointment belongs to the user
            $appointment = Appointment::where('id', $request->appointment_id)
                ->where('user_id', $user->id)
                ->where('status', 'completed')
                ->first();

            if (!$appointment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid appointment or appointment not completed'
                ], 400);
            }
        }

        // Check if it's a doctor rating and verify the doctor exists and is a service provider
        if ($request->rateable_type === 'doctor') {
            $doctor = User::where('id', $request->rateable_id)
                ->where('account_type', 2) // Service provider
                ->where('sp_approved', 1)
                ->first();

            if (!$doctor) {
                return response()->json([
                    'success' => false,
                    'message' => 'Doctor not found or not approved'
                ], 404);
            }
        }

        // Check if it's a facility rating and verify the facility exists and is active
        if ($request->rateable_type === 'facility') {
            $facility = \App\Models\Facility::where('id', $request->rateable_id)
                ->where('is_active', 1)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found or not active'
                ], 404);
            }
        }

        try {
            $ratingData = [
                'user_id' => $user->id,
                'rateable_type' => $rateableType,
                'rateable_id' => $request->rateable_id,
                'overall_rating' => $request->overall_rating,
                'comment' => $request->comment,
                'is_anonymous' => $request->is_anonymous ?? false,
                'recommendation' => $request->recommendation,
                'appointment_id' => $request->appointment_id,
                'is_verified' => !empty($request->appointment_id),
            ];

            // Add doctor-specific ratings
            if ($request->rateable_type === 'doctor') {
                $ratingData['communication_rating'] = $request->communication_rating;
                $ratingData['bedside_manner_rating'] = $request->bedside_manner_rating;
                $ratingData['waiting_time_rating'] = $request->waiting_time_rating;
                $ratingData['knowledge_rating'] = $request->knowledge_rating;
            }

            // Add facility-specific ratings (for future use)
            if ($request->rateable_type === 'facility') {
                $ratingData['cleanliness_rating'] = $request->cleanliness_rating;
                $ratingData['staff_rating'] = $request->staff_rating;
                $ratingData['facilities_rating'] = $request->facilities_rating;
                $ratingData['accessibility_rating'] = $request->accessibility_rating;
            }

            $rating = Rating::create($ratingData);

            return response()->json([
                'success' => true,
                'message' => 'Rating submitted successfully',
                'data' => [
                    'rating_id' => $rating->id,
                    'overall_rating' => $rating->overall_rating,
                    'star_display' => $rating->star_display
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to submit rating',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get ratings for a specific doctor or facility
     */
    public function show(Request $request, $type, $id)
    {
        $validator = Validator::make([
            'type' => $type,
            'id' => $id
        ], [
            'type' => 'required|string|in:doctor,facility',
            'id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid parameters'
            ], 422);
        }

        $rateableType = $type === 'doctor' ? User::class : 'App\\Models\\Facility';

        try {
            $ratings = Rating::with(['user'])
                ->where('rateable_type', $rateableType)
                ->where('rateable_id', $id)
                ->orderBy('created_at', 'desc')
                ->paginate(10);

            // Calculate statistics
            $stats = $this->calculateRatingStats($rateableType, $id);

            return response()->json([
                'success' => true,
                'data' => [
                    'ratings' => $ratings->items(),
                    'pagination' => [
                        'current_page' => $ratings->currentPage(),
                        'total_pages' => $ratings->lastPage(),
                        'total_ratings' => $ratings->total(),
                        'per_page' => $ratings->perPage(),
                    ],
                    'statistics' => $stats
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch ratings',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get user's own ratings
     */
    public function userRatings(Request $request)
    {
        $user = Auth::user();

        try {
            $ratings = Rating::with(['rateable'])
                ->where('user_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->paginate(10);

            return response()->json([
                'success' => true,
                'data' => [
                    'ratings' => $ratings->items(),
                    'pagination' => [
                        'current_page' => $ratings->currentPage(),
                        'total_pages' => $ratings->lastPage(),
                        'total_ratings' => $ratings->total(),
                        'per_page' => $ratings->perPage(),
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch user ratings',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get top-rated doctors for search results
     */
    public function topRatedDoctors(Request $request)
    {
        try {
            $limit = $request->get('limit', 10);

            $topDoctors = DB::table('users')
                ->select([
                    'users.id',
                    'users.name',
                    'users.email',
                    'users.specialization',
                    'users.experience_years',
                    'users.profile_image',
                    DB::raw('ROUND(AVG(ratings.overall_rating), 2) as average_rating'),
                    DB::raw('COUNT(ratings.id) as total_ratings')
                ])
                ->leftJoin('ratings', function($join) {
                    $join->on('users.id', '=', 'ratings.rateable_id')
                         ->where('ratings.rateable_type', '=', User::class);
                })
                ->where('users.account_type', 2) // Service providers
                ->where('users.sp_approved', 1) // Approved
                ->groupBy('users.id')
                ->having('total_ratings', '>', 0)
                ->orderBy('average_rating', 'desc')
                ->orderBy('total_ratings', 'desc')
                ->limit($limit)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $topDoctors
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch top-rated doctors',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculate rating statistics for a doctor or facility
     */
    private function calculateRatingStats($rateableType, $rateableId)
    {
        $ratings = Rating::where('rateable_type', $rateableType)
            ->where('rateable_id', $rateableId)
            ->get();

        if ($ratings->isEmpty()) {
            return [
                'average_rating' => 0,
                'total_ratings' => 0,
                'star_distribution' => [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0],
                'detailed_averages' => [],
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

        // Detailed averages for doctors
        $detailedAverages = [];
        if ($rateableType === User::class) {
            $detailedAverages = [
                'communication' => round($ratings->whereNotNull('communication_rating')->avg('communication_rating'), 2),
                'bedside_manner' => round($ratings->whereNotNull('bedside_manner_rating')->avg('bedside_manner_rating'), 2),
                'waiting_time' => round($ratings->whereNotNull('waiting_time_rating')->avg('waiting_time_rating'), 2),
                'knowledge' => round($ratings->whereNotNull('knowledge_rating')->avg('knowledge_rating'), 2),
            ];
        }

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
}
