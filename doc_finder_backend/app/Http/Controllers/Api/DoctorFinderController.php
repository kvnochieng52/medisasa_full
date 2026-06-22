<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Specialization;
use App\Models\Symptom;
use App\Models\Condition;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DoctorFinderController extends Controller
{
    /**
     * Conversational doctor finder - processes natural language queries
     */
    public function conversationalSearch(Request $request)
    {
        try {
            $userMessage = $request->input('message', '');
            $conversationContext = $request->input('context', []);

            // Analyze the user's message
            $analysis = $this->analyzeUserMessage($userMessage);

            // Generate response based on analysis
            $response = $this->generateResponse($analysis, $conversationContext);

            return response()->json([
                'success' => true,
                'response' => $response
            ]);

        } catch (\Exception $e) {
            Log::error('Conversational search error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'I encountered an error. Please try again.',
                'response' => [
                    'message' => 'I\'m sorry, I encountered an issue while processing your request. Please try rephrasing your question.',
                    'type' => 'error'
                ]
            ], 500);
        }
    }

    /**
     * Analyze user message to extract intent and entities
     */
    private function analyzeUserMessage($message)
    {
        $message = strtolower($message);
        $analysis = [
            'intent' => 'general_inquiry',
            'symptoms' => [],
            'specialties' => [],
            'location' => null,
            'urgency' => 'normal',
            'appointment_request' => false
        ];

        // Define symptom keywords
        $symptomKeywords = [
            'headache' => ['headache', 'head pain', 'migraine', 'head ache'],
            'fever' => ['fever', 'high temperature', 'hot', 'burning'],
            'cough' => ['cough', 'coughing', 'throat pain'],
            'chest_pain' => ['chest pain', 'heart pain', 'chest hurt'],
            'stomach_pain' => ['stomach pain', 'belly pain', 'abdominal pain', 'tummy pain'],
            'dizziness' => ['dizzy', 'dizziness', 'vertigo', 'spinning'],
            'nausea' => ['nausea', 'vomiting', 'throw up', 'sick'],
            'fatigue' => ['tired', 'fatigue', 'exhausted', 'weak'],
            'joint_pain' => ['joint pain', 'knee pain', 'back pain', 'arthritis'],
            'skin_issues' => ['rash', 'itchy', 'skin problem', 'acne', 'spots']
        ];

        // Define specialty keywords
        $specialtyKeywords = [
            'general_care' => ['general', 'family doctor', 'gp', 'primary care'],
            'cardiologist' => ['heart', 'cardiologist', 'cardiac', 'blood pressure'],
            'dermatologist' => ['skin', 'dermatologist', 'rash', 'acne'],
            'pediatrician' => ['child', 'baby', 'pediatrician', 'kids'],
            'orthopedic' => ['bone', 'orthopedic', 'fracture', 'joint'],
            'dentist' => ['teeth', 'dental', 'dentist', 'tooth']
        ];

        // Detect symptoms
        foreach ($symptomKeywords as $symptom => $keywords) {
            foreach ($keywords as $keyword) {
                if (strpos($message, $keyword) !== false) {
                    $analysis['symptoms'][] = $symptom;
                    break;
                }
            }
        }

        // Detect specialties
        foreach ($specialtyKeywords as $specialty => $keywords) {
            foreach ($keywords as $keyword) {
                if (strpos($message, $keyword) !== false) {
                    $analysis['specialties'][] = $specialty;
                    break;
                }
            }
        }

        // Detect appointment request
        $appointmentKeywords = ['appointment', 'book', 'schedule', 'meet', 'visit', 'consultation'];
        foreach ($appointmentKeywords as $keyword) {
            if (strpos($message, $keyword) !== false) {
                $analysis['appointment_request'] = true;
                break;
            }
        }

        // Detect urgency
        $urgentKeywords = ['urgent', 'emergency', 'asap', 'immediately', 'serious'];
        foreach ($urgentKeywords as $keyword) {
            if (strpos($message, $keyword) !== false) {
                $analysis['urgency'] = 'urgent';
                break;
            }
        }

        // Detect location (basic)
        $locationKeywords = ['nairobi', 'karen', 'westlands', 'kileleshwa', 'runda'];
        foreach ($locationKeywords as $location) {
            if (strpos($message, $location) !== false) {
                $analysis['location'] = $location;
                break;
            }
        }

        // Determine intent
        if (!empty($analysis['symptoms']) || !empty($analysis['specialties'])) {
            $analysis['intent'] = 'find_doctor';
        } elseif ($analysis['appointment_request']) {
            $analysis['intent'] = 'book_appointment';
        }

        return $analysis;
    }

    /**
     * Generate conversational response based on analysis
     */
    private function generateResponse($analysis, $context = [])
    {
        switch ($analysis['intent']) {
            case 'find_doctor':
                return $this->generateDoctorSearchResponse($analysis);

            case 'book_appointment':
                return $this->generateAppointmentResponse($analysis);

            default:
                return $this->generateGreetingResponse();
        }
    }

    /**
     * Generate doctor search response
     */
    private function generateDoctorSearchResponse($analysis)
    {
        // Build query for doctors
        $query = User::approvedDoctors()->with('specializations');

        // Filter by specialties if detected
        if (!empty($analysis['specialties'])) {
            $specialtyNames = $this->mapSpecialtyKeywords($analysis['specialties']);
            $query->whereHas('specializations', function($q) use ($specialtyNames) {
                $q->whereIn('specialization_name', $specialtyNames);
            });
        }

        $doctors = $query->limit(5)->get();

        if ($doctors->isEmpty()) {
            return [
                'message' => "I understand you're looking for medical help. Let me suggest some general practitioners who can assist you with your concerns.",
                'type' => 'no_results',
                'suggestions' => [
                    "Would you like me to show you general practitioners?",
                    "Can you tell me more about your symptoms?",
                    "Do you have a preferred location?"
                ]
            ];
        }

        $message = $this->generateDoctorRecommendationMessage($analysis, $doctors);

        return [
            'message' => $message,
            'type' => 'doctor_results',
            'doctors' => $this->formatDoctorsForResponse($doctors),
            'follow_up' => "Would you like to book an appointment with any of these doctors? Just let me know!"
        ];
    }

    /**
     * Generate appointment booking response
     */
    private function generateAppointmentResponse($analysis)
    {
        return [
            'message' => "I'd be happy to help you book an appointment! To get started, could you please tell me:\n\n1. What type of doctor are you looking for?\n2. What's the reason for your visit?\n3. Do you prefer in-person or online consultation?",
            'type' => 'appointment_inquiry',
            'next_steps' => [
                'Tell me your symptoms or condition',
                'Choose a doctor specialty',
                'Select your preferred date and time'
            ]
        ];
    }

    /**
     * Generate greeting response
     */
    private function generateGreetingResponse()
    {
        $greetings = [
            "Hello! I'm here to help you find the right doctor. You can tell me about your symptoms, ask for a specific type of doctor, or request to book an appointment.",
            "Hi there! How can I assist you with finding medical care today? Feel free to describe your symptoms or tell me what kind of doctor you need.",
            "Welcome! I'm your medical assistant. Whether you need to find a doctor, understand symptoms, or book an appointment, I'm here to help. What's on your mind?"
        ];

        return [
            'message' => $greetings[array_rand($greetings)],
            'type' => 'greeting',
            'suggestions' => [
                "I have a headache and need to see a doctor",
                "Book appointment with cardiologist",
                "Find pediatrician in Nairobi",
                "I need urgent medical attention"
            ]
        ];
    }

    /**
     * Map specialty keywords to database specialty names
     */
    private function mapSpecialtyKeywords($specialties)
    {
        $mapping = [
            'general_care' => 'General Care',
            'cardiologist' => 'Cardiologist',
            'dermatologist' => 'Dermatologist',
            'pediatrician' => 'Pediatrician',
            'orthopedic' => 'Orthopedic',
            'dentist' => 'Dentist'
        ];

        $mapped = [];
        foreach ($specialties as $specialty) {
            if (isset($mapping[$specialty])) {
                $mapped[] = $mapping[$specialty];
            }
        }

        return $mapped;
    }

    /**
     * Generate personalized doctor recommendation message
     */
    private function generateDoctorRecommendationMessage($analysis, $doctors)
    {
        $message = "Based on ";

        if (!empty($analysis['symptoms'])) {
            $symptomText = implode(', ', array_map(function($s) {
                return str_replace('_', ' ', $s);
            }, $analysis['symptoms']));
            $message .= "your symptoms ($symptomText)";
        }

        if (!empty($analysis['specialties'])) {
            if (!empty($analysis['symptoms'])) {
                $message .= " and ";
            }
            $message .= "your request for a specialist";
        }

        if (empty($analysis['symptoms']) && empty($analysis['specialties'])) {
            $message = "Here are some excellent doctors I recommend";
        }

        $message .= ", I found " . $doctors->count() . " qualified doctor" . ($doctors->count() > 1 ? "s" : "") . " who can help you:";

        if ($analysis['urgency'] === 'urgent') {
            $message = "I understand this is urgent. " . $message;
        }

        return $message;
    }

    /**
     * Format doctors for API response
     */
    private function formatDoctorsForResponse($doctors)
    {
        return $doctors->map(function($doctor) {
            return [
                'id' => $doctor->id,
                'name' => $doctor->name,
                'specialties' => $doctor->specializations->pluck('specialization_name')->toArray(),
                'bio' => $doctor->professional_bio ?? "Experienced medical professional committed to providing quality care.",
                'location' => $doctor->address ?? 'Nairobi',
                'profile_image' => $doctor->profile_image,
                'telephone' => $doctor->telephone,
                'rating' => rand(40, 50) / 10, // Mock rating for now
                'availability' => $this->generateMockAvailability()
            ];
        });
    }

    /**
     * Generate mock availability for demonstration
     */
    private function generateMockAvailability()
    {
        $times = ['9:00 AM', '10:30 AM', '2:00 PM', '3:30 PM', '4:00 PM'];
        return array_slice($times, 0, rand(2, 4));
    }

    /**
     * Get all approved doctors
     */
    public function getApprovedDoctors(Request $request)
    {
        try {
            $specialization = $request->input('specialization');
            $location = $request->input('location');

            $query = User::approvedDoctors()->with('specializations');

            if ($specialization) {
                $query->whereHas('specializations', function($q) use ($specialization) {
                    $q->where('specialization_name', 'like', "%$specialization%");
                });
            }

            if ($location) {
                $query->where('address', 'like', "%$location%");
            }

            $doctors = $query->get();

            return response()->json([
                'success' => true,
                'data' => $this->formatDoctorsForResponse($doctors)
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching doctors: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching doctors'
            ], 500);
        }
    }

    /**
     * Simple search for doctors based on form criteria
     */
    public function searchDoctors(Request $request)
    {
        try {
            $specialty = $request->input('specialty');
            $location = $request->input('location');
            $symptoms = $request->input('symptoms', []);
            $diseases = $request->input('diseases', []);

            $query = User::approvedDoctors()->with('specializations');

            // Filter by specialty if provided
            if ($specialty) {
                $query->whereHas('specializations', function($q) use ($specialty) {
                    $q->where('specialization_name', $specialty);
                });
            }

            // Filter by location if provided
            if ($location) {
                $query->where('address', 'like', "%$location%");
            }

            // If no specialty is specified but symptoms/diseases are provided,
            // use database mapping to suggest appropriate specialties
            if (!$specialty && (!empty($symptoms) || !empty($diseases))) {
                $suggestedSpecialties = $this->getSpecialtiesFromDatabase($symptoms, $diseases);
                if (!empty($suggestedSpecialties)) {
                    $query->whereHas('specializations', function($q) use ($suggestedSpecialties) {
                        $q->whereIn('specialization_name', $suggestedSpecialties);
                    });
                }
            }

            $doctors = $query->limit(20)->get();

            return response()->json([
                'success' => true,
                'data' => $this->formatDoctorsForResponse($doctors),
                'total' => $doctors->count(),
                'search_criteria' => [
                    'specialty' => $specialty,
                    'location' => $location,
                    'symptoms' => $symptoms,
                    'diseases' => $diseases,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error searching doctors: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error searching doctors'
            ], 500);
        }
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
}