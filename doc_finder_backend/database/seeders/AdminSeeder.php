<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $admins = [
            [
                'name'         => 'Super Admin',
                'email'        => 'superadmin@docfinder.com',
                'password'     => Hash::make('Admin@1234'),
                'telephone'    => '+254700000001',
                'address'      => 'Nairobi, Kenya',
                'account_type' => 3,
                'is_active'    => 1,
                'sp_approved'  => 1,
                'first_login'  => 0,
            ],
            [
                'name'         => 'Content Admin',
                'email'        => 'content@docfinder.com',
                'password'     => Hash::make('Admin@1234'),
                'telephone'    => '+254700000002',
                'address'      => 'Nairobi, Kenya',
                'account_type' => 3,
                'is_active'    => 1,
                'sp_approved'  => 1,
                'first_login'  => 0,
            ],
        ];

        foreach ($admins as $data) {
            // updateOrCreate so re-running the seeder REPAIRS bad data
            // (e.g. wrong account_type) instead of leaving it as-is. The
            // password is excluded from the update so existing accounts
            // keep their current password.
            $email = $data['email'];
            $password = $data['password'];

            $existing = User::where('email', $email)->first();

            if ($existing) {
                $existing->fill(collect($data)->except('password')->toArray());
                $existing->save();
                $user = $existing;
            } else {
                $user = User::create($data);
            }

            // Re-hash password if it was provided AND the existing one is empty (first-time create).
            if (!$existing && $password) {
                $user->password = $password;
                $user->save();
            }

            // Assign Admin role (Spatie), guard against duplicate assignment
            if (!$user->hasRole('Admin')) {
                $user->assignRole('Admin');
            }
        }

        $this->command->info('Admin accounts seeded:');
        $this->command->table(
            ['Name', 'Email', 'Password'],
            collect($admins)->map(fn($a) => [
                $a['name'],
                $a['email'],
                'Admin@1234',
            ])->toArray()
        );
    }
}
