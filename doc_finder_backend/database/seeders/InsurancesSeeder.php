<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class InsurancesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $insurances = [
            'JUBILEE INSURANCE',
            'AAR INSURANCE',
            'OLD MUTUAL INSURANCE',
            'BRITAM INSURANCE',
            'MADISON INSURANCE',
            'HERITAGE INSURANCE',
            'RESOLUTION INSURANCE',
            'APOLLO INSURANCE',
            'GA INSURANCE',
            'PACIS INSURANCE',
            'INVESCO ASSURANCE',
            'KENINDIA ASSURANCE',
            'REAL INSURANCE',
            'CORPORATE INSURANCE',
            'TAKAFUL INSURANCE',
            'AIG INSURANCE',
            'CIC INSURANCE',
            'ICEA LION',
            'LIBERTY INSURANCE',
            'METROPOLITAN LIFE',
            'SANLAM LIFE',
            'AMACO INSURANCE',
            'GEMINIA INSURANCE',
            'ORIENT INSURANCE',
            'FIDELITY INSURANCE',
        ];

        foreach ($insurances as $index => $insurance) {
            DB::table('insurances')->updateOrInsert(
                ['name' => $insurance],
                [
                    'name' => $insurance,
                    'slug' => Str::slug($insurance),
                    'description' => $insurance . ' - Medical insurance provider',
                    'is_active' => true,
                    'sort_order' => $index + 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }
}
