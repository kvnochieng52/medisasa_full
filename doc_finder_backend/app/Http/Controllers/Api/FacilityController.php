<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Facility;
use App\Models\FacilitySpeciality;
use App\Models\User;
use App\Models\Symptom;
use App\Models\Condition;
use App\Services\SubscriptionLimitService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;

class FacilityController extends Controller
{
    public function saveFacility(Request $request)
    {
        try {
            // Get authenticated user
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Validate the request data
            // $validator = Validator::make($request->all(), [
            //     'facility_name' => 'required|string|max:255',
            //     'facility_profile' => 'required|string',
            //     'facility_email' => 'required|email|unique:facilities,facility_email',
            //     'facility_phone' => 'required|string|max:20',
            //     'facility_location' => 'required|string',
            //     'facility_website' => 'nullable|url|max:255',
            // ]);

            // if ($validator->fails()) {
            //     return response()->json([
            //         'success' => false,
            //         'message' => 'Validation failed',
            //         'errors' => $validator->errors()
            //     ], 422);
            // }

            // Check subscription facility limit
            $limitService = app(SubscriptionLimitService::class);
            $limitCheck   = $limitService->canCreateFacility($user);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'message' => $limitCheck['message'],
                    'upgrade_required' => true,
                ], 403);
            }

            // Create a new facility
            $facility = new Facility();
            $facility->facility_name = $request->input('facility_name');
            $facility->facility_profile = $request->input('facility_profile');
            $facility->facility_email = $request->input('facility_email');
            $facility->facility_phone = $request->input('facility_phone');
            $facility->facility_location = $request->input('facility_location');
            $facility->facility_website = $request->input('facility_website');
            $facility->facility_type_id = $request->input('facility_type_id');
            $facility->facility_level_id = $request->input('facility_level_id');
            $facility->is_active = 1; // Set as active by default
            $facility->created_by = $user->id;
            $facility->updated_by = $user->id;
            $facility->save();

            // Handle insurance relationships
            $insuranceIds = $request->input('insurance_ids', []);
            if (!empty($insuranceIds) && is_array($insuranceIds)) {
                $insuranceData = [];
                foreach ($insuranceIds as $insuranceId) {
                    $insuranceData[$insuranceId] = [
                        'created_by' => $user->id,
                        'updated_by' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
                $facility->insurances()->attach($insuranceData);
            }

            return response()->json([
                'success' => true,
                'message' => 'Facility created successfully',
                'facility' => $facility
            ], 201);
        } catch (\Exception $e) {
            Log::error('Error saving facility details', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->all()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to save facility details. Please try again.'
            ], 500);
        }
    }

    public function saveFacilitySpecialties(Request $request)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Validate the request data
            $validator = Validator::make($request->all(), [
                'facility_id' => 'required|integer|exists:facilities,id',
                'specialty_ids' => 'required|array|min:1',
                'specialty_ids.*' => 'integer|exists:specializations,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $facilityId = $request->input('facility_id');
            $specialtyIds = $request->input('specialty_ids');

            // Check if facility belongs to the authenticated user
            $facility = Facility::where('id', $facilityId)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found or unauthorized'
                ], 404);
            }

            // Use database transaction to ensure data consistency
            DB::beginTransaction();

            try {
                // Delete existing facility specialties
                FacilitySpeciality::where('facility_id', $facilityId)->delete();

                // Insert new facility specialties
                $facilitySpecialties = [];
                foreach ($specialtyIds as $specialtyId) {
                    $facilitySpecialties[] = [
                        'facility_id' => $facilityId,
                        'speciality_id' => $specialtyId,
                        'created_by' => $user->id,
                        'updated_by' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }

                FacilitySpeciality::insert($facilitySpecialties);

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Facility specialties saved successfully',
                    'data' => [
                        'facility_id' => $facilityId,
                        'specialties_count' => count($specialtyIds)
                    ]
                ], 200);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Exception $e) {
            Log::error('Error saving facility specialties', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->all()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to save facility specialties. Please try again.'
            ], 500);
        }
    }

    public function getFacilities(Request $request)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $query = Facility::with(['specialties', 'facilityType', 'facilityLevel', 'insurances']) // Now this relationship exists
                ->where('created_by', $user->id)
                ->where('is_active', 1);

            // Add search functionality
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('facility_name', 'LIKE', "%{$search}%")
                        ->orWhere('facility_email', 'LIKE', "%{$search}%")
                        ->orWhere('facility_location', 'LIKE', "%{$search}%");
                });
            }

            $facilities = $query->orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'message' => 'Facilities retrieved successfully',
                'data' => $facilities
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error retrieving facilities', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve facilities'
            ], 500);
        }
    }

    public function getFacility($id)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $facility = Facility::with(['specialties', 'facilityType', 'facilityLevel', 'insurances'])
                ->where('id', $id)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Facility retrieved successfully',
                'data' => $facility
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error retrieving facility', [
                'error' => $e->getMessage(),
                'facility_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve facility'
            ], 500);
        }
    }

    public function updateFacility(Request $request, $id)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $facility = Facility::where('id', $id)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found'
                ], 404);
            }

            // Validate the request data
            // $validator = Validator::make($request->all(), [
            //     'facility_name' => 'sometimes|required|string|max:255',
            //     'facility_profile' => 'sometimes|required|string',
            //     'facility_email' => 'sometimes|required|email|unique:facilities,facility_email,' . $id,
            //     'facility_phone' => 'sometimes|required|string|max:20',
            //     'facility_location' => 'sometimes|required|string',
            //     'facility_website' => 'sometimes|nullable|url|max:255',
            //     'is_active' => 'sometimes|boolean',
            // ]);

            // if ($validator->fails()) {
            //     return response()->json([
            //         'success' => false,
            //         'message' => 'Validation failed',
            //         'errors' => $validator->errors()
            //     ], 422);
            // }

            // Update facility
            $facility->update(array_merge(
                $request->only([
                    'facility_name',
                    'facility_profile',
                    'facility_email',
                    'facility_phone',
                    'facility_location',
                    'facility_website',
                    'facility_type_id',
                    'facility_level_id',
                    'is_active'
                ]),
                ['updated_by' => $user->id]
            ));

            // Handle insurance relationships
            $insuranceIds = $request->input('insurance_ids');
            if ($insuranceIds !== null && is_array($insuranceIds)) {
                // Sync insurance relationships (this will remove old ones and add new ones)
                $insuranceData = [];
                foreach ($insuranceIds as $insuranceId) {
                    $insuranceData[$insuranceId] = [
                        'created_by' => $user->id,
                        'updated_by' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
                $facility->insurances()->sync($insuranceData);
            }

            return response()->json([
                'success' => true,
                'message' => 'Facility updated successfully',
                'data' => $facility
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error updating facility', [
                'error' => $e->getMessage(),
                'facility_id' => $id,
                'user_id' => auth()->id(),
                'request_data' => $request->all()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to update facility'
            ], 500);
        }
    }


    public function uploadFacilityLogo(Request $request)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Validate the request data
            $validator = Validator::make($request->all(), [
                'facility_id' => 'required|integer|exists:facilities,id',
                'logo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // Max 2MB
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $facilityId = $request->input('facility_id');

            // Check if facility belongs to the authenticated user
            $facility = Facility::where('id', $facilityId)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found or unauthorized'
                ], 404);
            }

            // Handle file upload
            if ($request->hasFile('logo')) {
                $logoFile = $request->file('logo');

                // Delete old logo if exists
                if ($facility->facility_logo && Storage::disk('public')->exists($facility->facility_logo)) {
                    Storage::disk('public')->delete($facility->facility_logo);
                }

                // Generate unique filename
                $filename = 'facility_logos/' . time() . '_' . $facilityId . '.' . $logoFile->getClientOriginalExtension();

                // Store the file
                $logoPath = $logoFile->storeAs('facility_logos', basename($filename), 'public');

                // Update facility record
                $facility->facility_logo = $logoPath;
                $facility->updated_by = $user->id;
                $facility->save();

                return response()->json([
                    'success' => true,
                    'message' => 'Facility logo uploaded successfully',
                    'data' => [
                        'facility_id' => $facilityId,
                        'logo_path' => $logoPath,
                        'logo_url' => Storage::disk('public')->url($logoPath)
                    ]
                ], 200);
            }

            return response()->json([
                'success' => false,
                'message' => 'No logo file provided'
            ], 400);
        } catch (\Exception $e) {
            Log::error('Error uploading facility logo', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->except(['logo']) // Exclude file from logging
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to upload facility logo. Please try again.'
            ], 500);
        }
    }

    public function uploadFacilityCoverImage(Request $request)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Validate the request data
            $validator = Validator::make($request->all(), [
                'facility_id' => 'required|integer|exists:facilities,id',
                'cover_image' => 'required|image|mimes:jpeg,png,jpg,gif|max:5120', // Max 5MB for cover images
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $facilityId = $request->input('facility_id');

            // Check if facility belongs to the authenticated user
            $facility = Facility::where('id', $facilityId)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found or unauthorized'
                ], 404);
            }

            // Handle file upload
            if ($request->hasFile('cover_image')) {
                $coverImageFile = $request->file('cover_image');

                // Delete old cover image if exists
                if ($facility->facility_cover_image && Storage::disk('public')->exists($facility->facility_cover_image)) {
                    Storage::disk('public')->delete($facility->facility_cover_image);
                }

                // Generate unique filename
                $filename = 'facility_cover_images/' . time() . '_' . $facilityId . '.' . $coverImageFile->getClientOriginalExtension();

                // Store the file
                $coverImagePath = $coverImageFile->storeAs('facility_cover_images', basename($filename), 'public');

                // Update facility record
                $facility->facility_cover_image = $coverImagePath;
                $facility->updated_by = $user->id;
                $facility->save();

                return response()->json([
                    'success' => true,
                    'message' => 'Facility cover image uploaded successfully',
                    'data' => [
                        'facility_id' => $facilityId,
                        'cover_image_path' => $coverImagePath,
                        'cover_image_url' => Storage::disk('public')->url($coverImagePath)
                    ]
                ], 200);
            }

            return response()->json([
                'success' => false,
                'message' => 'No cover image file provided'
            ], 400);
        } catch (\Exception $e) {
            Log::error('Error uploading facility cover image', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->except(['cover_image']) // Exclude file from logging
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to upload facility cover image. Please try again.'
            ], 500);
        }
    }


    public function deleteFacility($id)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $facility = Facility::where('id', $id)
                ->where('created_by', $user->id)
                ->first();

            if (!$facility) {
                return response()->json([
                    'success' => false,
                    'message' => 'Facility not found or unauthorized'
                ], 404);
            }

            // Use database transaction to ensure data consistency
            DB::beginTransaction();

            try {
                // Delete facility specialties first (foreign key constraint)
                FacilitySpeciality::where('facility_id', $id)->delete();

                // Delete uploaded images from storage
                if ($facility->facility_logo && Storage::disk('public')->exists($facility->facility_logo)) {
                    Storage::disk('public')->delete($facility->facility_logo);
                }

                if ($facility->facility_cover_image && Storage::disk('public')->exists($facility->facility_cover_image)) {
                    Storage::disk('public')->delete($facility->facility_cover_image);
                }

                // Delete the facility
                $facility->delete();

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Facility deleted successfully'
                ], 200);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Exception $e) {
            Log::error('Error deleting facility', [
                'error' => $e->getMessage(),
                'facility_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete facility. Please try again.'
            ], 500);
        }
    }

    /**
     * Public search for facilities (similar to doctor search)
     */
    public function searchFacilities(Request $request)
    {
        try {
            $location = $request->input('location');
            $specialty = $request->input('specialty');
            $symptoms = $request->input('symptoms', []);
            $conditions = $request->input('diseases', []); // Using 'diseases' for consistency with doctor search

            Log::info('Facility search request', [
                'location' => $location,
                'specialty' => $specialty,
                'symptoms' => $symptoms,
                'conditions' => $conditions
            ]);

            $query = Facility::with(['specialties', 'facilityType', 'facilityLevel', 'insurances'])
                ->where('is_active', 1);

            // Filter by location
            if ($location) {
                $query->where('facility_location', 'LIKE', "%{$location}%");
            }

            // Filter by specialty
            if ($specialty) {
                $query->whereHas('specialties', function($q) use ($specialty) {
                    $q->where('specialization_name', $specialty);
                });
            }

            // If no specialty is specified but symptoms/conditions are provided,
            // use database mapping to suggest appropriate specialties
            if (!$specialty && (!empty($symptoms) || !empty($conditions))) {
                $suggestedSpecialties = $this->getSpecialtiesFromDatabase($symptoms, $conditions);
                if (!empty($suggestedSpecialties)) {
                    $query->whereHas('specialties', function($q) use ($suggestedSpecialties) {
                        $q->whereIn('specialization_name', $suggestedSpecialties);
                    });
                }
            }

            $facilities = $query->orderBy('facility_name')->get();

            Log::info('Facility search results', [
                'count' => $facilities->count(),
                'facilities' => $facilities->pluck('facility_name')->toArray()
            ]);

            return response()->json([
                'success' => true,
                'data' => $facilities,
                'search_criteria' => [
                    'location' => $location,
                    'specialty' => $specialty,
                    'symptoms' => $symptoms,
                    'conditions' => $conditions,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Facility search error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error searching facilities',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all approved facilities (public access)
     */
    public function getApprovedFacilities(Request $request)
    {
        try {
            $query = Facility::with(['specialties', 'facilityType', 'facilityLevel', 'insurances'])
                ->where('is_active', 1);

            // Add search functionality
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('facility_name', 'LIKE', "%{$search}%")
                        ->orWhere('facility_location', 'LIKE', "%{$search}%");
                });
            }

            // Add pagination support
            $perPage = $request->input('per_page', 10);
            $facilities = $query->orderBy('facility_name')->paginate($perPage);

            // Add rating statistics to each facility
            $facilitiesWithRatings = $facilities->getCollection()->map(function ($facility) {
                $ratingStats = $this->calculateFacilityRatingStats($facility->id);
                $facility->average_rating = $ratingStats['average_rating'];
                $facility->total_ratings = $ratingStats['total_ratings'];
                return $facility;
            });

            $facilities->setCollection($facilitiesWithRatings);

            return response()->json([
                'success' => true,
                'data' => $facilities->items(),
                'pagination' => [
                    'current_page' => $facilities->currentPage(),
                    'total_pages' => $facilities->lastPage(),
                    'total' => $facilities->total(),
                    'per_page' => $facilities->perPage(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching approved facilities: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching facilities'
            ], 500);
        }
    }

    public function getPublicFacility($id)
    {
        try {
            $facility = Facility::with(['specialties', 'facilityType', 'facilityLevel', 'insurances'])
                ->where('id', $id)
                ->where('is_active', 1)
                ->first();

            if (!$facility) {
                return response()->json(['success' => false, 'message' => 'Facility not found'], 404);
            }

            $ratingStats = $this->calculateFacilityRatingStats($facility->id);
            $facility->average_rating = $ratingStats['average_rating'];
            $facility->total_ratings  = $ratingStats['total_ratings'];

            return response()->json(['success' => true, 'data' => $facility]);
        } catch (\Exception $e) {
            Log::error('Error fetching public facility: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Error fetching facility'], 500);
        }
    }

    /**
     * Calculate rating statistics for a facility
     */
    private function calculateFacilityRatingStats($facilityId)
    {
        $ratings = DB::table('ratings')
            ->where('rateable_type', 'App\\Models\\Facility')
            ->where('rateable_id', $facilityId);

        $totalRatings = $ratings->count();
        $averageRating = $totalRatings > 0 ? $ratings->avg('overall_rating') : 0;

        return [
            'total_ratings' => $totalRatings,
            'average_rating' => round($averageRating, 2),
        ];
    }

    /**
     * Get specialties from database using symptom-to-specialization mappings
     */
    private function getSpecialtiesFromDatabase($symptoms, $conditions)
    {
        $specialtyNames = [];

        // Get specializations from symptoms
        if (!empty($symptoms)) {
            $symptomSpecializations = Symptom::whereIn('name', $symptoms)
                ->with(['specializations' => function($query) {
                    $query->where('specializations.is_active', 1)
                          ->orderBy('symptom_specialization_mappings.priority', 'desc');
                }])
                ->get()
                ->pluck('specializations')
                ->flatten()
                ->pluck('specialization_name')
                ->toArray();

            $specialtyNames = array_merge($specialtyNames, $symptomSpecializations);
        }

        // Get specializations from conditions
        if (!empty($conditions)) {
            $conditionSpecializations = Condition::whereIn('name', $conditions)
                ->with(['specializations' => function($query) {
                    $query->where('specializations.is_active', 1)
                          ->orderBy('condition_specialization_mappings.priority', 'desc');
                }])
                ->get()
                ->pluck('specializations')
                ->flatten()
                ->pluck('specialization_name')
                ->toArray();

            $specialtyNames = array_merge($specialtyNames, $conditionSpecializations);
        }

        // Remove duplicates and return
        return array_unique($specialtyNames);
    }

    /**
     * Get all active facility types (public access)
     */
    public function getFacilityTypes()
    {
        try {
            $facilityTypes = \App\Models\FacilityType::active()
                ->ordered()
                ->get();

            return response()->json([
                'success' => true,
                'data' => $facilityTypes
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching facility types: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching facility types'
            ], 500);
        }
    }

    /**
     * Get all active facility levels (public access)
     */
    public function getFacilityLevels()
    {
        try {
            $facilityLevels = \App\Models\FacilityLevel::active()
                ->ordered()
                ->get();

            return response()->json([
                'success' => true,
                'data' => $facilityLevels
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching facility levels: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching facility levels'
            ], 500);
        }
    }

    /**
     * Get all active insurances (public access)
     */
    public function getInsurances()
    {
        try {
            $insurances = \App\Models\Insurance::active()
                ->ordered()
                ->get();

            return response()->json([
                'success' => true,
                'data' => $insurances
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching insurances: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching insurances'
            ], 500);
        }
    }
}
