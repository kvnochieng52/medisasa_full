<?php

namespace Database\Seeders;

use App\Models\SubscriptionPackage;
use Illuminate\Database\Seeder;

class SubscriptionPackageSeeder extends Seeder
{
    public function run(): void
    {
        $packages = [
            [
                'slug'                        => 'monthly',
                'name'                        => 'Monthly',
                'amount'                      => 1.00, // KES 1 for testing
                'currency'                    => 'KES',
                'duration_days'               => 30,
                'description'                 => '30 days access.',
                'features'                    => [
                    'View appointments (up to 50/month)',
                    'Manage appointments — basic scheduling',
                    'Create facilities (1 facility)',
                    'Add hospitals (1 hospital)',
                ],
                'max_appointments_per_month'  => 50,
                'max_facilities'              => 1,
                'max_hospitals'               => 1,
                'is_popular'                  => false,
                'is_active'                   => true,
            ],
            [
                'slug'                        => 'quarterly',
                'name'                        => 'Quarterly',
                'amount'                      => 7999.00,
                'currency'                    => 'KES',
                'duration_days'               => 90,
                'description'                 => '3 months access.',
                'features'                    => [
                    'View appointments (up to 200/month)',
                    'Manage appointments — advanced scheduling',
                    'Create facilities (up to 3)',
                    'Add hospitals (up to 3)',
                ],
                'max_appointments_per_month'  => 200,
                'max_facilities'              => 3,
                'max_hospitals'               => 3,
                'is_popular'                  => false,
                'is_active'                   => true,
            ],
            [
                'slug'                        => 'annually',
                'name'                        => 'Annual',
                'amount'                      => 29999.00,
                'currency'                    => 'KES',
                'duration_days'               => 365,
                'description'                 => '12 months access.',
                'features'                    => [
                    'View appointments (unlimited)',
                    'Manage appointments — full + analytics',
                    'Create facilities (unlimited)',
                    'Add hospitals (unlimited)',
                ],
                'max_appointments_per_month'  => null, // unlimited
                'max_facilities'              => null, // unlimited
                'max_hospitals'               => null, // unlimited
                'is_popular'                  => true,
                'is_active'                   => true,
            ],
        ];

        foreach ($packages as $package) {
            SubscriptionPackage::updateOrCreate(
                ['slug' => $package['slug']],
                $package
            );
        }
    }
}
