<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\MedicineCategory;
use App\Models\MedicineSubcategory;

class ProductCategoriesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Medical Equipment Categories for Products
        $categories = [
            [
                'name' => 'Diagnostic Equipment',
                'description' => 'Medical devices used for diagnosis and examination',
                'subcategories' => [
                    'Blood Pressure Monitors',
                    'Thermometers',
                    'Stethoscopes',
                    'Pulse Oximeters',
                    'Glucometers',
                    'Otoscopes',
                    'Ophthalmoscopes'
                ]
            ],
            [
                'name' => 'Mobility Aids',
                'description' => 'Equipment to assist with movement and mobility',
                'subcategories' => [
                    'Wheelchairs',
                    'Walking Aids',
                    'Crutches',
                    'Walkers',
                    'Mobility Scooters',
                    'Transfer Boards'
                ]
            ],
            [
                'name' => 'Respiratory Equipment',
                'description' => 'Devices for breathing and respiratory support',
                'subcategories' => [
                    'Nebulizers',
                    'Oxygen Concentrators',
                    'CPAP Machines',
                    'Inhalers',
                    'Peak Flow Meters',
                    'Spirometers'
                ]
            ],
            [
                'name' => 'Rehabilitation Equipment',
                'description' => 'Tools and devices for physical therapy and rehabilitation',
                'subcategories' => [
                    'Exercise Equipment',
                    'Physical Therapy Tools',
                    'Balance Training',
                    'Strength Training',
                    'Flexibility Aids',
                    'Recovery Tools'
                ]
            ],
            [
                'name' => 'Home Care Products',
                'description' => 'Medical products for home healthcare',
                'subcategories' => [
                    'Hospital Beds',
                    'Mattresses',
                    'Bathroom Safety',
                    'Lift Chairs',
                    'Compression Garments',
                    'Wound Care Supplies'
                ]
            ],
            [
                'name' => 'Monitoring Devices',
                'description' => 'Electronic devices for health monitoring',
                'subcategories' => [
                    'Heart Rate Monitors',
                    'Blood Glucose Monitors',
                    'Blood Pressure Cuffs',
                    'Temperature Monitors',
                    'Sleep Monitors',
                    'Activity Trackers'
                ]
            ]
        ];

        foreach ($categories as $categoryData) {
            // Create category with visible_for_products = true (or update if exists)
            $category = MedicineCategory::firstOrCreate(
                ['name' => $categoryData['name']],
                [
                    'description' => $categoryData['description'],
                    'is_active' => true,
                    'visible_for_products' => true,
                ]
            );

            // Update existing category to be visible for products
            if (!$category->visible_for_products) {
                $category->update(['visible_for_products' => true]);
            }

            // Create subcategories
            foreach ($categoryData['subcategories'] as $subcategoryName) {
                $slug = \Illuminate\Support\Str::slug($subcategoryName);
                $subcategory = MedicineSubcategory::firstOrCreate(
                    ['slug' => $slug],
                    [
                        'category_id' => $category->id,
                        'name' => $subcategoryName,
                        'description' => "Products related to {$subcategoryName}",
                        'is_active' => true,
                        'visible_for_products' => true,
                    ]
                );

                // Update existing subcategory to be visible for products
                if (!$subcategory->visible_for_products) {
                    $subcategory->update(['visible_for_products' => true]);
                }
            }
        }
    }
}