<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds the master list of medical specializations.
 *
 * Idempotent: uses updateOrInsert keyed on specialization_name so this seeder
 * can be re-run safely without duplicating rows. Names listed here are the
 * canonical ones that other seeders (MedicalDataSeeder) and the doctor finder
 * flow look up by string match.
 */
class SpecializationSeeder extends Seeder
{
    public function run(): void
    {
        $specializations = [
            // Generalists
            ['specialization_name' => 'General Care',           'specialization_description' => 'General medical practitioner / GP'],
            ['specialization_name' => 'Family Medicine',        'specialization_description' => 'Whole-family primary care'],
            ['specialization_name' => 'Emergency Medicine',     'specialization_description' => 'Acute & emergency care'],

            // Internal medicine subspecialties
            ['specialization_name' => 'Cardiologist',           'specialization_description' => 'Heart and cardiovascular system specialist'],
            ['specialization_name' => 'Pulmonologist',          'specialization_description' => 'Lungs and respiratory system specialist'],
            ['specialization_name' => 'Gastroenterologist',     'specialization_description' => 'Digestive system specialist'],
            ['specialization_name' => 'Endocrinologist',        'specialization_description' => 'Hormone and endocrine system specialist'],
            ['specialization_name' => 'Nephrologist',           'specialization_description' => 'Kidney specialist'],
            ['specialization_name' => 'Hepatologist',           'specialization_description' => 'Liver, gallbladder, biliary tree specialist'],
            ['specialization_name' => 'Hematologist',           'specialization_description' => 'Blood disorders specialist'],
            ['specialization_name' => 'Rheumatologist',         'specialization_description' => 'Joints and autoimmune disease specialist'],
            ['specialization_name' => 'Oncologist',             'specialization_description' => 'Cancer specialist'],
            ['specialization_name' => 'Infectious Diseases',    'specialization_description' => 'Infectious disease specialist'],
            ['specialization_name' => 'Allergist / Immunologist','specialization_description' => 'Allergy and immune system specialist'],

            // Surgical & system specialists
            ['specialization_name' => 'General Surgeon',        'specialization_description' => 'Abdominal and general surgical specialist'],
            ['specialization_name' => 'Orthopedic',             'specialization_description' => 'Musculoskeletal / bones, joints, muscles specialist'],
            ['specialization_name' => 'Neurologist',            'specialization_description' => 'Nervous system specialist'],
            ['specialization_name' => 'Neurosurgeon',           'specialization_description' => 'Brain and spinal surgical specialist'],
            ['specialization_name' => 'Plastic Surgeon',        'specialization_description' => 'Reconstructive and aesthetic surgery'],
            ['specialization_name' => 'Vascular Surgeon',       'specialization_description' => 'Blood vessel surgery specialist'],
            ['specialization_name' => 'Urologist',              'specialization_description' => 'Urinary tract & male reproductive specialist'],

            // Senses & external
            ['specialization_name' => 'Dermatologist',          'specialization_description' => 'Skin, hair, and nail specialist'],
            ['specialization_name' => 'Ophthalmologist',        'specialization_description' => 'Eye and vision specialist'],
            ['specialization_name' => 'ENT Specialist',         'specialization_description' => 'Ear, nose, and throat specialist'],
            ['specialization_name' => 'Dentist',                'specialization_description' => 'Dental and oral health specialist'],

            // Women, children & reproductive
            ['specialization_name' => 'Pediatrician',           'specialization_description' => 'Children and adolescent specialist'],
            ['specialization_name' => 'Neonatologist',          'specialization_description' => 'Newborn intensive care specialist'],
            ['specialization_name' => 'Gynecologist',           'specialization_description' => 'Female reproductive health specialist'],
            ['specialization_name' => 'Obstetrician',           'specialization_description' => 'Pregnancy and childbirth specialist'],

            // Mental health
            ['specialization_name' => 'Psychiatrist',           'specialization_description' => 'Mental health (medication-prescribing) specialist'],
            ['specialization_name' => 'Psychologist',           'specialization_description' => 'Counselling & psychological assessment'],
            ['specialization_name' => 'Therapist / Counselor',  'specialization_description' => 'Talk therapy / counselling'],

            // Imaging, labs & other clinical
            ['specialization_name' => 'Radiologist',            'specialization_description' => 'Medical imaging specialist'],
            ['specialization_name' => 'Pathologist',            'specialization_description' => 'Laboratory diagnostics specialist'],
            ['specialization_name' => 'Anesthesiologist',       'specialization_description' => 'Anesthesia & pain management specialist'],
            ['specialization_name' => 'Physiotherapist',        'specialization_description' => 'Physical rehabilitation specialist'],
            ['specialization_name' => 'Nutritionist / Dietitian','specialization_description' => 'Diet and nutrition specialist'],
            ['specialization_name' => 'Optometrist',            'specialization_description' => 'Eye care & vision testing'],
            ['specialization_name' => 'Pharmacist',             'specialization_description' => 'Medication dispensing & counselling'],
        ];

        $now = now();
        foreach ($specializations as $index => $spec) {
            DB::table('specializations')->updateOrInsert(
                ['specialization_name' => $spec['specialization_name']],
                [
                    'specialization_name' => $spec['specialization_name'],
                    'specialization_description' => $spec['specialization_description'],
                    'is_active' => 1,
                    'is_active_for_facility' => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );
        }
    }
}
