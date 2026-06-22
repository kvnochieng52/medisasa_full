<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
// use App\Services\GoogleMeetService; // Disabled - using calendar links instead
use App\Services\AppointmentNotificationService;
use App\Services\SubscriptionLimitService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class AppointmentController extends Controller
{
    /**
     * Create a new appointment
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'doctor_id' => 'required|exists:users,id',
                'patient_name' => 'required|string|max:255',
                'patient_email' => 'required|email|max:255',
                'patient_telephone' => 'required|string|max:20',
                'patient_location' => 'nullable|string|max:255',
                'appointment_date' => 'required|date|after_or_equal:today',
                'appointment_time' => 'required|date_format:H:i',
                'consultation_type' => 'required|in:in_person,online',
                'notes' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Check if doctor exists and is approved
            $doctor = User::where('id', $request->doctor_id)
                          ->where('account_type', 2)
                          ->where('sp_approved', 1)
                          ->where('is_active', 1)
                          ->first();

            if (!$doctor) {
                return response()->json([
                    'success' => false,
                    'message' => 'Doctor not found or not available for appointments'
                ], 404);
            }

            // Check doctor's subscription appointment limit
            $limitService = app(SubscriptionLimitService::class);
            $limitCheck   = $limitService->canReceiveAppointment($doctor);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'message' => $limitCheck['message'],
                ], 403);
            }

            // Check for conflicting appointments
            $existingAppointment = Appointment::where('doctor_id', $request->doctor_id)
                                           ->where('appointment_date', $request->appointment_date)
                                           ->where('appointment_time', $request->appointment_time)
                                           ->whereIn('status', ['pending', 'confirmed'])
                                           ->first();

            if ($existingAppointment) {
                return response()->json([
                    'success' => false,
                    'message' => 'This time slot is already booked. Please choose a different time.',
                    'response' => [
                        'message' => "I'm sorry, but Dr. {$doctor->name} already has an appointment at {$request->appointment_time} on {$request->appointment_date}. Would you like me to suggest alternative times?",
                        'type' => 'conflict',
                        'suggested_times' => $this->getSuggestedTimes($request->doctor_id, $request->appointment_date)
                    ]
                ], 409);
            }

            $appointment = Appointment::create($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Appointment booked successfully',
                'data' => $appointment->load('doctor'),
                'response' => [
                    'message' => "Great! I've successfully booked your appointment with Dr. {$doctor->name} on {$request->appointment_date} at {$request->appointment_time}. You'll receive a confirmation shortly at {$request->patient_email}.",
                    'type' => 'success',
                    'appointment_details' => [
                        'doctor' => $doctor->name,
                        'date' => $request->appointment_date,
                        'time' => $request->appointment_time,
                        'type' => $request->consultation_type,
                        'confirmation_number' => 'APT-' . str_pad($appointment->id, 6, '0', STR_PAD_LEFT)
                    ]
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error('Appointment booking error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error booking appointment',
                'response' => [
                    'message' => "I'm sorry, there was an issue booking your appointment. Please try again or contact support.",
                    'type' => 'error'
                ]
            ], 500);
        }
    }

    /**
     * Get suggested alternative times
     */
    private function getSuggestedTimes($doctorId, $date)
    {
        $allTimes = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

        $bookedTimes = Appointment::where('doctor_id', $doctorId)
                                ->where('appointment_date', $date)
                                ->whereIn('status', ['pending', 'confirmed'])
                                ->pluck('appointment_time')
                                ->map(function($time) {
                                    return date('H:i', strtotime($time));
                                })
                                ->toArray();

        $availableTimes = array_diff($allTimes, $bookedTimes);

        return array_slice(array_values($availableTimes), 0, 3);
    }

    /**
     * Get appointments for a doctor
     */
    public function getDoctorAppointments(Request $request, $doctorId)
    {
        try {
            $appointments = Appointment::where('doctor_id', $doctorId)
                                     ->with('doctor')
                                     ->orderBy('appointment_date')
                                     ->orderBy('appointment_time')
                                     ->get();

            return response()->json([
                'success' => true,
                'data' => $appointments
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching appointments'
            ], 500);
        }
    }

    /**
     * Get available time slots for a doctor on a specific date
     */
    public function getAvailableSlots(Request $request, $doctorId)
    {
        try {
            $date = $request->input('date', date('Y-m-d'));

            $allSlots = [
                '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
                '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
            ];

            $bookedSlots = Appointment::where('doctor_id', $doctorId)
                                    ->where('appointment_date', $date)
                                    ->whereIn('status', ['pending', 'confirmed'])
                                    ->pluck('appointment_time')
                                    ->map(function($time) {
                                        return date('H:i', strtotime($time));
                                    })
                                    ->toArray();

            $availableSlots = array_diff($allSlots, $bookedSlots);

            return response()->json([
                'success' => true,
                'date' => $date,
                'available_slots' => array_values($availableSlots),
                'booked_slots' => $bookedSlots
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching available slots'
            ], 500);
        }
    }

    /**
     * Update appointment status
     */
    public function updateStatus(Request $request, $appointmentId)
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:pending,confirmed,cancelled,completed'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid status'
                ], 422);
            }

            $appointment = Appointment::with('doctor')->find($appointmentId);

            if (!$appointment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Appointment not found'
                ], 404);
            }

            $oldStatus = $appointment->status;
            $newStatus = $request->status;

            // Update appointment status
            $appointment->update(['status' => $newStatus]);

            // Handle Google Meet creation when appointment is confirmed
            if ($oldStatus !== 'confirmed' && $newStatus === 'confirmed') {
                $this->handleAppointmentConfirmation($appointment);
            }

            // Handle Google Meet deletion when appointment is cancelled
            if ($newStatus === 'cancelled' && $appointment->google_meet_link) {
                $this->handleAppointmentCancellation($appointment);
            }

            return response()->json([
                'success' => true,
                'message' => 'Appointment status updated successfully',
                'data' => $appointment->fresh()->load('doctor')
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating appointment status'
            ], 500);
        }
    }

    /**
     * Get all appointments (for admin)
     */
    public function index(Request $request)
    {
        try {
            $query = Appointment::with('doctor');

            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            if ($request->has('date')) {
                $query->where('appointment_date', $request->date);
            }

            $appointments = $query->orderBy('appointment_date', 'desc')
                                 ->orderBy('appointment_time', 'desc')
                                 ->paginate(15);

            return response()->json([
                'success' => true,
                'data' => $appointments
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching appointments'
            ], 500);
        }
    }

    /**
     * Show specific appointment
     */
    public function show($appointmentId)
    {
        try {
            $appointment = Appointment::with('doctor')->find($appointmentId);

            if (!$appointment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Appointment not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $appointment
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching appointment'
            ], 500);
        }
    }

    /**
     * Handle appointment confirmation - create Google Meet and send notifications
     */
    private function handleAppointmentConfirmation(Appointment $appointment)
    {
        try {
            // Only create Google Meet for online consultations
            if ($appointment->consultation_type !== 'online') {
                Log::info('Appointment is not online consultation, skipping Google Meet creation', [
                    'appointment_id' => $appointment->id,
                    'consultation_type' => $appointment->consultation_type
                ]);
                return;
            }

            // Google Meet integration disabled - using calendar links instead
            Log::info('Creating calendar links for confirmed appointment', [
                'appointment_id' => $appointment->id,
                'doctor_id' => $appointment->doctor_id,
                'patient_email' => $appointment->patient_email
            ]);

            // TODO: Create Google Meet and calendar events (disabled for now)
            // $googleMeetService = new GoogleMeetService();
            // $meetResult = $googleMeetService->createMeetAppointment($appointment);

            // Using simple calendar link approach instead
            /*
            if ($meetResult['success']) {
                // Update appointment with Google Meet details
                $appointment->update([
                    'google_meet_link' => $meetResult['meet_link'],
                    'google_event_id' => $meetResult['main_event_id'],
                    'doctor_calendar_event_id' => $meetResult['doctor_event_id'],
                    'patient_calendar_event_id' => $meetResult['patient_event_id'],
                    'meet_created_at' => now(),
                ]);

                // Send email notifications with meet link
                $notificationService = new AppointmentNotificationService();
                $notificationResult = $notificationService->sendApprovalNotification($appointment, $meetResult);

                if ($notificationResult['success']) {
                    Log::info('Google Meet created and notifications sent successfully', [
                        'appointment_id' => $appointment->id,
                        'meet_link' => $meetResult['meet_link']
                    ]);
                } else {
                    Log::warning('Google Meet created but notification sending failed', [
                        'appointment_id' => $appointment->id,
                        'error' => $notificationResult['error'] ?? 'Unknown error'
                    ]);
                }
            } else {
                Log::error('Failed to create Google Meet for appointment', [
                    'appointment_id' => $appointment->id,
                    'error' => $meetResult['error'] ?? 'Unknown error'
                ]);
            }
            */

            // Send email notifications with calendar links
            $notificationService = new AppointmentNotificationService();
            $notificationResult = $notificationService->sendApprovalNotificationWithCalendar($appointment);

            if ($notificationResult['success']) {
                Log::info('Appointment confirmation sent successfully with calendar links', [
                    'appointment_id' => $appointment->id
                ]);
            } else {
                Log::warning('Failed to send appointment confirmation', [
                    'appointment_id' => $appointment->id,
                    'error' => $notificationResult['error'] ?? 'Unknown error'
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Error handling appointment confirmation', [
                'appointment_id' => $appointment->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Handle appointment cancellation - delete Google Meet and send notifications
     */
    private function handleAppointmentCancellation(Appointment $appointment)
    {
        try {
            Log::info('Handling appointment cancellation', [
                'appointment_id' => $appointment->id,
                'google_meet_link' => $appointment->google_meet_link
            ]);

            // Cancel Google Meet and calendar events
            if ($appointment->google_event_id) {
                $googleMeetService = new GoogleMeetService();

                $eventData = [
                    'main_event_id' => $appointment->google_event_id,
                    'doctor_event_id' => $appointment->doctor_calendar_event_id,
                    'patient_event_id' => $appointment->patient_calendar_event_id,
                    'doctor_email' => $appointment->doctor->email,
                    'patient_email' => $appointment->patient_email,
                ];

                $cancelResult = $googleMeetService->cancelMeetAppointment($eventData);

                if ($cancelResult['success']) {
                    Log::info('Google Meet cancelled successfully', [
                        'appointment_id' => $appointment->id
                    ]);
                } else {
                    Log::warning('Failed to cancel Google Meet', [
                        'appointment_id' => $appointment->id,
                        'error' => $cancelResult['error'] ?? 'Unknown error'
                    ]);
                }
            }

            // Clear Google Meet details from appointment
            $appointment->update([
                'google_meet_link' => null,
                'google_event_id' => null,
                'doctor_calendar_event_id' => null,
                'patient_calendar_event_id' => null,
                'meet_created_at' => null,
            ]);

            // Send cancellation notifications
            $notificationService = new AppointmentNotificationService();
            $notificationResult = $notificationService->sendCancellationNotification($appointment);

            if ($notificationResult['success']) {
                Log::info('Cancellation notifications sent successfully', [
                    'appointment_id' => $appointment->id
                ]);
            } else {
                Log::warning('Failed to send cancellation notifications', [
                    'appointment_id' => $appointment->id,
                    'error' => $notificationResult['error'] ?? 'Unknown error'
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Error handling appointment cancellation', [
                'appointment_id' => $appointment->id,
                'error' => $e->getMessage()
            ]);
        }
    }
}