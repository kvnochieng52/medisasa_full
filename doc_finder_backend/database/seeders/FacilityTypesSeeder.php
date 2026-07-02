<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FacilityTypesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $facilityTypes = [
            [
                'name' => 'Hospitals',
                'slug' => 'hospitals',
                'description' => 'General hospitals providing comprehensive medical care',
                'sort_order' => 1,
            ],
            [
                'name' => 'Labaratory & Radiology',
                'slug' => 'laboratory',
                'description' => 'Medical laboratories and radiology / imaging centres',
                'sort_order' => 2,
            ],
            [
                'name' => 'Clinics',
                'slug' => 'clinics',
                'description' => 'Outpatient medical facilities',
                'sort_order' => 3,
            ],
            [
                'name' => 'Specialty Centers',
                'slug' => 'specialty-centers',
                'description' => 'Specialized medical centers for specific conditions',
                'sort_order' => 4,
            ],
            [
                'name' => 'Urgent Care Centers',
                'slug' => 'urgent-care-centers',
                'description' => 'Walk-in medical facilities for urgent but non-emergency care',
                'sort_order' => 5,
            ],
            [
                'name' => 'Primary Health Care Centers',
                'slug' => 'primary-health-care-centers',
                'description' => 'Basic healthcare facilities serving communities',
                'sort_order' => 6,
            ],
            [
                'name' => 'Nursing Homes / Long-Term Care Facilities',
                'slug' => 'nursing-homes-long-term-care-facilities',
                'description' => 'Residential care facilities for elderly and chronic care patients',
                'sort_order' => 7,
            ],
            [
                'name' => 'Rehabilitation Centers',
                'slug' => 'rehabilitation-centers',
                'description' => 'Facilities providing physical therapy and rehabilitation services',
                'sort_order' => 8,
            ],
            [
                'name' => 'Diagnostic and Imaging Centers',
                'slug' => 'diagnostic-and-imaging-centers',
                'description' => 'Centers specializing in medical imaging and diagnostics',
                'sort_order' => 9,
            ],
            [
                'name' => 'Radiology',
                'slug' => 'radiology',
                'description' => 'Radiology and imaging facilities',
                'sort_order' => 9,
            ],
            [
                'name' => 'Pharmacies / Dispensaries',
                'slug' => 'pharmacies-dispensaries',
                'description' => 'Medication dispensing facilities',
                'sort_order' => 10,
            ],
            [
                'name' => 'Mobile Clinics',
                'slug' => 'mobile-clinics',
                'description' => 'Mobile healthcare units serving remote areas',
                'sort_order' => 11,
            ],
        ];

        foreach ($facilityTypes as $type) {
            DB::table('facility_types')->updateOrInsert(
                ['slug' => $type['slug']],
                array_merge($type, [
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );
        }
    }
}
