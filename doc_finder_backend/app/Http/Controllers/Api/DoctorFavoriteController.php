<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DoctorFavorite;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class DoctorFavoriteController extends Controller
{
    /**
     * Get user's favorite doctors
     */
    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $perPage = min($request->get('per_page', 15), 50);

        $favorites = DoctorFavorite::where('user_id', $user->id)
            ->with(['doctor' => function ($query) {
                $query->where('account_type', 2) // Ensure it's a doctor
                      ->select('id', 'name', 'email', 'profile_image');
            }])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        // Filter out any favorites where doctor might have been deleted or is not a doctor
        $filteredFavorites = $favorites->getCollection()->filter(function ($favorite) {
            return $favorite->doctor !== null;
        });

        $favorites->setCollection($filteredFavorites);

        return response()->json([
            'success' => true,
            'favorites' => $favorites->items(),
            'pagination' => [
                'current_page' => $favorites->currentPage(),
                'last_page' => $favorites->lastPage(),
                'per_page' => $favorites->perPage(),
                'total' => $favorites->total(),
            ]
        ]);
    }

    /**
     * Add doctor to favorites
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'doctor_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = Auth::user();
        $doctorId = $request->doctor_id;

        // Verify the user is actually a doctor
        $doctor = User::where('id', $doctorId)
                     ->where('account_type', 2)
                     ->first();

        if (!$doctor) {
            return response()->json([
                'success' => false,
                'message' => 'Doctor not found'
            ], 404);
        }

        // Check if already favorited
        $existingFavorite = DoctorFavorite::where('user_id', $user->id)
                                        ->where('doctor_id', $doctorId)
                                        ->first();

        if ($existingFavorite) {
            return response()->json([
                'success' => false,
                'message' => 'Doctor already in favorites'
            ], 409);
        }

        // Create favorite
        $favorite = DoctorFavorite::create([
            'user_id' => $user->id,
            'doctor_id' => $doctorId,
        ]);

        $favorite->load('doctor');

        return response()->json([
            'success' => true,
            'message' => 'Doctor added to favorites',
            'favorite' => $favorite
        ], 201);
    }

    /**
     * Remove doctor from favorites
     */
    public function destroy(Request $request, $doctorId): JsonResponse
    {
        $user = Auth::user();

        $favorite = DoctorFavorite::where('user_id', $user->id)
                                 ->where('doctor_id', $doctorId)
                                 ->first();

        if (!$favorite) {
            return response()->json([
                'success' => false,
                'message' => 'Favorite not found'
            ], 404);
        }

        $favorite->delete();

        return response()->json([
            'success' => true,
            'message' => 'Doctor removed from favorites'
        ]);
    }

    /**
     * Check if doctor is favorited by current user
     */
    public function check(Request $request, $doctorId): JsonResponse
    {
        $user = Auth::user();

        $isFavorited = DoctorFavorite::where('user_id', $user->id)
                                   ->where('doctor_id', $doctorId)
                                   ->exists();

        return response()->json([
            'success' => true,
            'is_favorited' => $isFavorited
        ]);
    }

    /**
     * Toggle favorite status
     */
    public function toggle(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'doctor_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = Auth::user();
        $doctorId = $request->doctor_id;

        // Verify the user is actually a doctor
        $doctor = User::where('id', $doctorId)
                     ->where('account_type', 2)
                     ->first();

        if (!$doctor) {
            return response()->json([
                'success' => false,
                'message' => 'Doctor not found'
            ], 404);
        }

        $favorite = DoctorFavorite::where('user_id', $user->id)
                                 ->where('doctor_id', $doctorId)
                                 ->first();

        if ($favorite) {
            // Remove from favorites
            $favorite->delete();
            return response()->json([
                'success' => true,
                'message' => 'Doctor removed from favorites',
                'is_favorited' => false
            ]);
        } else {
            // Add to favorites
            $favorite = DoctorFavorite::create([
                'user_id' => $user->id,
                'doctor_id' => $doctorId,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Doctor added to favorites',
                'is_favorited' => true
            ]);
        }
    }
}
