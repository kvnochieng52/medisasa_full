<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Symptom;
use App\Models\Condition;
use App\Models\Specialization;

/**
 * Seeds symptoms, conditions and their priority mappings to specializations.
 *
 * - All symptoms/conditions inserted via firstOrCreate so the seeder is
 *   idempotent.
 * - Mapping helper silently skips any specialization name that doesn't exist
 *   in the database; this means SpecializationSeeder should run first.
 */
class MedicalDataSeeder extends Seeder
{
    public function run(): void
    {
        // ── Symptoms ─────────────────────────────────────────────────────
        $symptoms = [
            ['name' => 'Headache',              'description' => 'Pain in head or neck area'],
            ['name' => 'Fever',                 'description' => 'High body temperature'],
            ['name' => 'Cough',                 'description' => 'Forced expulsion of air from lungs'],
            ['name' => 'Chest Pain',            'description' => 'Pain in chest area'],
            ['name' => 'Shortness of Breath',   'description' => 'Difficulty breathing'],
            ['name' => 'Nausea',                'description' => 'Feeling of sickness'],
            ['name' => 'Vomiting',              'description' => 'Expelling stomach contents'],
            ['name' => 'Dizziness',             'description' => 'Feeling unsteady or lightheaded'],
            ['name' => 'Fatigue',               'description' => 'Extreme tiredness'],
            ['name' => 'Joint Pain',            'description' => 'Pain in joints'],
            ['name' => 'Back Pain',             'description' => 'Pain in back area'],
            ['name' => 'Abdominal Pain',        'description' => 'Pain in stomach area'],
            ['name' => 'Skin Rash',             'description' => 'Skin irritation or eruption'],
            ['name' => 'Toothache',             'description' => 'Pain in teeth or gums'],
            ['name' => 'Sore Throat',           'description' => 'Pain in throat'],
            ['name' => 'Runny Nose',            'description' => 'Nasal discharge'],
            ['name' => 'Eye Pain',              'description' => 'Pain in or around eyes'],
            ['name' => 'Ear Pain',              'description' => 'Pain in ear'],
            ['name' => 'Muscle Pain',           'description' => 'Pain in muscles'],
            ['name' => 'Swelling',              'description' => 'Enlarged body part'],
            ['name' => 'Blurred Vision',        'description' => 'Loss of sharpness of eyesight'],
            ['name' => 'Painful Urination',     'description' => 'Burning or pain on urination'],
            ['name' => 'Heart Palpitations',    'description' => 'Awareness of irregular heartbeat'],
            ['name' => 'Numbness / Tingling',   'description' => 'Loss of sensation in extremities'],
            ['name' => 'Hair Loss',             'description' => 'Loss of scalp or body hair'],
            ['name' => 'Weight Loss',           'description' => 'Unintended weight loss'],
            ['name' => 'Weight Gain',           'description' => 'Unintended weight gain'],
            ['name' => 'Diarrhoea',             'description' => 'Loose, watery stools'],
            ['name' => 'Constipation',          'description' => 'Difficulty passing stool'],
            ['name' => 'Anxiety',               'description' => 'Persistent worry or unease'],
            ['name' => 'Low Mood',              'description' => 'Persistent sadness or hopelessness'],
            ['name' => 'Insomnia',              'description' => 'Inability to sleep'],
        ];

        foreach ($symptoms as $symptom) {
            Symptom::firstOrCreate(['name' => $symptom['name']], $symptom);
        }

        // ── Conditions ───────────────────────────────────────────────────
        $conditions = [
            ['name' => 'Diabetes',              'description' => 'High blood sugar condition'],
            ['name' => 'Hypertension',          'description' => 'High blood pressure'],
            ['name' => 'Asthma',                'description' => 'Breathing difficulty condition'],
            ['name' => 'Heart Disease',         'description' => 'Various heart conditions'],
            ['name' => 'Arthritis',             'description' => 'Joint inflammation'],
            ['name' => 'Migraine',              'description' => 'Severe headache condition'],
            ['name' => 'Depression',            'description' => 'Mental health condition'],
            ['name' => 'Anxiety Disorder',      'description' => 'Mental health condition'],
            ['name' => 'Flu',                   'description' => 'Viral infection'],
            ['name' => 'Common Cold',           'description' => 'Common cold virus'],
            ['name' => 'Pneumonia',             'description' => 'Lung infection'],
            ['name' => 'Bronchitis',            'description' => 'Airway inflammation'],
            ['name' => 'Eczema',                'description' => 'Skin inflammation'],
            ['name' => 'Acne',                  'description' => 'Skin condition'],
            ['name' => 'Allergies',             'description' => 'Immune system reaction'],
            ['name' => 'Constipation',          'description' => 'Digestive issue'],
            ['name' => 'Diarrhoea',             'description' => 'Digestive issue'],
            ['name' => 'Insomnia',              'description' => 'Sleep disorder'],
            ['name' => 'Kidney Stones',         'description' => 'Kidney condition'],
            ['name' => 'Gastritis',             'description' => 'Stomach inflammation'],
            ['name' => 'Urinary Tract Infection','description' => 'Bladder / urethra infection'],
            ['name' => 'Tuberculosis',          'description' => 'Bacterial lung infection'],
            ['name' => 'Malaria',               'description' => 'Mosquito-borne infection'],
            ['name' => 'HIV/AIDS',              'description' => 'Immune system viral infection'],
            ['name' => 'Sickle Cell Disease',   'description' => 'Inherited red-blood-cell disorder'],
            ['name' => 'Thyroid Disorder',      'description' => 'Hypo / hyperthyroidism'],
            ['name' => 'Stroke',                'description' => 'Brain blood-supply event'],
            ['name' => 'Cataracts',             'description' => 'Clouding of the eye lens'],
            ['name' => 'Glaucoma',              'description' => 'Increased eye pressure'],
            ['name' => 'Dental Caries',         'description' => 'Tooth decay'],
        ];

        foreach ($conditions as $condition) {
            Condition::firstOrCreate(['name' => $condition['name']], $condition);
        }

        $this->createSymptomMappings();
        $this->createConditionMappings();
    }

    private function createSymptomMappings(): void
    {
        // Map symptom → ordered list of specialization names (first = highest priority)
        $mappings = [
            // General triage
            'Fever'                => ['General Care', 'Family Medicine'],
            'Fatigue'              => ['General Care', 'Family Medicine'],
            'Nausea'               => ['General Care', 'Gastroenterologist'],
            'Vomiting'             => ['General Care', 'Gastroenterologist'],
            'Dizziness'            => ['General Care', 'Neurologist'],
            'Headache'             => ['General Care', 'Neurologist'],
            'Cough'                => ['General Care', 'Pulmonologist'],

            // Cardiology
            'Chest Pain'           => ['Cardiologist', 'General Care'],
            'Shortness of Breath'  => ['Cardiologist', 'Pulmonologist', 'General Care'],
            'Heart Palpitations'   => ['Cardiologist', 'General Care'],
            'Swelling'             => ['Cardiologist', 'General Care'],

            // Dermatology
            'Skin Rash'            => ['Dermatologist', 'Allergist / Immunologist'],
            'Hair Loss'            => ['Dermatologist'],

            // Dentistry
            'Toothache'            => ['Dentist'],

            // Orthopedic
            'Joint Pain'           => ['Orthopedic', 'Rheumatologist'],
            'Back Pain'            => ['Orthopedic', 'Physiotherapist'],
            'Muscle Pain'          => ['Orthopedic', 'Physiotherapist'],

            // Pediatrics / ENT
            'Ear Pain'             => ['ENT Specialist', 'Pediatrician', 'General Care'],
            'Sore Throat'          => ['ENT Specialist', 'General Care'],
            'Runny Nose'           => ['General Care', 'ENT Specialist'],

            // Ophthalmology
            'Eye Pain'             => ['Ophthalmologist', 'General Care'],
            'Blurred Vision'       => ['Ophthalmologist', 'Optometrist'],

            // GI
            'Abdominal Pain'       => ['Gastroenterologist', 'General Care'],
            'Diarrhoea'            => ['Gastroenterologist', 'General Care'],
            'Constipation'         => ['Gastroenterologist', 'General Care'],

            // Urology
            'Painful Urination'    => ['Urologist', 'General Care'],

            // Neurology
            'Numbness / Tingling'  => ['Neurologist', 'General Care'],

            // Endocrine
            'Weight Loss'          => ['Endocrinologist', 'General Care'],
            'Weight Gain'          => ['Endocrinologist', 'General Care'],

            // Mental health
            'Anxiety'              => ['Psychiatrist', 'Psychologist', 'Therapist / Counselor'],
            'Low Mood'             => ['Psychiatrist', 'Psychologist', 'Therapist / Counselor'],
            'Insomnia'             => ['Psychiatrist', 'General Care'],
        ];

        foreach ($mappings as $symptomName => $specialties) {
            $symptom = Symptom::where('name', $symptomName)->first();
            if (!$symptom) continue;

            foreach ($specialties as $index => $specialtyName) {
                $spec = Specialization::where('specialization_name', $specialtyName)->first();
                if (!$spec) continue;
                $symptom->specializations()->syncWithoutDetaching([
                    $spec->id => ['priority' => $index + 1],
                ]);
            }
        }
    }

    private function createConditionMappings(): void
    {
        $mappings = [
            // Cardiology
            'Hypertension'           => ['Cardiologist', 'General Care'],
            'Heart Disease'          => ['Cardiologist'],
            'Stroke'                 => ['Neurologist', 'Cardiologist'],

            // Endocrine
            'Diabetes'               => ['Endocrinologist', 'General Care'],
            'Thyroid Disorder'       => ['Endocrinologist'],

            // Respiratory
            'Asthma'                 => ['Pulmonologist', 'General Care'],
            'Pneumonia'              => ['Pulmonologist', 'General Care'],
            'Bronchitis'             => ['Pulmonologist', 'General Care'],
            'Tuberculosis'           => ['Pulmonologist', 'Infectious Diseases'],

            // GI
            'Gastritis'              => ['Gastroenterologist', 'General Care'],
            'Constipation'           => ['Gastroenterologist', 'General Care'],
            'Diarrhoea'              => ['Gastroenterologist', 'General Care'],

            // Urology
            'Kidney Stones'          => ['Urologist', 'Nephrologist'],
            'Urinary Tract Infection'=> ['Urologist', 'General Care'],

            // Dermatology
            'Eczema'                 => ['Dermatologist'],
            'Acne'                   => ['Dermatologist'],

            // Allergy
            'Allergies'              => ['Allergist / Immunologist', 'General Care'],

            // Orthopedic
            'Arthritis'              => ['Orthopedic', 'Rheumatologist'],

            // Mental health
            'Depression'             => ['Psychiatrist', 'Psychologist', 'Therapist / Counselor'],
            'Anxiety Disorder'       => ['Psychiatrist', 'Psychologist', 'Therapist / Counselor'],
            'Insomnia'               => ['Psychiatrist', 'General Care'],

            // Infections
            'Flu'                    => ['General Care'],
            'Common Cold'            => ['General Care'],
            'Malaria'                => ['General Care', 'Infectious Diseases'],
            'HIV/AIDS'               => ['Infectious Diseases', 'General Care'],

            // Other
            'Sickle Cell Disease'    => ['Hematologist', 'General Care'],
            'Migraine'               => ['Neurologist', 'General Care'],

            // Ophthalmology
            'Cataracts'              => ['Ophthalmologist'],
            'Glaucoma'               => ['Ophthalmologist'],

            // Dental
            'Dental Caries'          => ['Dentist'],
        ];

        foreach ($mappings as $conditionName => $specialties) {
            $condition = Condition::where('name', $conditionName)->first();
            if (!$condition) continue;

            foreach ($specialties as $index => $specialtyName) {
                $spec = Specialization::where('specialization_name', $specialtyName)->first();
                if (!$spec) continue;
                $condition->specializations()->syncWithoutDetaching([
                    $spec->id => ['priority' => $index + 1],
                ]);
            }
        }
    }
}
