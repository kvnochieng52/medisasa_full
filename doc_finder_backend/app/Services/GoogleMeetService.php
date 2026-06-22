<?php

namespace App\Services;

use Exception;
use Google\Client;
use Google\Service\Calendar;
use Google\Service\Calendar\Event;
use Google\Service\Calendar\EventDateTime;
use Google\Service\Calendar\ConferenceData;
use Google\Service\Calendar\CreateConferenceRequest;
use Google\Service\Calendar\ConferenceSolutionKey;
use Google\Service\Calendar\EventAttendee;
use Illuminate\Support\Facades\Log;

class GoogleMeetService
{
    private $client;
    private $calendarService;

    public function __construct()
    {
        $this->setupGoogleClient();
    }

    private function setupGoogleClient()
    {
        try {
            $this->client = new Client();

            // Check if we have OAuth2 credentials (web client) or service account
            $credentialsPath = config('services.google.calendar.credentials_path');

            if (file_exists(storage_path('app/google/oauth2_credentials.json'))) {
                // Use OAuth2 credentials with a stored refresh token
                $this->client->setAuthConfig(storage_path('app/google/oauth2_credentials.json'));
                $this->client->addScope([
                    Calendar::CALENDAR,
                    Calendar::CALENDAR_EVENTS
                ]);

                // For OAuth2, we need to handle access tokens differently
                // For now, we'll use application default credentials or stored tokens
                $this->setupOAuth2Authentication();

            } elseif (file_exists($credentialsPath)) {
                // Use service account credentials
                $this->client->setAuthConfig($credentialsPath);
                $this->client->addScope([
                    Calendar::CALENDAR,
                    Calendar::CALENDAR_EVENTS
                ]);
                $this->client->setSubject(config('services.google.admin_email'));
            } else {
                throw new Exception('No valid Google credentials found');
            }

            $this->calendarService = new Calendar($this->client);
        } catch (Exception $e) {
            Log::error('Google Client setup failed: ' . $e->getMessage());
            throw new Exception('Failed to initialize Google services: ' . $e->getMessage());
        }
    }

    private function setupOAuth2Authentication()
    {
        // For OAuth2, we need an access token
        // This is a simplified version - in production, you'd handle refresh tokens properly
        $tokenPath = storage_path('app/google/token.json');

        if (file_exists($tokenPath)) {
            $accessToken = json_decode(file_get_contents($tokenPath), true);
            $this->client->setAccessToken($accessToken);

            // Refresh the token if it's expired
            if ($this->client->isAccessTokenExpired()) {
                if ($this->client->getRefreshToken()) {
                    $this->client->fetchAccessTokenWithRefreshToken($this->client->getRefreshToken());
                    $newAccessToken = $this->client->getAccessToken();
                    file_put_contents($tokenPath, json_encode($newAccessToken));
                } else {
                    throw new Exception('No refresh token available. Please re-authenticate.');
                }
            }
        } else {
            // For automated server use, we'll create a default calendar using the client credentials
            // This requires setting up domain-wide delegation or using service account
            Log::warning('No stored access token found. OAuth2 flow needs to be completed first.');
            throw new Exception('OAuth2 authentication required. Please complete the authentication flow first.');
        }
    }

    /**
     * Create a Google Meet appointment with calendar events
     */
    public function createMeetAppointment($appointment)
    {
        try {
            // Create the calendar event with Google Meet
            $meetEvent = $this->createCalendarEvent($appointment);

            // Get the meet link from the created event
            $meetLink = $this->extractMeetLink($meetEvent);

            // Create calendar events for both doctor and patient
            $doctorEventId = $this->createDoctorCalendarEvent($appointment, $meetLink);
            $patientEventId = $this->createPatientCalendarEvent($appointment, $meetLink);

            return [
                'success' => true,
                'meet_link' => $meetLink,
                'doctor_event_id' => $doctorEventId,
                'patient_event_id' => $patientEventId,
                'main_event_id' => $meetEvent->getId()
            ];

        } catch (Exception $e) {
            Log::error('Google Meet creation failed: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Create the main calendar event with Google Meet
     */
    private function createCalendarEvent($appointment)
    {
        $startDateTime = new EventDateTime();
        $startDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time));
        $startDateTime->setTimeZone('Africa/Nairobi');

        $endDateTime = new EventDateTime();
        $endDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time, 60)); // 1 hour duration
        $endDateTime->setTimeZone('Africa/Nairobi');

        // Create attendees
        $doctorAttendee = new EventAttendee();
        $doctorAttendee->setEmail($appointment->doctor->email);
        $doctorAttendee->setDisplayName('Dr. ' . $appointment->doctor->name);

        $patientAttendee = new EventAttendee();
        $patientAttendee->setEmail($appointment->patient_email);
        $patientAttendee->setDisplayName($appointment->patient_name);

        // Create conference data for Google Meet
        $conferenceSolutionKey = new ConferenceSolutionKey();
        $conferenceSolutionKey->setType('hangoutsMeet');

        $createConferenceRequest = new CreateConferenceRequest();
        $createConferenceRequest->setRequestId(uniqid());
        $createConferenceRequest->setConferenceSolutionKey($conferenceSolutionKey);

        $conferenceData = new ConferenceData();
        $conferenceData->setCreateRequest($createConferenceRequest);

        // Create the event
        $event = new Event();
        $event->setSummary('Medical Consultation - ' . $appointment->patient_name);
        $event->setDescription($this->generateEventDescription($appointment));
        $event->setStart($startDateTime);
        $event->setEnd($endDateTime);
        $event->setAttendees([$doctorAttendee, $patientAttendee]);
        $event->setConferenceData($conferenceData);

        // Insert the event
        return $this->calendarService->events->insert('primary', $event, [
            'conferenceDataVersion' => 1,
            'sendNotifications' => true
        ]);
    }

    /**
     * Create calendar event for doctor
     */
    private function createDoctorCalendarEvent($appointment, $meetLink)
    {
        if (!$this->isGoogleEmail($appointment->doctor->email)) {
            Log::info('Doctor does not have Google email, skipping calendar creation');
            return null;
        }

        try {
            $startDateTime = new EventDateTime();
            $startDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time));
            $startDateTime->setTimeZone('Africa/Nairobi');

            $endDateTime = new EventDateTime();
            $endDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time, 60));
            $endDateTime->setTimeZone('Africa/Nairobi');

            $event = new Event();
            $event->setSummary('Patient Consultation - ' . $appointment->patient_name);
            $event->setDescription($this->generateDoctorEventDescription($appointment, $meetLink));
            $event->setStart($startDateTime);
            $event->setEnd($endDateTime);

            $calendarId = $appointment->doctor->email;
            $createdEvent = $this->calendarService->events->insert($calendarId, $event);

            return $createdEvent->getId();
        } catch (Exception $e) {
            Log::warning('Failed to create doctor calendar event: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Create calendar event for patient
     */
    private function createPatientCalendarEvent($appointment, $meetLink)
    {
        if (!$this->isGoogleEmail($appointment->patient_email)) {
            Log::info('Patient does not have Google email, skipping calendar creation');
            return null;
        }

        try {
            $startDateTime = new EventDateTime();
            $startDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time));
            $startDateTime->setTimeZone('Africa/Nairobi');

            $endDateTime = new EventDateTime();
            $endDateTime->setDateTime($this->formatDateTime($appointment->appointment_date, $appointment->appointment_time, 60));
            $endDateTime->setTimeZone('Africa/Nairobi');

            $event = new Event();
            $event->setSummary('Medical Consultation with Dr. ' . $appointment->doctor->name);
            $event->setDescription($this->generatePatientEventDescription($appointment, $meetLink));
            $event->setStart($startDateTime);
            $event->setEnd($endDateTime);

            $calendarId = $appointment->patient_email;
            $createdEvent = $this->calendarService->events->insert($calendarId, $event);

            return $createdEvent->getId();
        } catch (Exception $e) {
            Log::warning('Failed to create patient calendar event: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Extract Google Meet link from event
     */
    private function extractMeetLink($event)
    {
        $conferenceData = $event->getConferenceData();
        if ($conferenceData && $conferenceData->getEntryPoints()) {
            foreach ($conferenceData->getEntryPoints() as $entryPoint) {
                if ($entryPoint->getEntryPointType() === 'video') {
                    return $entryPoint->getUri();
                }
            }
        }
        return null;
    }

    /**
     * Format date and time for Google Calendar
     */
    private function formatDateTime($date, $time, $addMinutes = 0)
    {
        $datetime = $date->format('Y-m-d') . ' ' . $time;
        $timestamp = strtotime($datetime);

        if ($addMinutes > 0) {
            $timestamp += ($addMinutes * 60);
        }

        return date('c', $timestamp); // ISO 8601 format
    }

    /**
     * Check if email is a Google account
     */
    private function isGoogleEmail($email)
    {
        $googleDomains = ['gmail.com', 'googlemail.com'];
        $domain = substr(strrchr($email, "@"), 1);
        return in_array(strtolower($domain), $googleDomains) || $this->hasGoogleWorkspace($email);
    }

    /**
     * Check if email domain has Google Workspace
     */
    private function hasGoogleWorkspace($email)
    {
        // You can implement MX record checking here if needed
        // For now, we'll assume non-Gmail domains might have Google Workspace
        return true;
    }

    /**
     * Generate event description
     */
    private function generateEventDescription($appointment)
    {
        return "Medical Consultation\n\n" .
               "Patient: {$appointment->patient_name}\n" .
               "Doctor: Dr. {$appointment->doctor->name}\n" .
               "Type: {$appointment->consultation_type}\n" .
               "Date: {$appointment->appointment_date->format('F j, Y')}\n" .
               "Time: {$appointment->appointment_time}\n\n" .
               ($appointment->notes ? "Notes: {$appointment->notes}\n\n" : '') .
               "This is an online consultation via Google Meet.";
    }

    /**
     * Generate doctor event description
     */
    private function generateDoctorEventDescription($appointment, $meetLink)
    {
        return "Patient Consultation\n\n" .
               "Patient: {$appointment->patient_name}\n" .
               "Email: {$appointment->patient_email}\n" .
               "Phone: {$appointment->patient_telephone}\n" .
               ($appointment->patient_location ? "Location: {$appointment->patient_location}\n" : '') .
               "Type: {$appointment->consultation_type}\n\n" .
               ($appointment->notes ? "Notes: {$appointment->notes}\n\n" : '') .
               ($meetLink ? "Google Meet Link: {$meetLink}" : '');
    }

    /**
     * Generate patient event description
     */
    private function generatePatientEventDescription($appointment, $meetLink)
    {
        return "Medical Consultation\n\n" .
               "Doctor: Dr. {$appointment->doctor->name}\n" .
               "Type: {$appointment->consultation_type}\n" .
               "Date: {$appointment->appointment_date->format('F j, Y')}\n" .
               "Time: {$appointment->appointment_time}\n\n" .
               ($meetLink ? "Join Meeting: {$meetLink}\n\n" : '') .
               "Please join the meeting 5 minutes before the scheduled time.";
    }

    /**
     * Cancel/Delete Google Meet and calendar events
     */
    public function cancelMeetAppointment($eventData)
    {
        try {
            // Delete main event
            if (isset($eventData['main_event_id'])) {
                $this->calendarService->events->delete('primary', $eventData['main_event_id']);
            }

            // Delete doctor's calendar event
            if (isset($eventData['doctor_event_id']) && $eventData['doctor_event_id']) {
                try {
                    $this->calendarService->events->delete($eventData['doctor_email'], $eventData['doctor_event_id']);
                } catch (Exception $e) {
                    Log::warning('Failed to delete doctor calendar event: ' . $e->getMessage());
                }
            }

            // Delete patient's calendar event
            if (isset($eventData['patient_event_id']) && $eventData['patient_event_id']) {
                try {
                    $this->calendarService->events->delete($eventData['patient_email'], $eventData['patient_event_id']);
                } catch (Exception $e) {
                    Log::warning('Failed to delete patient calendar event: ' . $e->getMessage());
                }
            }

            return ['success' => true];
        } catch (Exception $e) {
            Log::error('Failed to cancel Google Meet appointment: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}