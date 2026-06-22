<?php

namespace App\Helpers;

class CalendarHelper
{
    /**
     * Generate ICS calendar file content
     */
    public static function generateICS($title, $startTime, $endTime, $description, $location)
    {
        return "BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:$title
DESCRIPTION:$description
DTSTART:" . date("Ymd\THis", strtotime($startTime)) . "
DTEND:" . date("Ymd\THis", strtotime($endTime)) . "
LOCATION:$location
END:VEVENT
END:VCALENDAR";
    }

    /**
     * Check if email is a Gmail address
     */
    public static function isGmail($email)
    {
        return stripos($email, '@gmail.com') !== false;
    }

    /**
     * Create a Google Calendar link
     */
    public static function createGoogleCalendarLink($title, $description, $location, $startTime, $endTime)
    {
        return "https://www.google.com/calendar/render?action=TEMPLATE" .
            "&text=" . urlencode($title) .
            "&details=" . urlencode($description) .
            "&location=" . urlencode($location) .
            "&dates=" . gmdate("Ymd\THis\Z", strtotime($startTime)) .
            "/" . gmdate("Ymd\THis\Z", strtotime($endTime));
    }

    /**
     * Generate calendar link for appointment based on email type
     */
    public static function generateAppointmentCalendarLink($appointment, $userType = 'patient')
    {
        $title = "Appointment with " . ($userType === 'patient' ? "Dr. {$appointment->doctor->name}" : $appointment->patient_name);
        $description = "Appointment Details:\n" .
                      "Type: " . ucfirst(str_replace('_', ' ', $appointment->consultation_type)) . " Consultation\n" .
                      "Date: " . date('F j, Y', strtotime($appointment->appointment_date)) . "\n" .
                      "Time: " . date('g:i A', strtotime($appointment->appointment_time));

        $location = $appointment->consultation_type === 'in_person'
            ? ($appointment->doctor->clinic_address ?? 'Clinic Address')
            : 'Online Consultation';

        $startDateTime = $appointment->appointment_date . ' ' . $appointment->appointment_time;
        $endDateTime = date("Y-m-d H:i:s", strtotime("+30 minutes", strtotime($startDateTime)));

        $email = $userType === 'patient' ? $appointment->patient_email : $appointment->doctor->email;

        if (self::isGmail($email)) {
            return self::createGoogleCalendarLink(
                $title,
                $description,
                $location,
                $startDateTime,
                $endDateTime
            );
        } else {
            // For non-Gmail users, we'll create a download link for ICS file
            return route('download-calendar-event', [
                'title' => $title,
                'description' => $description,
                'startTime' => $startDateTime,
                'endTime' => $endDateTime,
                'location' => $location,
            ]);
        }
    }
}