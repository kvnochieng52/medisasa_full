<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

class RolePermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create permissions
        $permissions = [
            'user-list',
            'user-create',
            'user-edit',
            'user-delete',
            'user-approve',
            'facility-list',
            'facility-create',
            'facility-edit',
            'facility-delete',
            'blog-list',
            'blog-create',
            'blog-edit',
            'blog-delete',
            'dashboard-access',
        ];

        foreach ($permissions as $permission) {
            Permission::create(['name' => $permission]);
        }

        // Create roles and assign permissions
        $adminRole = Role::create(['name' => 'Admin']);
        $serviceProviderRole = Role::create(['name' => 'Service Provider']);
        $standardRole = Role::create(['name' => 'Standard']);

        // Admin gets all permissions
        $adminRole->givePermissionTo(Permission::all());

        // Service Provider permissions
        $serviceProviderRole->givePermissionTo([
            'facility-list',
            'facility-create',
            'facility-edit',
            'dashboard-access',
        ]);

        // Standard user permissions
        $standardRole->givePermissionTo([
            'dashboard-access',
        ]);

        // Assign roles to existing users based on their account_type
        $users = User::all();
        foreach ($users as $user) {
            switch ($user->account_type) {
                case 1:
                    $user->assignRole('Standard');
                    break;
                case 2:
                    $user->assignRole('Service Provider');
                    break;
                case 3:
                    $user->assignRole('Admin');
                    break;
            }
        }
    }
}
