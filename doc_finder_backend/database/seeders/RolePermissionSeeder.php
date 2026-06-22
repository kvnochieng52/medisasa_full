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

        // Idempotent: firstOrCreate skips existing rows so re-running the
        // seeder doesn't blow up with "permission already exists".
        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
        }

        $adminRole = Role::firstOrCreate(['name' => 'Admin', 'guard_name' => 'web']);
        $serviceProviderRole = Role::firstOrCreate(['name' => 'Service Provider', 'guard_name' => 'web']);
        $standardRole = Role::firstOrCreate(['name' => 'Standard', 'guard_name' => 'web']);

        // Sync (not give) so we keep the role's permissions in sync with what's listed here
        // even if the lists change between runs.
        $adminRole->syncPermissions(Permission::all());

        $serviceProviderRole->syncPermissions([
            'facility-list',
            'facility-create',
            'facility-edit',
            'dashboard-access',
        ]);

        $standardRole->syncPermissions([
            'dashboard-access',
        ]);

        // Assign roles to existing users based on account_type (guarded against duplicate assignment).
        foreach (User::all() as $user) {
            $roleName = match ((int) $user->account_type) {
                1 => 'Standard',
                2 => 'Service Provider',
                3 => 'Admin',
                default => null,
            };
            if ($roleName && !$user->hasRole($roleName)) {
                $user->assignRole($roleName);
            }
        }
    }
}
