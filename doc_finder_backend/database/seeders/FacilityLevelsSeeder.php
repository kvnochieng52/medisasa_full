<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FacilityLevelsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $facilityLevels = [
            [
                'name' => 'Level 1: Community Health Units',
                'slug' => 'level-1-community-health-units',
                'description' => 'Basic community health units providing primary healthcare services',
                'level_number' => 1,
                'sort_order' => 1,
            ],
            [
                'name' => 'Level 2: Dispensaries, Clinics',
                'slug' => 'level-2-dispensaries-clinics',
                'description' => 'Dispensaries and clinics providing outpatient services',
                'level_number' => 2,
                'sort_order' => 2,
            ],
            [
                'name' => 'Level 3: Health Centres',
                'slug' => 'level-3-health-centres',
                'description' => 'Health centres providing comprehensive primary healthcare',
                'level_number' => 3,
                'sort_order' => 3,
            ],
            [
                'name' => 'Level 4: Sub-County Hospitals, Private Hospitals',
                'slug' => 'level-4-sub-county-hospitals-private-hospitals',
                'description' => 'Sub-county hospitals and private hospitals with inpatient services',
                'level_number' => 4,
                'sort_order' => 4,
            ],
            [
                'name' => 'Level 5: County Referral Hospitals, Private Hospitals',
                'slug' => 'level-5-county-referral-hospitals-private-hospitals',
                'description' => 'County referral hospitals and specialized private hospitals',
                'level_number' => 5,
                'sort_order' => 5,
            ],
            [
                'name' => 'Level 6: National Referral Hospitals',
                'slug' => 'level-6-national-referral-hospitals',
                'description' => 'National referral hospitals providing highly specialized care',
                'level_number' => 6,
                'sort_order' => 6,
            ],
        ];

        foreach ($facilityLevels as $level) {
            DB::table('facility_levels')->updateOrInsert(
                ['slug' => $level['slug']],
                array_merge($level, [
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );
        }
    }
}
