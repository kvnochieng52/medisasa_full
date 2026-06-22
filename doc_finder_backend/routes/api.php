<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BlogController;
use App\Http\Controllers\Api\FacilityController;
use App\Http\Controllers\Api\GroupController;
use App\Http\Controllers\Api\MedicineController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ShoppingCartController;
use App\Http\Controllers\Api\SpecializationController;
use App\Http\Controllers\Api\MedicalProductController;
use App\Http\Controllers\Api\DoctorFinderController;
use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\DoctorFavoriteController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\TestController;
use App\Http\Controllers\Api\SymptomsController;
use App\Http\Controllers\Api\ConditionsController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\PharmacyOrderController;
use App\Http\Controllers\Api\MentalHealthMaterialController;
use App\Http\Controllers\Api\MentalHealthPurchaseController;
use App\Http\Controllers\Api\DepressionScreeningController;
use App\Http\Controllers\Api\SurveyController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ServiceProviderController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
//     return $request->user();
// });

Route::middleware(['api'])->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/verify-email', [AuthController::class, 'VerifyEmail']);
    Route::post('/send-reset-code', [AuthController::class, 'sendResetCode']);
    Route::post('/verify-reset-code', [AuthController::class, 'verifyResetCode']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);

    Route::get('/service-provider/{userId}', [ServiceProviderController::class, 'getServiceProviderProfile']);

    Route::middleware('auth:sanctum')->group(function () {

        // Mental health materials (auth write)
        Route::post('/mental-health-materials', [MentalHealthMaterialController::class, 'store']);
        Route::put('/mental-health-materials/{id}', [MentalHealthMaterialController::class, 'update']);
        Route::delete('/mental-health-materials/{id}', [MentalHealthMaterialController::class, 'destroy']);
        // Mental health purchases (auth)
        Route::post('/mental-health-materials/{id}/purchase', [MentalHealthPurchaseController::class, 'initiate']);
        Route::get('/mental-health-purchases/my', [MentalHealthPurchaseController::class, 'myPurchases']);
        Route::get('/depression-screenings/history', [DepressionScreeningController::class, 'userHistory']);
        // Surveys (auth-only)
        Route::post('/surveys', [SurveyController::class, 'store']);
        Route::put('/surveys/{id}', [SurveyController::class, 'update']);
        Route::delete('/surveys/{id}', [SurveyController::class, 'destroy']);
        Route::get('/admin/surveys', [SurveyController::class, 'adminIndex']);
        Route::get('/admin/surveys/{id}', [SurveyController::class, 'adminShow']);

        // Admin: user management
        Route::get('/admin/users', [\App\Http\Controllers\Api\AdminUserController::class, 'index']);
        Route::get('/admin/users/specializations', [\App\Http\Controllers\Api\AdminUserController::class, 'specializations']);
        Route::get('/admin/users/{id}', [\App\Http\Controllers\Api\AdminUserController::class, 'show']);
        Route::post('/admin/users', [\App\Http\Controllers\Api\AdminUserController::class, 'store']);
        Route::put('/admin/users/{id}', [\App\Http\Controllers\Api\AdminUserController::class, 'update']);
        Route::delete('/admin/users/{id}', [\App\Http\Controllers\Api\AdminUserController::class, 'destroy']);
        Route::patch('/admin/users/{id}/toggle-status', [\App\Http\Controllers\Api\AdminUserController::class, 'toggleStatus']);
        Route::patch('/admin/users/{id}/approve', [\App\Http\Controllers\Api\AdminUserController::class, 'approveServiceProvider']);
        Route::patch('/admin/users/{id}/decline', [\App\Http\Controllers\Api\AdminUserController::class, 'declineServiceProvider']);
        Route::get('/admin/user-documents/{id}/url', [\App\Http\Controllers\Api\AdminUserController::class, 'documentUrl']);
        Route::get('/my-survey-responses', [SurveyController::class, 'myResponses']);

        Route::get('/user-profile', [ProfileController::class, 'userProfile']);
        Route::post('/upload-profile-image', [ProfileController::class, 'uploadProfileImage']);
        Route::post('/switch-account-type', [ProfileController::class, 'switchAccountType']);


        Route::post('/save-service-provider-details', [ServiceProviderController::class, 'saveServiceProviderDetails']);
        Route::post('/upload-user-document', [ServiceProviderController::class, 'uploadUserDocument']);
        // Route::get('/user-profile', [ServiceProviderController::class, 'getUserProfile']);
        Route::delete('/user-document/{documentId}', [ServiceProviderController::class, 'deleteUserDocument']);


        Route::post('/save-basic-details', [ProfileController::class, 'saveBasicDetails']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/user', [AuthController::class, 'user']);


        Route::post('/save-facility', [FacilityController::class, 'saveFacility']);
        Route::post('/save-facility-specialties', [FacilityController::class, 'saveFacilitySpecialties']);
        Route::post('/upload-facility-logo', [FacilityController::class, 'uploadFacilityLogo']);
        Route::post('/upload-facility-cover-image', [FacilityController::class, 'uploadFacilityCoverImage']);
        Route::get('/facilities', [FacilityController::class, 'getFacilities']);
        Route::get('/facilities/{id}', [FacilityController::class, 'getFacility']);
        Route::put('/facilities/{id}', [FacilityController::class, 'updateFacility']);
        Route::delete('/facilities/{id}', [FacilityController::class, 'deleteFacility']);


        Route::get('/specializations/active-for-facility', [SpecializationController::class, 'getActiveForFacility']);
        Route::get('/specializations', [SpecializationController::class, 'getSpecializations']);

        Route::get('/group-categories', [GroupController::class, 'getCategories']);

        // Get subcategories by category_id
        Route::get('/group-subcategories', [GroupController::class, 'getSubCategories']);

        // Create group with categories in one call
        Route::post('/groups', [GroupController::class, 'createGroup']);
        Route::get('/groups', [GroupController::class, 'getUserGroups']);

        // Image uploads
        Route::post('/upload-group-image', [GroupController::class, 'uploadGroupImage']);
        Route::post('/upload-group-cover-image', [GroupController::class, 'uploadGroupCoverImage']);

        // Get group details
        Route::get('/groups/{groupId}', [GroupController::class, 'getGroupDetails']);

        // Legacy routes (keeping for backward compatibility)
        Route::get('/active-categories', [GroupController::class, 'getActiveCategories']);
        Route::get('/categories/{categoryId}/subcategories', [GroupController::class, 'getCategorySubcategories']);
        Route::post('/groups/save', [GroupController::class, 'saveGroup']);
        Route::post('/groups/categories', [GroupController::class, 'saveGroupCategories']);

        // Just for testing

        Route::delete('/groups/{groupId}', [GroupController::class, 'deleteGroup']);

        // Image upload endpoints
        Route::post('/upload-group-image', [GroupController::class, 'uploadGroupImage']);
        Route::post('/upload-group-cover-image', [GroupController::class, 'uploadGroupCoverImage']);

        // =============================================================================
        // LEGACY ROUTES (For backward compatibility)
        // =============================================================================

        // Legacy category routes
        Route::get('/active-categories', [GroupController::class, 'getActiveCategories']);
        Route::get('/categories/{categoryId}/subcategories', [GroupController::class, 'getCategorySubcategories']);

        // Legacy group creation (without categories)
        Route::post('/groups/save', [GroupController::class, 'saveGroup']);

        // Note: saveGroupCategories method was commented out in original controller
        // Route::post('/groups/categories', [GroupController::class, 'saveGroupCategories']);
        Route::get('/groups/{groupId}', [GroupController::class, 'getGroup']);
        Route::put('/groups/{groupId}', [GroupController::class, 'updateGroup']);





        // Create new product
        Route::post('/products', [ProductController::class, 'store']);

        // Upload product images (multiple images support)
        Route::post('/upload-product-images', [ProductController::class, 'uploadProductImages']);

        // Get user's products
        Route::get('/my-products', [ProductController::class, 'userProducts']);

        // Update specific product
        Route::put('/products/{id}', [ProductController::class, 'update']);
        Route::patch('/products/{id}', [ProductController::class, 'update']);

        // Delete specific product
        Route::delete('/products/{id}', [ProductController::class, 'destroy']);

        // Delete specific product image
        Route::delete('/product-images/{imageId}', [ProductController::class, 'deleteProductImage']);

        // Blog management routes (authenticated)
        Route::post('/blogs', [BlogController::class, 'store']);
        Route::put('/blogs/{id}', [BlogController::class, 'update']);
        Route::delete('/blogs/{id}', [BlogController::class, 'destroy']);
        Route::post('/upload-blog-image', [BlogController::class, 'uploadFeaturedImage']);
        Route::get('/my-blogs', [BlogController::class, 'getUserBlogs']);

        // Medicine management routes (authenticated)
        Route::post('/medicines', [MedicineController::class, 'store']);
        Route::put('/medicines/{id}', [MedicineController::class, 'update']);
        Route::delete('/medicines/{id}', [MedicineController::class, 'destroy']);
        Route::post('/upload-medicine-image', [MedicineController::class, 'uploadImage']);

        // Shopping cart routes (authenticated)
        Route::get('/cart', [ShoppingCartController::class, 'index']);
        Route::post('/cart', [ShoppingCartController::class, 'store']);
        Route::put('/cart/{id}', [ShoppingCartController::class, 'update']);
        Route::delete('/cart/{id}', [ShoppingCartController::class, 'destroy']);
        Route::delete('/cart', [ShoppingCartController::class, 'clear']);
        Route::get('/cart/summary', [ShoppingCartController::class, 'getCartSummary']);

        // Medical products management routes (authenticated)
        Route::apiResource('medical-products', MedicalProductController::class);
        Route::get('/medical-product-categories', [MedicalProductController::class, 'getCategories']);
        Route::get('/medical-product-subcategories', [MedicalProductController::class, 'getSubcategories']);
        Route::patch('/medical-products/{id}/stock', [MedicalProductController::class, 'updateStock']);

        // Appointment management routes (authenticated)
        Route::apiResource('appointments', AppointmentController::class);
        Route::get('/doctors/{doctorId}/appointments', [AppointmentController::class, 'getDoctorAppointments']);
        Route::get('/doctors/{doctorId}/available-slots', [AppointmentController::class, 'getAvailableSlots']);
        Route::patch('/appointments/{appointmentId}/status', [AppointmentController::class, 'updateStatus']);

        // Doctor favorites routes (authenticated)
        Route::get('/doctor-favorites', [DoctorFavoriteController::class, 'index']);
        Route::post('/doctor-favorites', [DoctorFavoriteController::class, 'store']);
        Route::delete('/doctor-favorites/{doctorId}', [DoctorFavoriteController::class, 'destroy']);
        Route::get('/doctor-favorites/{doctorId}/check', [DoctorFavoriteController::class, 'check']);
        Route::post('/doctor-favorites/toggle', [DoctorFavoriteController::class, 'toggle']);

        // Rating system routes (authenticated)
        Route::post('/ratings', [RatingController::class, 'store']);
        Route::get('/ratings/{type}/{id}', [RatingController::class, 'show']);
        Route::get('/my-ratings', [RatingController::class, 'userRatings']);
        Route::get('/top-rated-doctors', [RatingController::class, 'topRatedDoctors']);

        // Subscription routes (authenticated)
        Route::get('/subscription/status', [SubscriptionController::class, 'status']);
        Route::get('/subscription/details', [SubscriptionController::class, 'details']);
        Route::post('/subscription/payment', [SubscriptionController::class, 'initiatePayment']);
        Route::get('/subscription/verify-payment/{transToken}', [SubscriptionController::class, 'verifyPayment']);
        Route::post('/subscription/cancel', [SubscriptionController::class, 'cancel']);
    });

    // =============================================================================
    // PUBLIC ROUTES (if needed for browsing groups)
    // =============================================================================

    // Public routes for browsing groups (optional)
    Route::get('/public-groups', [GroupController::class, 'getPublicGroups']);
    Route::get('/public-groups/{groupId}', [GroupController::class, 'getPublicGroupDetails']);
    
    // Pharmacy orders
    Route::post('/pharmacy-orders', [PharmacyOrderController::class, 'store']);
    Route::get('/pharmacy-orders/verify/{transToken}', [PharmacyOrderController::class, 'verify']);

    // Blog routes (public access)
    Route::get('/blogs', [BlogController::class, 'index']);
    Route::get('/blogs/trending', [BlogController::class, 'trending']);
    Route::get('/blogs/featured', [BlogController::class, 'featured']);
    Route::get('/blogs/latest-trends', [BlogController::class, 'latestTrends']);
    Route::get('/blogs/tags', [BlogController::class, 'tags']);
    Route::get('/blogs/{slug}', [BlogController::class, 'show']);

    // Medicine routes (public access for pharmacy view)
    Route::get('/medicines', [MedicineController::class, 'index']);
    Route::get('/medicines/{id}', [MedicineController::class, 'show']);
    Route::get('/medicine-categories', [MedicineController::class, 'getCategories']);
    Route::get('/medicine-categories/{categoryId}/subcategories', [MedicineController::class, 'getSubcategories']);

    // Medical products routes (public access for pharmacy view)
    Route::get('/public-medical-products', [MedicalProductController::class, 'index']);
    Route::get('/public-medical-products/{id}', [MedicalProductController::class, 'show']);
    Route::get('/public-medical-product-categories', [MedicalProductController::class, 'getCategories']);
    Route::get('/public-medical-product-subcategories', [MedicalProductController::class, 'getSubcategories']);

    // Test routes (public access)
    Route::get('/test/health', [TestController::class, 'healthCheck']);
    Route::post('/test/echo', [TestController::class, 'echo']);

    // Doctor finder routes (public access)
    Route::post('/doctor-finder/chat', [DoctorFinderController::class, 'conversationalSearch']);
    Route::get('/doctors/approved', [DoctorFinderController::class, 'getApprovedDoctors']);
    Route::post('/doctors/search', [DoctorFinderController::class, 'searchDoctors']);
    Route::post('/appointments/book', [AppointmentController::class, 'store']);
    Route::get('/doctors/{doctorId}/available-slots', [AppointmentController::class, 'getAvailableSlots']);

    // Symptoms and conditions routes (public access)
    Route::get('/symptoms', [SymptomsController::class, 'index']);
    Route::get('/symptoms/{id}', [SymptomsController::class, 'show']);
    Route::post('/symptoms/related-specializations', [SymptomsController::class, 'getRelatedSpecializations']);
    Route::get('/conditions', [ConditionsController::class, 'index']);
    Route::get('/conditions/{id}', [ConditionsController::class, 'show']);
    Route::post('/conditions/related-specializations', [ConditionsController::class, 'getRelatedSpecializations']);

    // Subscription plans (public)
    Route::get('/subscription/plans', [SubscriptionController::class, 'plans']);

    // Facility finder routes (public access) - moved above auth routes to avoid conflicts
    // Mental health (public)
    Route::get('/mental-health-materials', [MentalHealthMaterialController::class, 'index']);
    Route::get('/mental-health-materials/{id}', [MentalHealthMaterialController::class, 'show']);
    Route::get('/mental-health-purchases/verify/{transToken}', [MentalHealthPurchaseController::class, 'verify']);
    Route::post('/depression-screenings', [DepressionScreeningController::class, 'store']);
    // Surveys (public)
    Route::get('/surveys', [SurveyController::class, 'index']);
    Route::get('/surveys/{id}', [SurveyController::class, 'show']);
    Route::get('/surveys/slug/{slug}', [SurveyController::class, 'showBySlug']);
    Route::post('/surveys/{id}/respond', [SurveyController::class, 'respond']);
    Route::get('/surveys/{id}/materials', [MentalHealthMaterialController::class, 'bySurvey']);

    Route::get('/public-facilities/approved', [FacilityController::class, 'getApprovedFacilities']);
    Route::get('/public-facilities/{id}', [FacilityController::class, 'getPublicFacility']);
    Route::post('/public-facilities/search', [FacilityController::class, 'searchFacilities']);
    Route::get('/facility-types', [FacilityController::class, 'getFacilityTypes']);
    Route::get('/facility-levels', [FacilityController::class, 'getFacilityLevels']);
    Route::get('/insurances', [FacilityController::class, 'getInsurances']);

    // Support group finder routes (public access)
    Route::get('/support-groups/public', [GroupController::class, 'getPublicGroups']);
    Route::post('/support-groups/search', [GroupController::class, 'searchGroups']);
    Route::get('/support-groups/categories', [GroupController::class, 'getCategories']);
});
