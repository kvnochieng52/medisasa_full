<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\PaymentCallbackController;
use App\Models\User;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

// DPO Pay payment callback routes (no auth — DPO redirects here after payment)
Route::get('/payment/callback', [PaymentCallbackController::class, 'handleCallback'])->name('payment.callback');
Route::get('/payment/cancel', [PaymentCallbackController::class, 'handleCancel'])->name('payment.cancel');

// Dev-only: simulated payment success page (shown in the new tab opened by the frontend)
if (app()->environment('local')) {
    Route::get('/payment/dev-success', function () {
        return response('<html><head><title>Dev Payment</title></head><body style="font-family:sans-serif;text-align:center;padding:60px;background:#f0fdf4">
            <div style="max-width:400px;margin:0 auto;background:white;border-radius:12px;padding:40px;box-shadow:0 4px 20px rgba(0,0,0,.08)">
                <div style="font-size:56px;margin-bottom:16px">✅</div>
                <h2 style="color:#16a34a;margin:0 0 8px">Dev Payment Simulated</h2>
                <p style="color:#6b7280;margin:0">Your subscription has been activated. Switch back to the app tab — it will confirm automatically.</p>
                <p style="color:#9ca3af;font-size:12px;margin-top:24px">APP_ENV=local bypass · No real payment was processed</p>
            </div>
        </body></html>', 200, ['Content-Type' => 'text/html']);
    });
}

// Route::get(
//     '/test',
//     // function () {
//     //     $user = User::get();
//     //     dd($user);
//     // }
// );


// Main route - redirect to dashboard if authenticated, otherwise to login
Route::get('/', [App\Http\Controllers\HomeController::class, 'index'])->middleware('auth')->name('dashboard');

// Authentication Routes
Route::get('login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('login', [AuthController::class, 'login']);
Route::post('logout', [AuthController::class, 'logout'])->name('logout');

// Register routes (if needed)
Auth::routes(['register' => false, 'login' => false, 'logout' => false]);

Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');

// Admin Routes
Route::prefix('admin')->name('admin.')->middleware(['auth'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::resource('blogs', App\Http\Controllers\Admin\BlogController::class);

    // User Management Routes
    Route::resource('users', App\Http\Controllers\Admin\UserController::class);
    Route::patch('users/{user}/toggle-status', [App\Http\Controllers\Admin\UserController::class, 'toggleStatus'])->name('users.toggleStatus');
    Route::patch('users/{user}/approve', [App\Http\Controllers\Admin\UserController::class, 'approveServiceProvider'])->name('users.approve');
    Route::patch('users/{user}/decline', [App\Http\Controllers\Admin\UserController::class, 'declineServiceProvider'])->name('users.decline');
    Route::get('users/documents/{document}/download', [App\Http\Controllers\Admin\UserController::class, 'downloadDocument'])->name('users.documents.download');
    Route::get('users/documents/{document}/view', [App\Http\Controllers\Admin\UserController::class, 'viewDocument'])->name('users.documents.view');
});

// Calendar download route
Route::get('/download-calendar-event', function (Illuminate\Http\Request $request) {
    $title = $request->get('title', 'Appointment');
    $description = $request->get('description', '');
    $startTime = $request->get('startTime');
    $endTime = $request->get('endTime');
    $location = $request->get('location', '');

    $icsContent = App\Helpers\CalendarHelper::generateICS(
        $title,
        $startTime,
        $endTime,
        $description,
        $location
    );

    $filename = 'appointment-' . date('Y-m-d-H-i-s') . '.ics';

    return response($icsContent)
        ->header('Content-Type', 'text/calendar')
        ->header('Content-Disposition', 'attachment; filename="' . $filename . '"');
})->name('download-calendar-event');

Auth::routes();

Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');
