<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Default seeder run by `php artisan db:seed`.
 *
 * This seeds everything required for the platform to operate:
 *   - Roles, permissions and admin accounts
 *   - Reference / lookup tables (specializations, facility types, levels,
 *     insurances, group categories, medicine categories, product categories)
 *   - Medical data (symptoms, conditions, mappings to specializations)
 *   - Mental-health surveys + materials (PHQ-2, PHQ-9, GAD-7)
 *   - Subscription packages
 *
 * Demo / sample data (DemoDataSeeder, DoctorSeeder, BlogSeeder, TestGroupsSeeder)
 * is intentionally NOT called from here. Run those separately, e.g.
 *     php artisan db:seed --class=DemoDataSeeder
 *     php artisan db:seed --class=DoctorSeeder
 *     php artisan db:seed --class=BlogSeeder
 *     php artisan db:seed --class=TestGroupsSeeder
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            // ── Auth foundation ─────────────────────────────────────────
            RolePermissionSeeder::class,
            AdminSeeder::class,

            // ── Reference / lookup data ─────────────────────────────────
            // Order matters: SpecializationSeeder must run before
            // MedicalDataSeeder (mappings depend on specialization names).
            SpecializationSeeder::class,
            FacilityTypesSeeder::class,
            FacilityLevelsSeeder::class,
            FacilityServicesSeeder::class,
            InsurancesSeeder::class,
            GroupCategoriesSeeder::class,
            MedicineCategorySeeder::class,
            ProductCategoriesSeeder::class,
            MedicalDataSeeder::class,

            // ── Subscription packages ───────────────────────────────────
            SubscriptionPackageSeeder::class,

            // ── Mental health module ────────────────────────────────────
            // Materials before surveys: PHQ-9 result bands link to material
            // titles created by the materials seeder.
            MentalHealthMaterialsSeeder::class,
            MentalHealthSurveysSeeder::class,
            SurveysSeeder::class,
        ]);
    }
}
