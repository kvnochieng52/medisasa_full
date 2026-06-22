<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Specialization;
use App\Models\User;
use App\Models\UserDocuments;
use App\Models\UserSpecialization;
use App\Services\SubscriptionLimitService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{


    public function updateUserProfile(Request $request) {}


    public function uploadProfileImage(Request $request)
    {
        try {
            // Validate the incoming request
            $request->validate([
                'profile_image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // Max 2MB
                'user_id' => 'required|integer|exists:users,id'
            ]);

            $userId = $request->input('user_id');

            // Find the user
            $user = User::findOrFail($userId);

            // Get the uploaded file
            $file = $request->file('profile_image');

            // Delete old profile image if exists
            if ($user->profile_image) {
                Storage::disk('public')->delete($user->profile_image);
            }

            // Generate unique filename
            $filename = 'profile_' . $userId . '_' . time() . '.' . $file->getClientOriginalExtension();

            // Store the file in public disk under 'profile_images' directory
            $path = $file->storeAs('profile_images', $filename, 'public');

            // Update user's profile image path in database
            $user->profile_image = $path;
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Profile image uploaded successfully',
                'data' => [
                    'profile_image_url' => Storage::url($path),
                    'profile_image_path' => $path
                ]
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'error' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            // Log the error for debugging
            Log::error('Profile image upload failed: ' . $e->getMessage(), [
                'user_id' => $request->input('user_id'),
                'file_info' => $request->hasFile('profile_image') ? [
                    'name' => $request->file('profile_image')->getClientOriginalName(),
                    'size' => $request->file('profile_image')->getSize()
                ] : null
            ]);

            return response()->json([
                'success' => false,
                'error' => 'Failed to upload profile image'
            ], 500);
        }
    }


    public function saveBasicDetails(Request $request)
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
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email,' . $user->id,
                'telephone' => 'required|string|max:20',
                'idNumber' => 'required|string|max:50',
                'address' => 'required|string|max:500',
                'dateOfBirth' => 'required|date',
                'userType' => 'required|in:user,serviceProvider',

            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Map userType to account_type integer
            $accountType = $request->userType === 'user' ? 1 : 2;

            // Update user details
            $user->update([
                'name' => $request->name,
                'email' => $request->email,
                'telephone' => $request->telephone,
                'id_number' => $request->idNumber,
                'address' => $request->address,
                'dob' => $request->dateOfBirth,
                'account_type' => $accountType,
                'first_login' => 0,
            ]);

            Log::info('User basic details updated successfully', [
                'user_id' => $user->id,
                'updated_fields' => $request->only(['name', 'email', 'telephone', 'idNumber', 'address', 'dateOfBirth', 'userType'])
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Basic details saved successfully',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'telephone' => $user->telephone,
                        'id_number' => $user->id_number,
                        'address' => $user->address,
                        'dob' => $user->dob,
                        'account_type' => $user->account_type,
                        'profile_image' => $user->profile_image,
                    ]
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error saving basic details', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->all()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to save basic details. Please try again.'
            ], 500);
        }
    }



    public function switchAccountType(Request $request)
    {
        try {
            $user = auth()->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Validate the request
            $validator = Validator::make($request->all(), [
                'account_type' => 'required|integer|in:1,2'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid account type',
                    'errors' => $validator->errors()
                ], 422);
            }

            $newAccountType = $request->account_type;

            // Prevent admins from switching (account_type 3)
            if ($user->account_type == 3) {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin accounts cannot switch roles'
                ], 403);
            }

            // Only allow approved service providers to switch
            // if (!($user->account_type == 2 && $user->sp_approved == 1)) {
            //     return response()->json([
            //         'success' => false,
            //         'message' => 'Only approved service providers can switch account types'
            //     ], 403);
            // }

            // Store original sp_approved value
            $originalSpApproved = $user->sp_approved;

            // Log current state before update
            Log::info('Before account type switch', [
                'user_id' => $user->id,
                'current_account_type' => $user->account_type,
                'current_sp_approved' => $user->sp_approved,
                'new_account_type' => $newAccountType
            ]);

            // Update using explicit database query to avoid any model events
            DB::table('users')
                ->where('id', $user->id)
                ->update([
                    'account_type' => $newAccountType,
                    //  'sp_approved' => $originalSpApproved, // Explicitly preserve the value
                    'updated_at' => now()
                ]);

            // Refresh user model to get updated data
            $user->refresh();

            Log::info('After account type switch', [
                'user_id' => $user->id,
                'updated_account_type' => $user->account_type,
                'updated_sp_approved' => $user->sp_approved,
                'sp_approved_preserved' => $user->sp_approved == $originalSpApproved
            ]);

            // Revoke all tokens to force re-login
            $user->tokens()->delete();

            return response()->json([
                'success' => true,
                'message' => 'Account type switched successfully. Please log in again.',
                'data' => [
                    'account_type' => $newAccountType,
                    'account_type_name' => $newAccountType == 1 ? 'Standard User' : 'Service Provider'
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error switching account type', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'request_data' => $request->all()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to switch account type. Please try again.'
            ], 500);
        }
    }

    public function userProfile(Request $request)
    {
        try {
            $user = auth()->user();

            // Attach subscription info for service providers
            $subscriptionInfo = null;
            $subscriptionPaid = 0;

            if ($user->account_type == 2) {
                $limitService    = app(SubscriptionLimitService::class);
                $subscriptionInfo = $limitService->getSubscriptionInfo($user);
                $subscriptionPaid = $subscriptionInfo ? 1 : 0;
            }

            // Merge subscription_paid into user array for backward compatibility
            $userData                     = $user->toArray();
            $userData['subscription_paid'] = $subscriptionPaid;

            return response()->json([
                'success' => true,
                'data' => [
                    'user'                => $userData,
                    'subscription'        => $subscriptionInfo,
                    'specializations'     => Specialization::where('is_active', 1)->get(),
                    'user_specializations'=> UserSpecialization::where('user_id', $user->id)->get(),
                    'user_ids'            => UserDocuments::where([
                        'user_id'       => $user->id,
                        'document_type' => 'id'
                    ])->get(),
                    'user_documents'      => UserDocuments::where([
                        'user_id'       => $user->id,
                        'document_type' => 'certificate'
                    ])->get(),
                ]
            ], 200);
        } catch (\Exception $e) {
            // Log the error
            Log::error('Error in userProfile: ' . $e->getMessage(), [
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'An unexpected error occurred. Please try again later.'
            ], 500);
        }
    }
}
