<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Symptom;
use App\Models\Condition;
use App\Models\Specialization;

class MedicalDataSeeder extends Seeder
{
    public function run(): void
    {
        // Create symptoms
        $symptoms = [
            ['name' => 'Headache', 'description' => 'Pain in head or neck area'],
            ['name' => 'Fever', 'description' => 'High body temperature'],
            ['name' => 'Cough', 'description' => 'Forced expulsion of air from lungs'],
            ['name' => 'Chest Pain', 'description' => 'Pain in chest area'],
            ['name' => 'Shortness of Breath', 'description' => 'Difficulty breathing'],
            ['name' => 'Nausea', 'description' => 'Feeling of sickness'],
            ['name' => 'Vomiting', 'description' => 'Expelling stomach contents'],
            ['name' => 'Dizziness', 'description' => 'Feeling unsteady or lightheaded'],
            ['name' => 'Fatigue', 'description' => 'Extreme tiredness'],
            ['name' => 'Joint Pain', 'description' => 'Pain in joints'],
            ['name' => 'Back Pain', 'description' => 'Pain in back area'],
            ['name' => 'Abdominal Pain', 'description' => 'Pain in stomach area'],
            ['name' => 'Skin Rash', 'description' => 'Skin irritation or eruption'],
            ['name' => 'Toothache', 'description' => 'Pain in teeth or gums'],
            ['name' => 'Sore Throat', 'description' => 'Pain in throat'],
            ['name' => 'Runny Nose', 'description' => 'Nasal discharge'],
            ['name' => 'Eye Pain', 'description' => 'Pain in or around eyes'],
            ['name' => 'Ear Pain', 'description' => 'Pain in ear'],
            ['name' => 'Muscle Pain', 'description' => 'Pain in muscles'],
            ['name' => 'Swelling', 'description' => 'Enlarged body part'],
        ];

        foreach ($symptoms as $symptom) {
            Symptom::firstOrCreate(['name' => $symptom['name']], $symptom);
        }

        // Create conditions
        $conditions = [
            ['name' => 'Diabetes', 'description' => 'High blood sugar condition'],
            ['name' => 'Hypertension', 'description' => 'High blood pressure'],
            ['name' => 'Asthma', 'description' => 'Breathing difficulty condition'],
            ['name' => 'Heart Disease', 'description' => 'Various heart conditions'],
            ['name' => 'Arthritis', 'description' => 'Joint inflammation'],
            ['name' => 'Migraine', 'description' => 'Severe headache condition'],
            ['name' => 'Depression', 'description' => 'Mental health condition'],
            ['name' => 'Anxiety', 'description' => 'Mental health condition'],
            ['name' => 'Flu', 'description' => 'Viral infection'],
            ['name' => 'Cold', 'description' => 'Common cold virus'],
            ['name' => 'Pneumonia', 'description' => 'Lung infection'],
            ['name' => 'Bronchitis', 'description' => 'Airway inflammation'],
            ['name' => 'Eczema', 'description' => 'Skin condition'],
            ['name' => 'Acne', 'description' => 'Skin condition'],
            ['name' => 'Allergies', 'description' => 'Immune system reaction'],
            ['name' => 'Constipation', 'description' => 'Digestive issue'],
            ['name' => 'Diarrhea', 'description' => 'Digestive issue'],
            ['name' => 'Insomnia', 'description' => 'Sleep disorder'],
            ['name' => 'Kidney Stones', 'description' => 'Kidney condition'],
            ['name' => 'Gastritis', 'description' => 'Stomach inflammation'],
        ];

        foreach ($conditions as $condition) {
            Condition::firstOrCreate(['name' => $condition['name']], $condition);
        }

        // Create symptom-to-specialization mappings
        $this->createSymptomMappings();
        $this->createConditionMappings();
    }

    private function createSymptomMappings()
    {
        $mappings = [
            // General Care symptoms
            'Fever' => ['General Care'],
            'Fatigue' => ['General Care'],
            'Nausea' => ['General Care'],
            'Vomiting' => ['General Care'],
            'Dizziness' => ['General Care'],

            // Cardiologist symptoms
            'Chest Pain' => ['Cardiologist', 'General Care'],
            'Shortness of Breath' => ['Cardiologist', 'General Care'],

            // Dermatologist symptoms
            'Skin Rash' => ['Dermatologist'],
            'Acne' => ['Dermatologist'],

            // Dentist symptoms
            'Toothache' => ['Dentist'],

            // Orthopedic symptoms
            'Joint Pain' => ['Orthopedic'],
            'Back Pain' => ['Orthopedic'],
            'Muscle Pain' => ['Orthopedic'],

            // Pediatrician symptoms (for children)
            'Ear Pain' => ['Pediatrician', 'General Care'],
            'Sore Throat' => ['Pediatrician', 'General Care'],
            'Runny Nose' => ['Pediatrician', 'General Care'],

            // Multiple specialties
            'Headache' => ['General Care', 'Cardiologist'],
            'Cough' => ['General Care', 'Cardiologist'],
            'Abdominal Pain' => ['General Care'],
            'Eye Pain' => ['General Care'],
            'Swelling' => ['General Care', 'Cardiologist'],
        ];

        foreach ($mappings as $symptomName => $specialties) {
            $symptom = Symptom::where('name', $symptomName)->first();
            if ($symptom) {
                foreach ($specialties as $index => $specialtyName) {
                    $specialization = Specialization::where('specialization_name', $specialtyName)->first();
                    if ($specialization) {
                        $symptom->specializations()->syncWithoutDetaching([
                            $specialization->id => ['priority' => $index + 1]
                        ]);
                    }
                }
            }
        }
    }

    private function createConditionMappings()
    {
        $mappings = [
            // Cardiologist conditions
            'Hypertension' => ['Cardiologist'],
            'Heart Disease' => ['Cardiologist'],

            // General Care conditions
            'Diabetes' => ['General Care'],
            'Flu' => ['General Care'],
            'Cold' => ['General Care'],
            'Allergies' => ['General Care'],
            'Constipation' => ['General Care'],
            'Diarrhea' => ['General Care'],
            'Gastritis' => ['General Care'],

            // Respiratory conditions
            'Asthma' => ['General Care', 'Cardiologist'],
            'Pneumonia' => ['General Care'],
            'Bronchitis' => ['General Care'],

            // Orthopedic conditions
            'Arthritis' => ['Orthopedic'],

            // Dermatologist conditions
            'Eczema' => ['Dermatologist'],
            'Acne' => ['Dermatologist'],

            // Mental health (General Care can refer)
            'Depression' => ['General Care'],
            'Anxiety' => ['General Care'],
            'Insomnia' => ['General Care'],

            // Neurological
            'Migraine' => ['General Care'],

            // Urological
            'Kidney Stones' => ['General Care'],
        ];

        foreach ($mappings as $conditionName => $specialties) {
            $condition = Condition::where('name', $conditionName)->first();
            if ($condition) {
                foreach ($specialties as $index => $specialtyName) {
                    $specialization = Specialization::where('specialization_name', $specialtyName)->first();
                    if ($specialization) {
                        $condition->specializations()->syncWithoutDetaching([
                            $specialization->id => ['priority' => $index + 1]
                        ]);
                    }
                }
            }
        }
    }
}