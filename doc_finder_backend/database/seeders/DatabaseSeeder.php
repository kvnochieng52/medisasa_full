<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            // Roles & permissions
            RolePermissionSeeder::class,

            // Admin accounts (must follow RolePermissionSeeder)
            AdminSeeder::class,

            // Reference / lookup data
            SpecializationSeeder::class,
            FacilityTypesSeeder::class,
            FacilityLevelsSeeder::class,
            InsurancesSeeder::class,
            MedicineCategorySeeder::class,
            MedicalDataSeeder::class,

            // Content
            BlogSeeder::class,
            GroupCategoriesSeeder::class,

            // Subscription packages
            SubscriptionPackageSeeder::class,

            // Doctor accounts (depends on specializations)
            DoctorSeeder::class,

            // Demo / sample data for all modules
            DemoDataSeeder::class,
        ]);
    }
}
