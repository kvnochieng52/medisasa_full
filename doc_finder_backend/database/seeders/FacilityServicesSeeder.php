<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Catalogue of medical services commonly offered by facilities. Facilities
 * pick from these when adding what they offer (and can also add custom ones).
 * Idempotent: keyed on `slug`.
 */
class FacilityServicesSeeder extends Seeder
{
    public function run(): void
    {
        $services = [
            // Consultations
            ['General Consultation',              'Standard doctor consultation'],
            ['Specialist Consultation',           'Consultation with a specialist doctor'],
            ['Telemedicine Consultation',         'Online video consultation with a doctor'],
            ['Follow-up Consultation',            'Follow-up appointment for a previous visit'],
            ['Emergency Consultation',            'Urgent same-day consultation'],
            ['Home Visit',                        'Doctor / nurse visits the patient at home'],

            // Diagnostics: lab
            ['Complete Blood Count (CBC)',        'Full blood count laboratory test'],
            ['Blood Sugar Test',                  'Random / fasting blood glucose test'],
            ['HbA1c Test',                        '3-month blood sugar average test'],
            ['Lipid Profile',                     'Cholesterol and triglycerides panel'],
            ['Liver Function Test (LFT)',         'Panel to assess liver enzyme levels'],
            ['Kidney Function Test (KFT)',        'Panel to assess kidney function'],
            ['Thyroid Function Test',             'TSH, T3, T4 panel'],
            ['Urinalysis',                        'General urine examination'],
            ['Urine Culture',                     'Culture to identify urinary infections'],
            ['Stool Test',                        'Stool laboratory examination'],
            ['HIV Test',                          'HIV antibody test'],
            ['Malaria Test',                      'Malaria rapid diagnostic test / microscopy'],
            ['Tuberculosis (TB) Screening',       'Sputum / GeneXpert TB screening'],
            ['Pregnancy Test',                    'Beta-hCG or urine pregnancy test'],
            ['Pap Smear',                         'Cervical cancer screening'],
            ['Prostate Specific Antigen (PSA)',   'Prostate cancer screening'],

            // Imaging / Radiology
            ['Radiology',                         'General radiology and medical imaging services'],
            ['X-Ray',                             'Digital radiography imaging'],
            ['Ultrasound',                        'General or obstetric ultrasound imaging'],
            ['CT Scan',                           'Computed tomography imaging'],
            ['MRI Scan',                          'Magnetic resonance imaging'],
            ['Mammogram',                         'Breast cancer screening imaging'],
            ['Echocardiogram',                    'Ultrasound of the heart'],
            ['Electrocardiogram (ECG)',           'Recording of the heart\'s electrical activity'],
            ['Bone Density Scan (DEXA)',          'Bone mineral density measurement'],

            // Preventive & wellness
            ['Vaccination / Immunisation',        'Routine and travel vaccines'],
            ['Antenatal Care',                    'Pregnancy monitoring visits'],
            ['Postnatal Care',                    'Post-delivery mother & child care'],
            ['Family Planning',                   'Contraception counselling and provision'],
            ['Well-baby Clinic',                  'Infant growth monitoring and immunisations'],
            ['Cervical Cancer Screening',         'HPV / VIA / Pap-based screening'],
            ['Diabetes Clinic',                   'Ongoing diabetes management'],
            ['Hypertension Clinic',               'Ongoing blood pressure management'],
            ['Weight Management',                 'Diet, exercise and clinical weight support'],
            ['Nutrition Counselling',             'Dietitian-led nutrition assessment'],

            // Dental
            ['Dental Consultation',               'Dental examination and consultation'],
            ['Dental Cleaning (Scaling)',         'Professional teeth cleaning'],
            ['Tooth Filling',                     'Cavity filling'],
            ['Tooth Extraction',                  'Removal of a tooth'],
            ['Root Canal Treatment',              'Endodontic therapy'],

            // Eye
            ['Eye Examination',                   'Vision and eye health check'],
            ['Spectacle Fitting',                 'Prescription glasses fitting'],
            ['Contact Lens Fitting',              'Contact lens assessment and fitting'],
            ['Cataract Surgery',                  'Removal of clouded lens'],

            // Physio / rehab
            ['Physiotherapy Session',             'Physical rehabilitation session'],
            ['Occupational Therapy',              'Functional rehabilitation therapy'],

            // Mental health
            ['Psychiatric Consultation',          'Consultation with a psychiatrist'],
            ['Psychological Counselling',         'Therapy session with a psychologist'],
            ['Group Therapy',                     'Facilitated group therapy session'],

            // Surgery & procedures
            ['Minor Surgery',                     'Outpatient minor surgical procedures'],
            ['Major Surgery',                     'Inpatient major surgical procedures'],
            ['Circumcision',                      'Male circumcision procedure'],
            ['Wound Dressing',                    'Wound cleaning and dressing'],
            ['Injection Administration',          'Intramuscular / IV drug administration'],
            ['Intravenous Fluid Therapy',         'IV fluid administration'],

            // Maternity
            ['Normal Delivery',                   'Vaginal childbirth care'],
            ['Caesarean Section',                 'Surgical childbirth'],
            ['Labour Ward Admission',             'Inpatient labour and delivery care'],

            // Inpatient
            ['General Ward Admission',            'General inpatient bed and care'],
            ['Private Ward Admission',            'Private inpatient room and care'],
            ['ICU Admission',                     'Intensive care unit admission'],
            ['HDU Admission',                     'High dependency unit admission'],

            // Ambulance / emergency
            ['Ambulance Services',                'Emergency patient transport'],
            ['Casualty / Emergency Room',         'Emergency room evaluation and treatment'],

            // Pharmacy
            ['Pharmacy / Prescription Dispensing','On-site prescription dispensing'],
        ];

        $sort = 1;
        foreach ($services as [$name, $desc]) {
            DB::table('facility_services')->updateOrInsert(
                ['slug' => Str::slug($name)],
                [
                    'name' => $name,
                    'slug' => Str::slug($name),
                    'description' => $desc,
                    'is_active' => true,
                    'sort_order' => $sort++,
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        }
    }
}
