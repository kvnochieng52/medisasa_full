<?php

namespace App\Services;

use App\Models\Appointment;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class AppointmentNotificationService
{
    /**
     * Send appointment approval notification with Google Meet link
     */
    public function sendApprovalNotification(Appointment $appointment, $meetData)
    {
        try {
            // Send email to patient
            $this->sendPatientApprovalEmail($appointment, $meetData);

            // Send email to doctor
            $this->sendDoctorApprovalEmail($appointment, $meetData);

            Log::info('Appointment approval notifications sent successfully', [
                'appointment_id' => $appointment->id,
                'doctor_email' => $appointment->doctor->email,
                'patient_email' => $appointment->patient_email
            ]);

            return ['success' => true];
        } catch (\Exception $e) {
            Log::error('Failed to send appointment approval notifications: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Send email to patient
     */
    private function sendPatientApprovalEmail(Appointment $appointment, $meetData)
    {
        $subject = "Appointment Confirmed - Dr. {$appointment->doctor->name}";

        $emailData = [
            'patient_name' => $appointment->patient_name,
            'doctor_name' => $appointment->doctor->name,
            'appointment_date' => $appointment->appointment_date->format('F j, Y'),
            'appointment_time' => $appointment->appointment_time,
            'consultation_type' => $appointment->consultation_type,
            'meet_link' => $meetData['meet_link'] ?? null,
            'notes' => $appointment->notes,
        ];

        Mail::send('emails.appointment.patient_approval', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->patient_email, $appointment->patient_name)
                    ->subject($subject);
        });
    }

    /**
     * Send email to doctor
     */
    private function sendDoctorApprovalEmail(Appointment $appointment, $meetData)
    {
        $subject = "Appointment Scheduled - {$appointment->patient_name}";

        $emailData = [
            'doctor_name' => $appointment->doctor->name,
            'patient_name' => $appointment->patient_name,
            'patient_email' => $appointment->patient_email,
            'patient_telephone' => $appointment->patient_telephone,
            'patient_location' => $appointment->patient_location,
            'appointment_date' => $appointment->appointment_date->format('F j, Y'),
            'appointment_time' => $appointment->appointment_time,
            'consultation_type' => $appointment->consultation_type,
            'meet_link' => $meetData['meet_link'] ?? null,
            'notes' => $appointment->notes,
        ];

        Mail::send('emails.appointment.doctor_approval', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->doctor->email, 'Dr. ' . $appointment->doctor->name)
                    ->subject($subject);
        });
    }

    /**
     * Send appointment cancellation notification
     */
    public function sendCancellationNotification(Appointment $appointment)
    {
        try {
            // Send cancellation email to patient
            $this->sendPatientCancellationEmail($appointment);

            // Send cancellation email to doctor
            $this->sendDoctorCancellationEmail($appointment);

            Log::info('Appointment cancellation notifications sent successfully', [
                'appointment_id' => $appointment->id
            ]);

            return ['success' => true];
        } catch (\Exception $e) {
            Log::error('Failed to send appointment cancellation notifications: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Send cancellation email to patient
     */
    private function sendPatientCancellationEmail(Appointment $appointment)
    {
        $subject = "Appointment Cancelled - Dr. {$appointment->doctor->name}";

        $emailData = [
            'patient_name' => $appointment->patient_name,
            'doctor_name' => $appointment->doctor->name,
            'appointment_date' => $appointment->appointment_date->format('F j, Y'),
            'appointment_time' => $appointment->appointment_time,
        ];

        Mail::send('emails.appointment.patient_cancellation', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->patient_email, $appointment->patient_name)
                    ->subject($subject);
        });
    }

    /**
     * Send cancellation email to doctor
     */
    private function sendDoctorCancellationEmail(Appointment $appointment)
    {
        $subject = "Appointment Cancelled - {$appointment->patient_name}";

        $emailData = [
            'doctor_name' => $appointment->doctor->name,
            'patient_name' => $appointment->patient_name,
            'appointment_date' => $appointment->appointment_date->format('F j, Y'),
            'appointment_time' => $appointment->appointment_time,
        ];

        Mail::send('emails.appointment.doctor_cancellation', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->doctor->email, 'Dr. ' . $appointment->doctor->name)
                    ->subject($subject);
        });
    }

    /**
     * Send appointment approval notification with calendar links
     */
    public function sendApprovalNotificationWithCalendar(Appointment $appointment)
    {
        try {
            // Send email to patient with calendar link
            $this->sendPatientApprovalEmailWithCalendar($appointment);

            // Send email to doctor with calendar link
            $this->sendDoctorApprovalEmailWithCalendar($appointment);

            Log::info('Appointment approval notifications with calendar links sent successfully', [
                'appointment_id' => $appointment->id,
                'doctor_email' => $appointment->doctor->email,
                'patient_email' => $appointment->patient_email
            ]);

            return ['success' => true];
        } catch (\Exception $e) {
            Log::error('Failed to send appointment approval notifications with calendar: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Send approval email to patient with calendar link
     */
    private function sendPatientApprovalEmailWithCalendar(Appointment $appointment)
    {
        $calendarLink = \App\Helpers\CalendarHelper::generateAppointmentCalendarLink($appointment, 'patient');

        $subject = 'Appointment Confirmed - ' . config('app.name');

        $emailData = [
            'patient_name' => $appointment->patient_name,
            'doctor_name' => $appointment->doctor->name,
            'appointment_date' => date('F j, Y', strtotime($appointment->appointment_date)),
            'appointment_time' => date('g:i A', strtotime($appointment->appointment_time)),
            'consultation_type' => $appointment->consultation_type,
            'notes' => $appointment->notes,
            'calendar_link' => $calendarLink,
            'is_gmail' => \App\Helpers\CalendarHelper::isGmail($appointment->patient_email)
        ];

        Mail::send('emails.appointment.patient_approval_calendar', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->patient_email, $appointment->patient_name)
                    ->subject($subject);
        });
    }

    /**
     * Send approval email to doctor with calendar link
     */
    private function sendDoctorApprovalEmailWithCalendar(Appointment $appointment)
    {
        $calendarLink = \App\Helpers\CalendarHelper::generateAppointmentCalendarLink($appointment, 'doctor');

        $subject = 'New Appointment Confirmed - ' . config('app.name');

        $emailData = [
            'doctor_name' => $appointment->doctor->name,
            'patient_name' => $appointment->patient_name,
            'appointment_date' => date('F j, Y', strtotime($appointment->appointment_date)),
            'appointment_time' => date('g:i A', strtotime($appointment->appointment_time)),
            'consultation_type' => $appointment->consultation_type,
            'notes' => $appointment->notes,
            'calendar_link' => $calendarLink,
            'is_gmail' => \App\Helpers\CalendarHelper::isGmail($appointment->doctor->email)
        ];

        Mail::send('emails.appointment.doctor_approval_calendar', $emailData, function ($message) use ($appointment, $subject) {
            $message->to($appointment->doctor->email, 'Dr. ' . $appointment->doctor->name)
                    ->subject($subject);
        });
    }
}