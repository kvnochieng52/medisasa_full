<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Carbon\Carbon;
use App\Models\User;
use App\Models\Specialization;
use App\Models\UserSpecialization;
use App\Models\Facility;
use App\Models\FacilitySpeciality;
use App\Models\Appointment;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\Medicine;
use App\Models\MedicineCategory;
use App\Models\MedicineSubcategory;
use App\Models\MedicalProduct;
use App\Models\Group;
use App\Models\MentalHealthMaterial;
use App\Models\DepressionScreening;
use App\Models\Rating;
use App\Models\DoctorFavorite;
use App\Models\DoctorSubscription;
use App\Models\SubscriptionPackage;
use App\Models\PharmacyOrder;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedUsers();
        $this->seedFacilities();
        $this->seedAppointments();
        $this->seedPharmacies();
        $this->seedProducts();
        $this->seedMedicines();
        $this->seedMedicalProducts();
        $this->seedGroups();
        $this->seedMentalHealthMaterials();
        $this->seedDepressionScreenings();
        $this->seedSurvey();
        $this->seedGad7Survey();
        $this->seedRatings();
        $this->seedPharmacyOrders();
        $this->seedDoctorSubscriptions();
        $this->seedDoctorFavorites();
    }

    // -------------------------------------------------------------------------
    // USERS
    // -------------------------------------------------------------------------
    private function seedUsers(): void
    {
        // Admin
        User::firstOrCreate(['email' => 'admin@docfinder.com'], [
            'name'         => 'System Admin',
            'password'     => Hash::make('Admin@1234'),
            'account_type' => 1,
            'is_active'    => 1,
            'telephone'    => '+254700000001',
            'address'      => 'Nairobi, Kenya',
        ]);

        // Regular patients
        $patients = [
            ['name' => 'Alice Kamau',   'email' => 'alice.kamau@demo.com',   'telephone' => '+254711111101', 'dob' => '1990-03-12'],
            ['name' => 'Brian Otieno',  'email' => 'brian.otieno@demo.com',  'telephone' => '+254711111102', 'dob' => '1985-07-22'],
            ['name' => 'Caroline Njau', 'email' => 'caroline.njau@demo.com', 'telephone' => '+254711111103', 'dob' => '1995-11-05'],
            ['name' => 'Daniel Mwenda', 'email' => 'daniel.mwenda@demo.com', 'telephone' => '+254711111104', 'dob' => '1988-01-30'],
            ['name' => 'Esther Achieng','email' => 'esther.achieng@demo.com','telephone' => '+254711111105', 'dob' => '1992-09-18'],
        ];

        foreach ($patients as $p) {
            User::firstOrCreate(['email' => $p['email']], array_merge($p, [
                'password'     => Hash::make('Patient@123'),
                'account_type' => 1,
                'is_active'    => 1,
                'address'      => 'Nairobi, Kenya',
            ]));
        }

        // Extra doctors
        $extraDoctors = [
            [
                'name'             => 'Dr. Fatuma Hassan',
                'email'            => 'fatuma.hassan@docfinder.com',
                'telephone'        => '+254778901234',
                'address'          => 'Mombasa Medical Centre, Mombasa',
                'professional_bio' => 'Dr. Fatuma Hassan is a specialist in gynecology and obstetrics with 12 years of experience in maternal and reproductive health.',
                'licence_number'   => 'MD001240',
                'profile_image'    => 'https://randomuser.me/api/portraits/women/33.jpg',
                'specialty'        => 'Obstetrics & Gynecology',
            ],
            [
                'name'             => 'Dr. Peter Njoroge',
                'email'            => 'peter.njoroge@docfinder.com',
                'telephone'        => '+254789012345',
                'address'          => 'Kisumu Eye Institute, Kisumu',
                'professional_bio' => 'Dr. Peter Njoroge is an ophthalmologist specializing in cataract surgery and laser eye treatments.',
                'licence_number'   => 'MD001241',
                'profile_image'    => 'https://randomuser.me/api/portraits/men/58.jpg',
                'specialty'        => 'Ophthalmologist',
            ],
            [
                'name'             => 'Dr. Lucy Wambua',
                'email'            => 'lucy.wambua@docfinder.com',
                'telephone'        => '+254790123456',
                'address'          => 'Eldoret Neurological Center, Eldoret',
                'professional_bio' => 'Dr. Lucy Wambua is a neurologist with expertise in stroke management and epilepsy treatment.',
                'licence_number'   => 'MD001242',
                'profile_image'    => 'https://randomuser.me/api/portraits/women/18.jpg',
                'specialty'        => 'Neurologist',
            ],
        ];

        foreach ($extraDoctors as $d) {
            $specialty = $d['specialty'];
            unset($d['specialty']);

            $doctor = User::firstOrCreate(['email' => $d['email']], array_merge($d, [
                'password'     => Hash::make('Doctor@123'),
                'account_type' => 2,
                'sp_approved'  => 1,
                'is_active'    => 1,
            ]));

            $spec = Specialization::firstOrCreate(
                ['specialization_name' => $specialty],
                ['specialization_description' => $specialty . ' specialist', 'is_active' => 1, 'is_active_for_facility' => 1]
            );

            UserSpecialization::firstOrCreate(['user_id' => $doctor->id, 'specialization_id' => $spec->id]);
        }
    }

    // -------------------------------------------------------------------------
    // FACILITIES
    // -------------------------------------------------------------------------
    private function seedFacilities(): void
    {
        $facilityTypeId  = DB::table('facility_types')->where('slug', 'hospitals')->value('id');
        $clinicTypeId    = DB::table('facility_types')->where('slug', 'clinics')->value('id');
        $level4Id        = DB::table('facility_levels')->where('level_number', 4)->value('id');
        $level5Id        = DB::table('facility_levels')->where('level_number', 5)->value('id');
        $level2Id        = DB::table('facility_levels')->where('level_number', 2)->value('id');
        $jubileeId       = DB::table('insurances')->where('name', 'JUBILEE INSURANCE')->value('id');
        $aarId           = DB::table('insurances')->where('name', 'AAR INSURANCE')->value('id');
        $britamId        = DB::table('insurances')->where('name', 'BRITAM INSURANCE')->value('id');
        $madisonId       = DB::table('insurances')->where('name', 'MADISON INSURANCE')->value('id');
        $cicId           = DB::table('insurances')->where('name', 'CIC INSURANCE')->value('id');

        $facilities = [
            [
                'facility_name'     => 'Nairobi Premier Hospital',
                'facility_profile'  => 'A leading referral hospital in Nairobi offering comprehensive specialist medical services. Equipped with state-of-the-art diagnostic and surgical facilities.',
                'facility_phone'    => '+254202345678',
                'facility_email'    => 'info@nairobipremierhospital.co.ke',
                'facility_location' => 'Upper Hill, Nairobi',
                'is_active'         => 1,
                'facility_type_id'  => $facilityTypeId,
                'facility_level_id' => $level5Id,
                'specializations'   => ['Cardiologist', 'Orthopedic', 'Pediatrician', 'Neurologist'],
                'insurances'        => array_filter([$jubileeId, $aarId, $britamId]),
            ],
            [
                'facility_name'     => 'Westlands Family Clinic',
                'facility_profile'  => 'A family-centered outpatient clinic providing quality primary and preventive healthcare to individuals and families across all age groups.',
                'facility_phone'    => '+254203456789',
                'facility_email'    => 'contact@westlandsclinic.co.ke',
                'facility_location' => 'Westlands, Nairobi',
                'is_active'         => 1,
                'facility_type_id'  => $clinicTypeId,
                'facility_level_id' => $level2Id,
                'specializations'   => ['General Care', 'Pediatrician'],
                'insurances'        => array_filter([$jubileeId, $madisonId, $cicId]),
            ],
            [
                'facility_name'     => 'Mombasa Coastal Medical Centre',
                'facility_profile'  => 'The leading healthcare provider along the Kenyan coast, offering full-spectrum medical services with a dedicated maternity wing and ICU.',
                'facility_phone'    => '+254412345678',
                'facility_email'    => 'info@coastalmedical.co.ke',
                'facility_location' => 'Nyali, Mombasa',
                'is_active'         => 1,
                'facility_type_id'  => $facilityTypeId,
                'facility_level_id' => $level4Id,
                'specializations'   => ['Obstetrics & Gynecology', 'General Care', 'Dermatologist'],
                'insurances'        => array_filter([$jubileeId, $aarId]),
            ],
            [
                'facility_name'     => 'Kisumu Eye & ENT Specialty Center',
                'facility_profile'  => 'Specialized eye, ear, nose and throat centre offering diagnosis and treatment of sensory organ conditions. Home to the most advanced ophthalmic equipment in Western Kenya.',
                'facility_phone'    => '+254572345678',
                'facility_email'    => 'appointments@kisumueyeent.co.ke',
                'facility_location' => 'Milimani, Kisumu',
                'is_active'         => 1,
                'facility_type_id'  => DB::table('facility_types')->where('slug', 'specialty-centers')->value('id'),
                'facility_level_id' => $level4Id,
                'specializations'   => ['Ophthalmologist'],
                'insurances'        => array_filter([$britamId, $madisonId]),
            ],
            [
                'facility_name'     => 'Karen Dental & Orthodontics',
                'facility_profile'  => 'A premium dental practice in Karen offering cosmetic dentistry, orthodontics, implants, and general dental care in a comfortable, modern environment.',
                'facility_phone'    => '+254202678901',
                'facility_email'    => 'smile@karendental.co.ke',
                'facility_location' => 'Karen, Nairobi',
                'is_active'         => 1,
                'facility_type_id'  => $clinicTypeId,
                'facility_level_id' => $level2Id,
                'specializations'   => ['Dentist'],
                'insurances'        => array_filter([$jubileeId, $cicId]),
            ],
        ];

        foreach ($facilities as $data) {
            $specializations = $data['specializations'];
            $insuranceIds    = $data['insurances'];
            unset($data['specializations'], $data['insurances']);

            $facility = Facility::firstOrCreate(
                ['facility_name' => $data['facility_name']],
                $data
            );

            // Attach specializations
            foreach ($specializations as $specName) {
                $spec = Specialization::where('specialization_name', $specName)->first();
                if ($spec) {
                    FacilitySpeciality::firstOrCreate([
                        'facility_id'  => $facility->id,
                        'speciality_id' => $spec->id,
                    ]);
                }
            }

            // Attach insurances
            foreach ($insuranceIds as $insId) {
                if ($insId) {
                    DB::table('facility_insurances')->updateOrInsert(
                        ['facility_id' => $facility->id, 'insurance_id' => $insId],
                        ['created_at' => now(), 'updated_at' => now()]
                    );
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // APPOINTMENTS
    // -------------------------------------------------------------------------
    private function seedAppointments(): void
    {
        $doctorEmails = [
            'sarah.johnson@docfinder.com',
            'michael.ochieng@docfinder.com',
            'grace.wanjiku@docfinder.com',
            'james.mwangi@docfinder.com',
            'fatuma.hassan@docfinder.com',
            'peter.njoroge@docfinder.com',
        ];

        $doctors = User::whereIn('email', $doctorEmails)->get()->keyBy('email');

        $appointments = [
            [
                'doctor_email'       => 'sarah.johnson@docfinder.com',
                'patient_name'       => 'Alice Kamau',
                'patient_email'      => 'alice.kamau@demo.com',
                'patient_telephone'  => '+254711111101',
                'patient_location'   => 'Karen, Nairobi',
                'appointment_date'   => Carbon::now()->addDays(2)->toDateString(),
                'appointment_time'   => '09:00:00',
                'consultation_type'  => 'in_person',
                'status'             => 'confirmed',
                'notes'              => 'Annual cardiac check-up. Patient has family history of hypertension.',
            ],
            [
                'doctor_email'       => 'michael.ochieng@docfinder.com',
                'patient_name'       => 'Brian Otieno',
                'patient_email'      => 'brian.otieno@demo.com',
                'patient_telephone'  => '+254711111102',
                'patient_location'   => 'Westlands, Nairobi',
                'appointment_date'   => Carbon::now()->addDays(3)->toDateString(),
                'appointment_time'   => '10:30:00',
                'consultation_type'  => 'online',
                'status'             => 'pending',
                'notes'              => 'Follow-up consultation for recurring headaches.',
                'google_meet_link'   => 'https://meet.google.com/demo-link-001',
            ],
            [
                'doctor_email'       => 'grace.wanjiku@docfinder.com',
                'patient_name'       => 'Caroline Njau',
                'patient_email'      => 'caroline.njau@demo.com',
                'patient_telephone'  => '+254711111103',
                'patient_location'   => 'Kilimani, Nairobi',
                'appointment_date'   => Carbon::now()->addDays(1)->toDateString(),
                'appointment_time'   => '14:00:00',
                'consultation_type'  => 'in_person',
                'status'             => 'confirmed',
                'notes'              => 'Routine check-up for 2-year-old child. Vaccination due.',
            ],
            [
                'doctor_email'       => 'james.mwangi@docfinder.com',
                'patient_name'       => 'Daniel Mwenda',
                'patient_email'      => 'daniel.mwenda@demo.com',
                'patient_telephone'  => '+254711111104',
                'patient_location'   => 'Runda, Nairobi',
                'appointment_date'   => Carbon::now()->subDays(5)->toDateString(),
                'appointment_time'   => '11:00:00',
                'consultation_type'  => 'in_person',
                'status'             => 'completed',
                'notes'              => 'Skin rash evaluation. Patient reported itching for 2 weeks.',
            ],
            [
                'doctor_email'       => 'fatuma.hassan@docfinder.com',
                'patient_name'       => 'Esther Achieng',
                'patient_email'      => 'esther.achieng@demo.com',
                'patient_telephone'  => '+254711111105',
                'patient_location'   => 'Mombasa Road, Nairobi',
                'appointment_date'   => Carbon::now()->addDays(7)->toDateString(),
                'appointment_time'   => '08:30:00',
                'consultation_type'  => 'in_person',
                'status'             => 'pending',
                'notes'              => 'First prenatal visit. Last period was 8 weeks ago.',
            ],
            [
                'doctor_email'       => 'peter.njoroge@docfinder.com',
                'patient_name'       => 'Alice Kamau',
                'patient_email'      => 'alice.kamau@demo.com',
                'patient_telephone'  => '+254711111101',
                'patient_location'   => 'Karen, Nairobi',
                'appointment_date'   => Carbon::now()->subDays(10)->toDateString(),
                'appointment_time'   => '15:00:00',
                'consultation_type'  => 'in_person',
                'status'             => 'completed',
                'notes'              => 'Annual eye examination. Patient wears corrective lenses.',
            ],
            [
                'doctor_email'       => 'sarah.johnson@docfinder.com',
                'patient_name'       => 'Brian Otieno',
                'patient_email'      => 'brian.otieno@demo.com',
                'patient_telephone'  => '+254711111102',
                'patient_location'   => 'Westlands, Nairobi',
                'appointment_date'   => Carbon::now()->subDays(3)->toDateString(),
                'appointment_time'   => '10:00:00',
                'consultation_type'  => 'online',
                'status'             => 'cancelled',
                'notes'              => 'Cancelled by patient due to emergency travel.',
                'google_meet_link'   => 'https://meet.google.com/demo-link-002',
            ],
            [
                'doctor_email'       => 'michael.ochieng@docfinder.com',
                'patient_name'       => 'Caroline Njau',
                'patient_email'      => 'caroline.njau@demo.com',
                'patient_telephone'  => '+254711111103',
                'patient_location'   => 'Kilimani, Nairobi',
                'appointment_date'   => Carbon::now()->addDays(5)->toDateString(),
                'appointment_time'   => '16:00:00',
                'consultation_type'  => 'in_person',
                'status'             => 'confirmed',
                'notes'              => 'Blood pressure management consultation.',
            ],
        ];

        foreach ($appointments as $appt) {
            $doctor = $doctors[$appt['doctor_email']] ?? null;
            if (!$doctor) continue;

            $existing = Appointment::where('doctor_id', $doctor->id)
                ->where('patient_email', $appt['patient_email'])
                ->where('appointment_date', $appt['appointment_date'])
                ->first();

            if (!$existing) {
                Appointment::create(array_merge(
                    ['doctor_id' => $doctor->id],
                    collect($appt)->except('doctor_email')->toArray()
                ));
            }
        }
    }

    // -------------------------------------------------------------------------
    // PHARMACIES
    // -------------------------------------------------------------------------
    private function seedPharmacies(): void
    {
        $pharmacies = [
            [
                'pharmacy_name'        => 'MediPlus Pharmacy',
                'pharmacy_description' => 'A fully stocked modern pharmacy with qualified pharmacists available round the clock. We stock both branded and generic medicines.',
                'pharmacy_location'    => 'Kimathi Street, Nairobi CBD',
                'pharmacy_tags'        => 'pharmacy,medicines,24hr',
                'pharmacy_privacy'     => 'public',
                'require_approval'     => false,
            ],
            [
                'pharmacy_name'        => 'Goodlife Chemist - Westlands',
                'pharmacy_description' => 'Part of the trusted Goodlife Chemist chain. Offering a wide range of pharmaceuticals, health & beauty products, and professional advice.',
                'pharmacy_location'    => 'Sarit Centre, Westlands, Nairobi',
                'pharmacy_tags'        => 'pharmacy,chemist,health,beauty',
                'pharmacy_privacy'     => 'public',
                'require_approval'     => false,
            ],
            [
                'pharmacy_name'        => 'Coast Pharmacy & Health Store',
                'pharmacy_description' => 'Mombasa\'s trusted pharmacy serving the coastal community for over 20 years. Prescription and OTC medicines available.',
                'pharmacy_location'    => 'Digo Road, Mombasa',
                'pharmacy_tags'        => 'pharmacy,mombasa,prescription',
                'pharmacy_privacy'     => 'public',
                'require_approval'     => false,
            ],
        ];

        foreach ($pharmacies as $p) {
            Pharmacy::firstOrCreate(['pharmacy_name' => $p['pharmacy_name']], $p);
        }
    }

    // -------------------------------------------------------------------------
    // PRODUCTS (pharmacy products)
    // -------------------------------------------------------------------------
    private function seedProducts(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        $products = [
            [
                'product_name'        => 'Omron Blood Pressure Monitor',
                'product_description' => 'Clinically validated automatic upper arm blood pressure monitor with irregular heartbeat detection. Easy-to-use one-touch operation.',
                'product_location'    => 'Nairobi',
                'product_price'       => 8500.00,
                'product_tags'        => 'blood pressure,monitor,omron,hypertension',
            ],
            [
                'product_name'        => 'Accu-Chek Active Glucose Meter Kit',
                'product_description' => 'Complete blood glucose monitoring kit for diabetes management. Includes meter, 50 test strips, lancing device, and 10 lancets.',
                'product_location'    => 'Nairobi',
                'product_price'       => 3200.00,
                'product_tags'        => 'glucose,diabetes,blood sugar,monitor',
            ],
            [
                'product_name'        => 'Digital Infrared Thermometer',
                'product_description' => 'Non-contact forehead thermometer with 1-second reading. Suitable for all ages. Temperature memory and fever alert.',
                'product_location'    => 'Nairobi',
                'product_price'       => 1800.00,
                'product_tags'        => 'thermometer,fever,temperature,infrared',
            ],
            [
                'product_name'        => 'Pulse Oximeter - Fingertip',
                'product_description' => 'Portable fingertip pulse oximeter measuring blood oxygen saturation (SpO2) and pulse rate. Includes lanyard and batteries.',
                'product_location'    => 'Nairobi',
                'product_price'       => 2200.00,
                'product_tags'        => 'oximeter,oxygen,pulse,SpO2',
            ],
            [
                'product_name'        => 'First Aid Kit - Deluxe 100pc',
                'product_description' => 'Comprehensive 100-piece first aid kit for home and travel. Includes bandages, antiseptics, scissors, gloves, and emergency guide.',
                'product_location'    => 'Nairobi',
                'product_price'       => 2800.00,
                'product_tags'        => 'first aid,emergency,bandage,kit',
            ],
            [
                'product_name'        => 'Digital Weighing Scale - Body',
                'product_description' => 'High-precision digital body weight scale with BMI calculation, auto-on, and 180kg capacity. Slim tempered glass design.',
                'product_location'    => 'Nairobi',
                'product_price'       => 3500.00,
                'product_tags'        => 'scale,weight,BMI,body',
            ],
            [
                'product_name'        => 'Surgical Face Masks - Box of 50',
                'product_description' => 'Disposable 3-ply surgical face masks providing protection against dust, pollen, and respiratory droplets. Individually packed.',
                'product_location'    => 'Nairobi',
                'product_price'       => 650.00,
                'product_tags'        => 'mask,protection,surgical,disposable',
            ],
            [
                'product_name'        => 'Latex Examination Gloves - Box of 100',
                'product_description' => 'Powder-free latex examination gloves offering protection and tactile sensitivity. Available in S, M, L sizes.',
                'product_location'    => 'Nairobi',
                'product_price'       => 900.00,
                'product_tags'        => 'gloves,latex,examination,protection',
            ],
        ];

        foreach ($products as $p) {
            Product::firstOrCreate(
                ['product_name' => $p['product_name']],
                array_merge($p, ['created_by' => $adminId, 'updated_by' => $adminId])
            );
        }
    }

    // -------------------------------------------------------------------------
    // MEDICINES
    // -------------------------------------------------------------------------
    private function seedMedicines(): void
    {
        $painCat    = MedicineCategory::where('name', 'Medical Conditions')->first();
        $vitaminCat = MedicineCategory::where('name', 'Vitamins and Supplements')->first();

        $painSubcat = $painCat
            ? MedicineSubcategory::where('category_id', $painCat->id)->where('name', 'Pain Relief')->first()
            : null;
        $stomachSubcat = $painCat
            ? MedicineSubcategory::where('category_id', $painCat->id)->where('name', 'Stomach Care')->first()
            : null;
        $coughSubcat = $painCat
            ? MedicineSubcategory::where('category_id', $painCat->id)->where('name', 'Cough/Cold/Flu')->first()
            : null;
        $vitaminSubcat = $vitaminCat
            ? MedicineSubcategory::where('category_id', $vitaminCat->id)->where('name', 'Multivitamins')->first()
            : null;
        $vitCSubcat = $vitaminCat
            ? MedicineSubcategory::where('category_id', $vitaminCat->id)->where('name', 'Vitamin C')->first()
            : null;

        $fallbackCatId = $painCat ? $painCat->id : MedicineCategory::first()?->id ?? 1;

        $medicines = [
            [
                'name'                   => 'Paracetamol 500mg',
                'slug'                   => 'paracetamol-500mg',
                'description'            => 'Analgesic and antipyretic for relief of mild to moderate pain and fever. Suitable for adults and children over 12.',
                'medicine_number'        => 'MED-001',
                'cost'                   => 50.00,
                'image'                  => 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => $painSubcat?->id,
                'manufacturer'           => 'Dawa Limited',
                'strength'               => '500mg',
                'form'                   => 'tablet',
                'quantity_available'     => 500,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => ['Fever', 'Headache', 'Muscle Pain'],
            ],
            [
                'name'                   => 'Ibuprofen 400mg',
                'slug'                   => 'ibuprofen-400mg',
                'description'            => 'Non-steroidal anti-inflammatory drug (NSAID) for pain, fever, and inflammation. Take with food or milk.',
                'medicine_number'        => 'MED-002',
                'cost'                   => 80.00,
                'image'                  => 'https://images.unsplash.com/photo-1550159930-40066082a4fc?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => $painSubcat?->id,
                'manufacturer'           => 'Reckitt',
                'strength'               => '400mg',
                'form'                   => 'tablet',
                'quantity_available'     => 300,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => ['Arthritis', 'Back Pain', 'Fever'],
            ],
            [
                'name'                   => 'Amoxicillin 500mg',
                'slug'                   => 'amoxicillin-500mg',
                'description'            => 'Broad-spectrum penicillin antibiotic for bacterial infections including chest, ear, and urinary tract infections.',
                'medicine_number'        => 'MED-003',
                'cost'                   => 150.00,
                'image'                  => 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'GlaxoSmithKline',
                'strength'               => '500mg',
                'form'                   => 'capsule',
                'quantity_available'     => 200,
                'is_active'              => true,
                'requires_prescription'  => true,
                'conditions'             => ['Pneumonia', 'Bronchitis', 'Ear Pain'],
            ],
            [
                'name'                   => 'Metformin 500mg',
                'slug'                   => 'metformin-500mg',
                'description'            => 'First-line medication for type 2 diabetes. Reduces glucose production in the liver and improves insulin sensitivity.',
                'medicine_number'        => 'MED-004',
                'cost'                   => 120.00,
                'image'                  => 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'Merck',
                'strength'               => '500mg',
                'form'                   => 'tablet',
                'quantity_available'     => 400,
                'is_active'              => true,
                'requires_prescription'  => true,
                'conditions'             => ['Diabetes'],
            ],
            [
                'name'                   => 'Amlodipine 5mg',
                'slug'                   => 'amlodipine-5mg',
                'description'            => 'Calcium channel blocker for high blood pressure and coronary artery disease. Once-daily dosing.',
                'medicine_number'        => 'MED-005',
                'cost'                   => 200.00,
                'image'                  => 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'Pfizer',
                'strength'               => '5mg',
                'form'                   => 'tablet',
                'quantity_available'     => 350,
                'is_active'              => true,
                'requires_prescription'  => true,
                'conditions'             => ['Hypertension', 'Heart Disease'],
            ],
            [
                'name'                   => 'Salbutamol 2.5mg Nebules',
                'slug'                   => 'salbutamol-25mg-nebules',
                'description'            => 'Bronchodilator for treatment and prevention of bronchospasm in asthma and COPD. For use with a nebulizer.',
                'medicine_number'        => 'MED-006',
                'cost'                   => 350.00,
                'image'                  => 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'Allen & Hanburys',
                'strength'               => '2.5mg/2.5ml',
                'form'                   => 'nebule',
                'quantity_available'     => 150,
                'is_active'              => true,
                'requires_prescription'  => true,
                'conditions'             => ['Asthma', 'Shortness of Breath'],
            ],
            [
                'name'                   => 'Omeprazole 20mg',
                'slug'                   => 'omeprazole-20mg',
                'description'            => 'Proton pump inhibitor for gastric ulcers, GERD, and acid reflux. Take 30 minutes before meals.',
                'medicine_number'        => 'MED-007',
                'cost'                   => 180.00,
                'image'                  => 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => $stomachSubcat?->id,
                'manufacturer'           => 'AstraZeneca',
                'strength'               => '20mg',
                'form'                   => 'capsule',
                'quantity_available'     => 250,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => ['Gastritis', 'Abdominal Pain'],
            ],
            [
                'name'                   => 'Cetirizine 10mg',
                'slug'                   => 'cetirizine-10mg',
                'description'            => 'Second-generation antihistamine for allergic rhinitis, urticaria, and seasonal allergies. Non-drowsy formula.',
                'medicine_number'        => 'MED-008',
                'cost'                   => 60.00,
                'image'                  => 'https://images.unsplash.com/photo-1585435421671-7e4ff95e8bf8?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'UCB Pharma',
                'strength'               => '10mg',
                'form'                   => 'tablet',
                'quantity_available'     => 600,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => ['Allergies', 'Skin Rash'],
            ],
            [
                'name'                   => 'Benylin Cough Syrup 200ml',
                'slug'                   => 'benylin-cough-syrup-200ml',
                'description'            => 'Effective cough suppressant and expectorant for dry and productive coughs. Suitable for adults and children over 12.',
                'medicine_number'        => 'MED-009',
                'cost'                   => 420.00,
                'image'                  => 'https://images.unsplash.com/photo-1553498898-8f6d29b3a6f5?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => $coughSubcat?->id,
                'manufacturer'           => 'Johnson & Johnson',
                'strength'               => '6.1mg/5ml',
                'form'                   => 'syrup',
                'quantity_available'     => 180,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => ['Cough', 'Cold', 'Flu'],
            ],
            [
                'name'                   => 'Centrum Multivitamin (30 tabs)',
                'slug'                   => 'centrum-multivitamin-30-tabs',
                'description'            => 'Complete daily multivitamin with 24 essential vitamins and minerals to support energy, immunity, and overall wellness.',
                'medicine_number'        => 'MED-010',
                'cost'                   => 1200.00,
                'image'                  => 'https://images.unsplash.com/photo-1560472355-536de3962603?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $vitaminCat ? $vitaminCat->id : $fallbackCatId,
                'subcategory_id'         => $vitaminSubcat?->id,
                'manufacturer'           => 'Pfizer Consumer Healthcare',
                'strength'               => 'Standard adult dose',
                'form'                   => 'tablet',
                'quantity_available'     => 300,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => [],
            ],
            [
                'name'                   => 'Vitamin C 1000mg Effervescent',
                'slug'                   => 'vitamin-c-1000mg-effervescent',
                'description'            => 'High-dose effervescent Vitamin C tablet for immune support and antioxidant protection. Orange flavor.',
                'medicine_number'        => 'MED-011',
                'cost'                   => 850.00,
                'image'                  => 'https://images.unsplash.com/photo-1578496479932-143f3d13f621?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $vitaminCat ? $vitaminCat->id : $fallbackCatId,
                'subcategory_id'         => $vitCSubcat?->id,
                'manufacturer'           => 'Bayer',
                'strength'               => '1000mg',
                'form'                   => 'effervescent tablet',
                'quantity_available'     => 400,
                'is_active'              => true,
                'requires_prescription'  => false,
                'conditions'             => [],
            ],
            [
                'name'                   => 'Artemether/Lumefantrine 20/120mg',
                'slug'                   => 'artemether-lumefantrine-20-120mg',
                'description'            => 'Combination antimalarial therapy (Coartem). First-line treatment for uncomplicated Plasmodium falciparum malaria.',
                'medicine_number'        => 'MED-012',
                'cost'                   => 380.00,
                'image'                  => 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&h=400&fit=crop&auto=format',
                'category_id'            => $fallbackCatId,
                'subcategory_id'         => null,
                'manufacturer'           => 'Novartis',
                'strength'               => '20mg/120mg',
                'form'                   => 'tablet',
                'quantity_available'     => 220,
                'is_active'              => true,
                'requires_prescription'  => true,
                'conditions'             => ['Fever', 'Malaria'],
            ],
        ];

        foreach ($medicines as $m) {
            $existing = Medicine::where('medicine_number', $m['medicine_number'])->first();
            if (!$existing) {
                Medicine::create($m); // model cast handles array→JSON encoding
            }
        }
    }

    // -------------------------------------------------------------------------
    // MEDICAL PRODUCTS
    // -------------------------------------------------------------------------
    private function seedMedicalProducts(): void
    {
        $cat    = MedicineCategory::where('name', 'Medical Devices')->first();
        $catId  = $cat?->id;

        $products = [
            [
                'name'               => 'Stethoscope - Littmann Classic III',
                'description'        => 'Dual-head stethoscope suitable for general examination. Excellent acoustic quality with tunable diaphragm technology.',
                'batch_no'           => 'BP-LIT-2025-001',
                'category'           => 'Medical Devices',
                'category_id'        => $catId,
                'cost'               => 15000.00,
                'stock_quantity'     => 25,
                'manufacturer'       => '3M Littmann',
                'expiry_date'        => null,
                'needs_prescription' => false,
                'is_available'       => true,
                'dosage_form'        => 'device',
                'status'             => 'active',
                'conditions'         => [],
                'side_effects'       => [],
                'ingredients'        => [],
            ],
            [
                'name'               => 'Nebulizer Machine - Portable',
                'description'        => 'Compact ultrasonic nebulizer for delivering liquid medication as a mist to the lungs. Ideal for asthma and COPD patients.',
                'batch_no'           => 'BP-NEB-2025-002',
                'category'           => 'Medical Devices',
                'category_id'        => $catId,
                'cost'               => 6500.00,
                'stock_quantity'     => 40,
                'manufacturer'       => 'Omron Healthcare',
                'expiry_date'        => null,
                'needs_prescription' => false,
                'is_available'       => true,
                'dosage_form'        => 'device',
                'status'             => 'active',
                'conditions'         => ['Asthma'],
                'side_effects'       => [],
                'ingredients'        => [],
            ],
            [
                'name'               => 'Insulin Syringes 1ml U100 (100pk)',
                'description'        => 'Sterile, single-use insulin syringes with integrated needle for precise insulin delivery. U-100 calibration.',
                'batch_no'           => 'BP-INS-2025-003',
                'category'           => 'Medical Devices',
                'category_id'        => $catId,
                'cost'               => 1200.00,
                'stock_quantity'     => 200,
                'manufacturer'       => 'BD Medical',
                'expiry_date'        => Carbon::now()->addYears(3)->toDateString(),
                'needs_prescription' => true,
                'is_available'       => true,
                'dosage_form'        => 'syringe',
                'status'             => 'active',
                'conditions'         => ['Diabetes'],
                'side_effects'       => [],
                'ingredients'        => [],
            ],
            [
                'name'               => 'Wound Dressing Set - Sterile',
                'description'        => 'Complete sterile wound care kit with gauze pads, adhesive bandages, antiseptic wipes, and medical tape.',
                'batch_no'           => 'BP-WDS-2025-004',
                'category'           => 'Emergency and First Aid',
                'category_id'        => null,
                'cost'               => 850.00,
                'stock_quantity'     => 150,
                'manufacturer'       => 'Smith & Nephew',
                'expiry_date'        => Carbon::now()->addYears(2)->toDateString(),
                'needs_prescription' => false,
                'is_available'       => true,
                'dosage_form'        => 'kit',
                'status'             => 'active',
                'conditions'         => [],
                'side_effects'       => [],
                'ingredients'        => [],
            ],
            [
                'name'               => 'Orthopaedic Knee Support Brace',
                'description'        => 'Adjustable compression knee brace providing lateral stability and meniscus support for arthritis, sports injuries, and post-surgery.',
                'batch_no'           => 'BP-KNE-2025-005',
                'category'           => 'Medical Devices',
                'category_id'        => $catId,
                'cost'               => 3200.00,
                'stock_quantity'     => 60,
                'manufacturer'       => 'Mueller Sports Medicine',
                'expiry_date'        => null,
                'needs_prescription' => false,
                'is_available'       => true,
                'dosage_form'        => 'device',
                'status'             => 'active',
                'conditions'         => ['Arthritis', 'Joint Pain'],
                'side_effects'       => [],
                'ingredients'        => [],
            ],
        ];

        foreach ($products as $p) {
            $existing = MedicalProduct::where('batch_no', $p['batch_no'])->first();
            if (!$existing) {
                MedicalProduct::create($p); // model casts handle array→JSON encoding
            }
        }
    }

    // -------------------------------------------------------------------------
    // SUPPORT GROUPS
    // -------------------------------------------------------------------------
    private function seedGroups(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        // Map group data to existing category/subcategory names from GroupCategoriesSeeder
        $groups = [
            [
                'group_name'        => 'Living Well with Diabetes Kenya',
                'group_description' => 'A safe space for people living with Type 1 and Type 2 diabetes in Kenya to share experiences, tips, recipes, and support one another on the journey to better health.',
                'group_location'    => 'Kenya (Nationwide)',
                'group_tags'        => 'diabetes,blood sugar,insulin,health',
                'group_privacy'     => 'public',
                'require_approval'  => false,
                'created_by'        => $adminId,
                'category_name'     => 'Chronic Illness & Autoimmune Conditions',
                'subcategory_name'  => 'Diabetes (Type 1 & Type 2)',
            ],
            [
                'group_name'        => 'Anxiety & Stress Support Circle',
                'group_description' => 'A compassionate community for individuals dealing with anxiety, stress, and panic disorders. Share coping strategies, breathing exercises, and encouragement.',
                'group_location'    => 'Nairobi, Kenya',
                'group_tags'        => 'anxiety,stress,mental health,support',
                'group_privacy'     => 'private',
                'require_approval'  => true,
                'created_by'        => $adminId,
                'category_name'     => 'Mental & Emotional Health',
                'subcategory_name'  => 'Depression & Anxiety',
            ],
            [
                'group_name'        => 'New Mums Network - Nairobi',
                'group_description' => 'Connect with other new and expectant mothers in Nairobi. Share pregnancy journeys, breastfeeding tips, postpartum recovery, and baby milestones in a warm supportive environment.',
                'group_location'    => 'Nairobi, Kenya',
                'group_tags'        => 'pregnancy,motherhood,postpartum,newborn',
                'group_privacy'     => 'public',
                'require_approval'  => false,
                'created_by'        => $adminId,
                'category_name'     => "Women's & Family Health",
                'subcategory_name'  => 'Postpartum & New Mothers',
            ],
            [
                'group_name'        => 'Heart Health Warriors',
                'group_description' => 'For individuals diagnosed with heart conditions, hypertension, or cardiovascular disease. Evidence-based lifestyle advice, medication questions, and emotional support from fellow warriors.',
                'group_location'    => 'Kenya',
                'group_tags'        => 'heart disease,hypertension,cardiovascular,diet',
                'group_privacy'     => 'public',
                'require_approval'  => false,
                'created_by'        => $adminId,
                'category_name'     => 'Chronic Illness & Autoimmune Conditions',
                'subcategory_name'  => 'Hypertension & Heart Disease',
            ],
            [
                'group_name'        => 'Smoke-Free Kenya - Cessation Group',
                'group_description' => 'Support group for people committed to quitting smoking and tobacco use. Share milestones, cravings management tips, and celebrate each smoke-free day together.',
                'group_location'    => 'Kenya (Nationwide)',
                'group_tags'        => 'smoking,cessation,quit,nicotine',
                'group_privacy'     => 'public',
                'require_approval'  => false,
                'created_by'        => $adminId,
                'category_name'     => 'Addiction & Recovery',
                'subcategory_name'  => 'Smoking & Vaping Cessation',
            ],
        ];

        foreach ($groups as $gData) {
            $categoryName   = $gData['category_name'];
            $subcategoryName = $gData['subcategory_name'];
            unset($gData['category_name'], $gData['subcategory_name']);

            $group = Group::firstOrCreate(['group_name' => $gData['group_name']], $gData);

            // Attach to existing category
            $catId = DB::table('group_categories')->where('name', $categoryName)->value('id');
            if ($catId) {
                DB::table('group_category_mappings')->updateOrInsert(
                    ['group_id' => $group->id, 'category_id' => $catId],
                    ['created_at' => now(), 'updated_at' => now()]
                );
            }

            // Attach to existing subcategory
            $subcatId = DB::table('group_sub_categories')->where('name', $subcategoryName)->value('id');
            if ($subcatId) {
                DB::table('group_subcategory_mappings')->updateOrInsert(
                    ['group_id' => $group->id, 'subcategory_id' => $subcatId],
                    ['created_at' => now(), 'updated_at' => now()]
                );
            }
        }
    }

    // -------------------------------------------------------------------------
    // MENTAL HEALTH MATERIALS
    // -------------------------------------------------------------------------
    private function seedMentalHealthMaterials(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        $materials = [
            [
                'title'       => 'Understanding Depression: A Beginner\'s Guide',
                'description' => 'A comprehensive PDF guide explaining what depression is, its symptoms, causes, and the most effective evidence-based treatments available. Suitable for patients and caregivers.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Mindfulness Meditation for Anxiety - 30-Day Program',
                'description' => 'A structured 30-day guided mindfulness program in video format, helping you build daily meditation habits to reduce anxiety and improve mental clarity.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 500.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Stress Management Workbook',
                'description' => 'An interactive PDF workbook with exercises, journaling prompts, and cognitive restructuring tools to help you identify stress triggers and build healthy coping strategies.',
                'file_type'   => 'pdf',
                'is_free'     => false,
                'price'       => 350.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1517971129774-8a2b38fa128e?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Sleep Hygiene & Insomnia - Expert Talk',
                'description' => 'A 45-minute expert video by a sleep specialist covering the science of sleep, common causes of insomnia, and proven techniques to improve sleep quality without medication.',
                'file_type'   => 'video',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Grief & Loss: Healing After Bereavement',
                'description' => 'A compassionate guide through the stages of grief with practical advice on processing loss, building resilience, and finding meaning after bereavement.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1573497620304-9ed4f55db3b7?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Building Emotional Resilience - Masterclass',
                'description' => 'A 3-part video masterclass covering the pillars of emotional resilience, including positive psychology, social support networks, and practical resilience-building exercises.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 800.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1521175628397-9c05e873a4f4?w=600&h=400&fit=crop&auto=format',
            ],
        ];

        foreach ($materials as $m) {
            MentalHealthMaterial::firstOrCreate(['title' => $m['title']], $m);
        }
    }

    // -------------------------------------------------------------------------
    // DEPRESSION SCREENINGS (PHQ-2 sample)
    // -------------------------------------------------------------------------
    private function seedDepressionScreenings(): void
    {
        $patients = User::whereIn('email', [
            'alice.kamau@demo.com',
            'brian.otieno@demo.com',
            'caroline.njau@demo.com',
        ])->get();

        $sampleScreenings = [
            ['q1' => 1, 'q2' => 2, 'answers' => [['question' => 'Little interest or pleasure in doing things', 'score' => 1], ['question' => 'Feeling down, depressed, or hopeless', 'score' => 2]]],
            ['q1' => 3, 'q2' => 3, 'answers' => [['question' => 'Little interest or pleasure in doing things', 'score' => 3], ['question' => 'Feeling down, depressed, or hopeless', 'score' => 3]]],
            ['q1' => 0, 'q2' => 1, 'answers' => [['question' => 'Little interest or pleasure in doing things', 'score' => 0], ['question' => 'Feeling down, depressed, or hopeless', 'score' => 1]]],
        ];

        foreach ($patients as $i => $patient) {
            $screen = $sampleScreenings[$i] ?? $sampleScreenings[0];
            $existing = DepressionScreening::where('user_id', $patient->id)->first();
            if (!$existing) {
                DepressionScreening::create([
                    'user_id'     => $patient->id,
                    'q1_score'    => $screen['q1'],
                    'q2_score'    => $screen['q2'],
                    'total_score' => $screen['q1'] + $screen['q2'],
                    'answers'     => json_encode($screen['answers']),
                    'ip_address'  => '127.0.0.1',
                ]);
            }
        }
    }

    // -------------------------------------------------------------------------
    // SURVEY (PHQ-9 Depression Survey)
    // -------------------------------------------------------------------------
    private function seedSurvey(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        $survey = DB::table('surveys')->where('slug', 'phq-9-depression-screening')->first();
        if ($survey) return;

        $surveyId = DB::table('surveys')->insertGetId([
            'title'        => 'PHQ-9 Depression Screening',
            'description'  => 'The Patient Health Questionnaire-9 (PHQ-9) is a validated tool for screening, diagnosing, monitoring, and measuring the severity of depression.',
            'instructions' => 'Over the last 2 weeks, how often have you been bothered by any of the following problems? Answer as honestly as possible.',
            'slug'         => 'phq-9-depression-screening',
            'is_active'    => true,
            'created_by'   => $adminId,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $questions = [
            'Little interest or pleasure in doing things',
            'Feeling down, depressed, or hopeless',
            'Trouble falling or staying asleep, or sleeping too much',
            'Feeling tired or having little energy',
            'Poor appetite or overeating',
            'Feeling bad about yourself — or that you are a failure or have let yourself or your family down',
            'Trouble concentrating on things, such as reading the newspaper or watching television',
            'Moving or speaking so slowly that other people could have noticed, or the opposite — being so fidgety or restless that you have been moving around a lot more than usual',
            'Thoughts that you would be better off dead, or thoughts of hurting yourself in some way',
        ];

        $options = [
            ['label' => 'Not at all',        'score_value' => 0, 'color' => 'green',  'order_index' => 0],
            ['label' => 'Several days',       'score_value' => 1, 'color' => 'yellow', 'order_index' => 1],
            ['label' => 'More than half the days', 'score_value' => 2, 'color' => 'orange', 'order_index' => 2],
            ['label' => 'Nearly every day',  'score_value' => 3, 'color' => 'red',    'order_index' => 3],
        ];

        foreach ($questions as $idx => $qText) {
            $questionId = DB::table('survey_questions')->insertGetId([
                'survey_id'     => $surveyId,
                'question_text' => $qText,
                'order_index'   => $idx,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            foreach ($options as $opt) {
                DB::table('survey_options')->insert([
                    'question_id' => $questionId,
                    'label'       => $opt['label'],
                    'score_value' => $opt['score_value'],
                    'color'       => $opt['color'],
                    'order_index' => $opt['order_index'],
                ]);
            }
        }

        // Result bands
        $bands = [
            ['label' => 'Minimal Depression',  'min' => 0,  'max' => 4,  'type' => 'low',      'cta' => false, 'order' => 0, 'message' => 'Your responses suggest minimal or no depression. Continue maintaining healthy lifestyle habits like regular exercise, good sleep, and social connections.'],
            ['label' => 'Mild Depression',     'min' => 5,  'max' => 9,  'type' => 'low',      'cta' => false, 'order' => 1, 'message' => 'Your responses suggest mild depression. Consider monitoring your mood and implementing self-care strategies. Speak with your GP if symptoms persist.'],
            ['label' => 'Moderate Depression', 'min' => 10, 'max' => 14, 'type' => 'moderate', 'cta' => true,  'order' => 2, 'message' => 'Your responses suggest moderate depression. We recommend speaking with a healthcare professional. A therapist or counsellor can provide effective support.'],
            ['label' => 'Moderately Severe',   'min' => 15, 'max' => 19, 'type' => 'high',     'cta' => true,  'order' => 3, 'message' => 'Your responses suggest moderately severe depression. It is important to consult a doctor or mental health professional as soon as possible for proper diagnosis and treatment.'],
            ['label' => 'Severe Depression',   'min' => 20, 'max' => 27, 'type' => 'high',     'cta' => true,  'order' => 4, 'message' => 'Your responses suggest severe depression. Please reach out to a mental health professional or emergency services immediately. You are not alone — help is available.'],
        ];

        $materials = MentalHealthMaterial::where('is_active', true)->get()->keyBy('title');

        foreach ($bands as $band) {
            $bandId = DB::table('survey_result_bands')->insertGetId([
                'survey_id'         => $surveyId,
                'label'             => $band['label'],
                'min_score'         => $band['min'],
                'max_score'         => $band['max'],
                'message'           => $band['message'],
                'result_type'       => $band['type'],
                'show_therapist_cta'=> $band['cta'],
                'order_index'       => $band['order'],
            ]);

            // Link relevant materials to bands
            if ($band['type'] === 'moderate' || $band['type'] === 'high') {
                $mat1 = $materials->get('Understanding Depression: A Beginner\'s Guide');
                $mat2 = $materials->get('Mindfulness Meditation for Anxiety - 30-Day Program');
                if ($mat1) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat1->id]);
                if ($mat2) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat2->id]);
            } elseif ($band['type'] === 'low') {
                $mat3 = $materials->get('Sleep Hygiene & Insomnia - Expert Talk');
                if ($mat3) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat3->id]);
            }
        }

        // Seed a sample survey response
        $patient = User::where('email', 'alice.kamau@demo.com')->first();
        if ($patient) {
            $sampleAnswers = [];
            $totalScore = 0;
            $questionIds = DB::table('survey_questions')->where('survey_id', $surveyId)->pluck('id');
            $sampleScores = [1, 2, 1, 2, 1, 0, 1, 0, 0]; // PHQ-9 scores = 8 (mild)

            foreach ($questionIds as $idx => $qId) {
                $score = $sampleScores[$idx] ?? 0;
                $sampleAnswers[] = ['question_id' => $qId, 'score' => $score];
                $totalScore += $score;
            }

            $matchedBand = DB::table('survey_result_bands')
                ->where('survey_id', $surveyId)
                ->where('min_score', '<=', $totalScore)
                ->where('max_score', '>=', $totalScore)
                ->first();

            DB::table('survey_responses')->insert([
                'survey_id'   => $surveyId,
                'user_id'     => $patient->id,
                'total_score' => $totalScore,
                'band_id'     => $matchedBand?->id,
                'answers'     => json_encode($sampleAnswers),
                'ip_address'  => '127.0.0.1',
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);
        }
    }

    // -------------------------------------------------------------------------
    // RATINGS
    // -------------------------------------------------------------------------
    private function seedRatings(): void
    {
        $doctors  = User::where('account_type', 2)->where('sp_approved', 1)->get();
        $patients = User::whereIn('email', [
            'alice.kamau@demo.com',
            'brian.otieno@demo.com',
            'caroline.njau@demo.com',
            'daniel.mwenda@demo.com',
        ])->get();
        $facilities = Facility::where('is_active', 1)->take(3)->get();

        $doctorRatings = [
            ['overall' => 5, 'communication' => 5, 'bedside' => 5, 'waiting' => 4, 'knowledge' => 5, 'comment' => 'Excellent doctor! Very thorough and compassionate. Took time to explain everything clearly.', 'recommendation' => 'yes'],
            ['overall' => 4, 'communication' => 4, 'bedside' => 5, 'waiting' => 3, 'knowledge' => 4, 'comment' => 'Very professional and knowledgeable. Slight wait but worth it.', 'recommendation' => 'yes'],
            ['overall' => 5, 'communication' => 5, 'bedside' => 4, 'waiting' => 5, 'knowledge' => 5, 'comment' => 'Dr was amazing! Punctual, friendly, and gave me a very detailed explanation of my condition.', 'recommendation' => 'yes'],
            ['overall' => 3, 'communication' => 3, 'bedside' => 4, 'waiting' => 2, 'knowledge' => 4, 'comment' => 'Good doctor but the waiting time was quite long. Consultation itself was satisfactory.', 'recommendation' => 'maybe'],
            ['overall' => 5, 'communication' => 5, 'bedside' => 5, 'waiting' => 5, 'knowledge' => 5, 'comment' => 'Best paediatrician I have ever visited. My child is always comfortable with her.', 'recommendation' => 'yes'],
        ];

        $facilityRatings = [
            ['overall' => 4, 'cleanliness' => 5, 'staff' => 4, 'facilities' => 4, 'accessibility' => 4, 'comment' => 'Clean, modern facility with helpful staff. Parking can be a challenge on busy days.', 'recommendation' => 'yes'],
            ['overall' => 5, 'cleanliness' => 5, 'staff' => 5, 'facilities' => 5, 'accessibility' => 4, 'comment' => 'Top-notch hospital. Equipment is modern and staff are highly professional and caring.', 'recommendation' => 'yes'],
            ['overall' => 4, 'cleanliness' => 4, 'staff' => 5, 'facilities' => 3, 'accessibility' => 5, 'comment' => 'Friendly staff and very accessible location. Could benefit from newer equipment in some departments.', 'recommendation' => 'yes'],
        ];

        $ratingIdx = 0;
        foreach ($patients as $pidx => $patient) {
            foreach ($doctors->take(2) as $didx => $doctor) {
                $key = ($pidx * 2 + $didx) % count($doctorRatings);
                $r   = $doctorRatings[$key];

                $existing = Rating::where('user_id', $patient->id)
                    ->where('rateable_type', 'App\Models\User')
                    ->where('rateable_id', $doctor->id)
                    ->first();

                if (!$existing) {
                    Rating::create([
                        'user_id'               => $patient->id,
                        'rateable_type'         => 'App\Models\User',
                        'rateable_id'           => $doctor->id,
                        'overall_rating'        => $r['overall'],
                        'communication_rating'  => $r['communication'],
                        'bedside_manner_rating' => $r['bedside'],
                        'waiting_time_rating'   => $r['waiting'],
                        'knowledge_rating'      => $r['knowledge'],
                        'comment'               => $r['comment'],
                        'is_verified'           => true,
                        'is_anonymous'          => false,
                        'recommendation'        => $r['recommendation'],
                    ]);
                }
                $ratingIdx++;
            }
        }

        foreach ($patients->take(3) as $pidx => $patient) {
            foreach ($facilities->take(2) as $fidx => $facility) {
                $key = ($pidx + $fidx) % count($facilityRatings);
                $r   = $facilityRatings[$key];

                $existing = Rating::where('user_id', $patient->id)
                    ->where('rateable_type', 'App\Models\Facility')
                    ->where('rateable_id', $facility->id)
                    ->first();

                if (!$existing) {
                    Rating::create([
                        'user_id'              => $patient->id,
                        'rateable_type'        => 'App\Models\Facility',
                        'rateable_id'          => $facility->id,
                        'overall_rating'       => $r['overall'],
                        'cleanliness_rating'   => $r['cleanliness'],
                        'staff_rating'         => $r['staff'],
                        'facilities_rating'    => $r['facilities'],
                        'accessibility_rating' => $r['accessibility'],
                        'comment'              => $r['comment'],
                        'is_verified'          => false,
                        'is_anonymous'         => false,
                        'recommendation'       => $r['recommendation'],
                    ]);
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // PHARMACY ORDERS
    // -------------------------------------------------------------------------
    private function seedPharmacyOrders(): void
    {
        $patients = User::whereIn('email', [
            'alice.kamau@demo.com',
            'brian.otieno@demo.com',
            'caroline.njau@demo.com',
        ])->get();

        $orders = [
            [
                'patient'         => 'alice.kamau@demo.com',
                'customer_name'   => 'Alice Kamau',
                'customer_phone'  => '+254711111101',
                'delivery_address'=> '15 Karen Road, Karen',
                'delivery_city'   => 'Nairobi',
                'delivery_option' => 'standard',
                'delivery_fee'    => 200.00,
                'subtotal'        => 2050.00,
                'total'           => 2250.00,
                'status'          => 'paid',
                'items'           => [
                    ['id' => 1, 'name' => 'Paracetamol 500mg', 'price' => 50.00,   'quantity' => 2, 'type' => 'medicine'],
                    ['id' => 2, 'name' => 'Vitamin C 1000mg',  'price' => 850.00,  'quantity' => 2, 'type' => 'medicine'],
                    ['id' => 3, 'name' => 'Cetirizine 10mg',   'price' => 60.00,   'quantity' => 5, 'type' => 'medicine'],
                ],
            ],
            [
                'patient'         => 'brian.otieno@demo.com',
                'customer_name'   => 'Brian Otieno',
                'customer_phone'  => '+254711111102',
                'delivery_address'=> 'Westlands Medical Plaza',
                'delivery_city'   => 'Nairobi',
                'delivery_option' => 'express',
                'delivery_fee'    => 350.00,
                'subtotal'        => 4700.00,
                'total'           => 5050.00,
                'status'          => 'pending',
                'items'           => [
                    ['id' => 4, 'name' => 'Omron Blood Pressure Monitor', 'price' => 8500.00, 'quantity' => 1, 'type' => 'product'],
                    ['id' => 5, 'name' => 'Metformin 500mg',              'price' => 120.00,  'quantity' => 3, 'type' => 'medicine'],
                ],
            ],
            [
                'patient'         => 'caroline.njau@demo.com',
                'customer_name'   => 'Caroline Njau',
                'customer_phone'  => '+254711111103',
                'delivery_address'=> 'Kilimani Estate, House 22',
                'delivery_city'   => 'Nairobi',
                'delivery_option' => 'pickup',
                'delivery_fee'    => 0.00,
                'subtotal'        => 1380.00,
                'total'           => 1380.00,
                'status'          => 'paid',
                'items'           => [
                    ['id' => 6, 'name' => 'Amoxicillin 500mg',   'price' => 150.00, 'quantity' => 2, 'type' => 'medicine'],
                    ['id' => 7, 'name' => 'Centrum Multivitamin', 'price' => 1200.00,'quantity' => 1, 'type' => 'medicine'],
                ],
            ],
        ];

        foreach ($orders as $o) {
            $patient = User::where('email', $o['patient'])->first();
            $ref = 'ORD-' . strtoupper(Str::random(8));

            $existing = PharmacyOrder::where('customer_name', $o['customer_name'])
                ->where('total', $o['total'])
                ->first();

            if (!$existing) {
                PharmacyOrder::create([
                    'user_id'         => $patient?->id,
                    'order_ref'       => $ref,
                    'customer_name'   => $o['customer_name'],
                    'customer_phone'  => $o['customer_phone'],
                    'delivery_address'=> $o['delivery_address'],
                    'delivery_city'   => $o['delivery_city'],
                    'delivery_option' => $o['delivery_option'],
                    'delivery_fee'    => $o['delivery_fee'],
                    'subtotal'        => $o['subtotal'],
                    'total'           => $o['total'],
                    'status'          => $o['status'],
                    'items'           => json_encode($o['items']),
                ]);
            }
        }
    }

    // -------------------------------------------------------------------------
    // DOCTOR SUBSCRIPTIONS
    // -------------------------------------------------------------------------
    private function seedDoctorSubscriptions(): void
    {
        $doctorEmails = [
            'sarah.johnson@docfinder.com'  => 'annually',
            'michael.ochieng@docfinder.com'=> 'quarterly',
            'grace.wanjiku@docfinder.com'  => 'monthly',
            'fatuma.hassan@docfinder.com'  => 'annually',
        ];

        foreach ($doctorEmails as $email => $plan) {
            $doctor  = User::where('email', $email)->first();
            $package = SubscriptionPackage::where('slug', $plan)->first();
            if (!$doctor || !$package) continue;

            $existing = DoctorSubscription::where('user_id', $doctor->id)->where('status', 'paid')->first();
            if ($existing) continue;

            DoctorSubscription::create([
                'user_id'                => $doctor->id,
                'plan'                   => $plan,
                'amount'                 => $package->amount,
                'currency'               => 'KES',
                'payment_method'         => 'DPO',
                'status'                 => 'paid',
                'company_ref'            => 'SUB-' . strtoupper(Str::random(10)),
                'subscription_starts_at' => Carbon::now()->subDays(rand(1, 30)),
                'subscription_ends_at'   => Carbon::now()->addDays($package->duration_days - rand(1, 30)),
            ]);
        }
    }

    // -------------------------------------------------------------------------
    // DOCTOR FAVORITES
    // -------------------------------------------------------------------------
    private function seedDoctorFavorites(): void
    {
        $patients = User::whereIn('email', [
            'alice.kamau@demo.com',
            'brian.otieno@demo.com',
            'caroline.njau@demo.com',
        ])->get();

        $doctors = User::where('account_type', 2)->where('sp_approved', 1)->take(4)->get();

        foreach ($patients as $patient) {
            foreach ($doctors->take(2) as $doctor) {
                DoctorFavorite::firstOrCreate([
                    'user_id'   => $patient->id,
                    'doctor_id' => $doctor->id,
                ]);
            }
        }
    }

    // -------------------------------------------------------------------------
    // GAD-7 ANXIETY SCREENING (Screening 2)
    // -------------------------------------------------------------------------
    private function seedGad7Survey(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        if (DB::table('surveys')->where('slug', 'gad-7-anxiety-screening')->exists()) return;

        $surveyId = DB::table('surveys')->insertGetId([
            'title'        => 'GAD-7 Anxiety Screening',
            'description'  => 'The Generalized Anxiety Disorder 7-item (GAD-7) scale is a validated self-report tool used to screen for and measure the severity of generalized anxiety disorder.',
            'instructions' => 'Over the last 2 weeks, how often have you been bothered by the following problems? There are no right or wrong answers — please answer as honestly as you can.',
            'slug'         => 'gad-7-anxiety-screening',
            'is_active'    => true,
            'created_by'   => $adminId,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $questions = [
            'Feeling nervous, anxious, or on edge',
            'Not being able to stop or control worrying',
            'Worrying too much about different things',
            'Trouble relaxing',
            'Being so restless that it is hard to sit still',
            'Becoming easily annoyed or irritable',
            'Feeling afraid, as if something awful might happen',
        ];

        $options = [
            ['label' => 'Not at all',              'score_value' => 0, 'color' => 'green',  'order_index' => 0],
            ['label' => 'Several days',             'score_value' => 1, 'color' => 'yellow', 'order_index' => 1],
            ['label' => 'More than half the days',  'score_value' => 2, 'color' => 'orange', 'order_index' => 2],
            ['label' => 'Nearly every day',         'score_value' => 3, 'color' => 'red',    'order_index' => 3],
        ];

        foreach ($questions as $idx => $qText) {
            $questionId = DB::table('survey_questions')->insertGetId([
                'survey_id'     => $surveyId,
                'question_text' => $qText,
                'order_index'   => $idx,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            foreach ($options as $opt) {
                DB::table('survey_options')->insert([
                    'question_id' => $questionId,
                    'label'       => $opt['label'],
                    'score_value' => $opt['score_value'],
                    'color'       => $opt['color'],
                    'order_index' => $opt['order_index'],
                ]);
            }
        }

        // Result bands (GAD-7 clinical cut-offs)
        $bands = [
            [
                'label'   => 'Minimal Anxiety',
                'min'     => 0, 'max' => 4,
                'type'    => 'low',
                'cta'     => false,
                'order'   => 0,
                'message' => 'Your responses suggest minimal anxiety. Keep up the healthy habits — regular exercise, quality sleep, and staying connected with loved ones all support good mental wellbeing.',
            ],
            [
                'label'   => 'Mild Anxiety',
                'min'     => 5, 'max' => 9,
                'type'    => 'low',
                'cta'     => false,
                'order'   => 1,
                'message' => 'Your responses suggest mild anxiety. Consider practising relaxation techniques such as deep breathing or mindfulness. Monitoring how you feel over the coming weeks is a good idea.',
            ],
            [
                'label'   => 'Moderate Anxiety',
                'min'     => 10, 'max' => 14,
                'type'    => 'moderate',
                'cta'     => true,
                'order'   => 2,
                'message' => 'Your responses suggest moderate anxiety. We recommend speaking with a healthcare professional. Talking therapies like CBT are highly effective at this level.',
            ],
            [
                'label'   => 'Severe Anxiety',
                'min'     => 15, 'max' => 21,
                'type'    => 'high',
                'cta'     => true,
                'order'   => 3,
                'message' => 'Your responses suggest severe anxiety. Please reach out to a doctor or mental health professional as soon as possible. Effective treatments are available and seeking help is a sign of strength.',
            ],
        ];

        // Seed GAD-7 specific materials
        $gad7Materials = [
            [
                'title'       => 'Understanding Anxiety: A Complete Guide',
                'description' => 'A comprehensive PDF guide covering what anxiety is, the different types, how it affects your body and mind, and the most effective evidence-based treatments including CBT and medication.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Anxiety Management Techniques — Video Series',
                'description' => 'A 5-part video series by a clinical psychologist covering grounding exercises, progressive muscle relaxation, cognitive restructuring, and exposure techniques for managing anxiety.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 650.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'The Worry Journal: CBT Workbook for Anxiety',
                'description' => 'An interactive PDF workbook based on Cognitive Behavioural Therapy principles. Includes thought records, worry diaries, exposure hierarchies, and relapse prevention exercises.',
                'file_type'   => 'pdf',
                'is_free'     => false,
                'price'       => 400.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1517971129774-8a2b38fa128e?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Breathing & Grounding Exercises — Quick Reference',
                'description' => 'A free quick-reference PDF card with 5 proven breathing techniques (4-7-8, box breathing, diaphragmatic) and the 5-4-3-2-1 grounding exercise you can use anywhere.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=600&h=400&fit=crop&auto=format',
            ],
        ];

        $createdMaterials = [];
        foreach ($gad7Materials as $mat) {
            $existing = MentalHealthMaterial::where('title', $mat['title'])->first();
            if (!$existing) {
                $existing = MentalHealthMaterial::create($mat);
            }
            $createdMaterials[$mat['title']] = $existing->id;
        }

        // Insert bands and link materials
        foreach ($bands as $band) {
            $bandId = DB::table('survey_result_bands')->insertGetId([
                'survey_id'          => $surveyId,
                'label'              => $band['label'],
                'min_score'          => $band['min'],
                'max_score'          => $band['max'],
                'message'            => $band['message'],
                'result_type'        => $band['type'],
                'show_therapist_cta' => $band['cta'],
                'order_index'        => $band['order'],
            ]);

            // Link relevant materials to each band
            if ($band['type'] === 'high' || $band['type'] === 'moderate') {
                foreach ($createdMaterials as $materialId) {
                    DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $materialId]);
                }
            } else {
                // Low bands get free materials only
                $freeIds = [
                    $createdMaterials['Understanding Anxiety: A Complete Guide'] ?? null,
                    $createdMaterials['Breathing & Grounding Exercises — Quick Reference'] ?? null,
                ];
                foreach (array_filter($freeIds) as $materialId) {
                    DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $materialId]);
                }
            }
        }
    }
}
