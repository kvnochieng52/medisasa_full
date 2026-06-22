<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Specialization;
use App\Models\UserSpecialization;
use Illuminate\Support\Facades\Hash;

class DoctorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create specializations if they don't exist
        $specializations = [
            ['specialization_name' => 'General Care', 'specialization_description' => 'General medical practice', 'is_active' => 1, 'is_active_for_facility' => 1],
            ['specialization_name' => 'Cardiologist', 'specialization_description' => 'Heart and cardiovascular specialist', 'is_active' => 1, 'is_active_for_facility' => 1],
            ['specialization_name' => 'Dermatologist', 'specialization_description' => 'Skin, hair and nail specialist', 'is_active' => 1, 'is_active_for_facility' => 1],
            ['specialization_name' => 'Pediatrician', 'specialization_description' => 'Children and adolescent specialist', 'is_active' => 1, 'is_active_for_facility' => 1],
            ['specialization_name' => 'Orthopedic', 'specialization_description' => 'Bone, joint and muscle specialist', 'is_active' => 1, 'is_active_for_facility' => 1],
            ['specialization_name' => 'Dentist', 'specialization_description' => 'Dental and oral health specialist', 'is_active' => 1, 'is_active_for_facility' => 1],
        ];

        foreach ($specializations as $specialization) {
            Specialization::firstOrCreate(
                ['specialization_name' => $specialization['specialization_name']],
                $specialization
            );
        }

        // Create sample doctors
        $doctors = [
            [
                'name' => 'Dr. Sarah Johnson',
                'email' => 'sarah.johnson@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254712345678',
                'address' => 'Karen Medical Centre, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. Sarah Johnson is a highly experienced cardiologist with over 15 years of practice. She specializes in preventive cardiology and heart disease management.',
                'licence_number' => 'MD001234',
                'profile_image' => 'https://randomuser.me/api/portraits/women/45.jpg',
                'specialties' => ['Cardiologist']
            ],
            [
                'name' => 'Dr. Michael Ochieng',
                'email' => 'michael.ochieng@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254723456789',
                'address' => 'Westlands Medical Plaza, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. Michael Ochieng is a dedicated general practitioner who provides comprehensive healthcare services to patients of all ages.',
                'licence_number' => 'MD001235',
                'profile_image' => 'https://randomuser.me/api/portraits/men/35.jpg',
                'specialties' => ['General Care']
            ],
            [
                'name' => 'Dr. Grace Wanjiku',
                'email' => 'grace.wanjiku@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254734567890',
                'address' => 'Kileleshwa Children\'s Hospital, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. Grace Wanjiku is a passionate pediatrician with expertise in child development and pediatric emergency medicine.',
                'licence_number' => 'MD001236',
                'profile_image' => 'https://randomuser.me/api/portraits/women/62.jpg',
                'specialties' => ['Pediatrician']
            ],
            [
                'name' => 'Dr. James Mwangi',
                'email' => 'james.mwangi@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254745678901',
                'address' => 'Runda Dermatology Clinic, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. James Mwangi is a board-certified dermatologist specializing in medical and cosmetic dermatology.',
                'licence_number' => 'MD001237',
                'profile_image' => 'https://randomuser.me/api/portraits/men/47.jpg',
                'specialties' => ['Dermatologist']
            ],
            [
                'name' => 'Dr. Rebecca Mutua',
                'email' => 'rebecca.mutua@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254756789012',
                'address' => 'Nairobi Orthopedic Center, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. Rebecca Mutua is an experienced orthopedic surgeon specializing in sports medicine and joint replacement.',
                'licence_number' => 'MD001238',
                'profile_image' => 'https://randomuser.me/api/portraits/women/28.jpg',
                'specialties' => ['Orthopedic']
            ],
            [
                'name' => 'Dr. David Kimani',
                'email' => 'david.kimani@docfinder.com',
                'password' => Hash::make('password123'),
                'telephone' => '+254767890123',
                'address' => 'Karen Dental Clinic, Nairobi',
                'account_type' => 2,
                'sp_approved' => 1,
                'is_active' => 1,
                'professional_bio' => 'Dr. David Kimani is a skilled dentist with expertise in general dentistry and oral surgery.',
                'licence_number' => 'MD001239',
                'profile_image' => 'https://randomuser.me/api/portraits/men/22.jpg',
                'specialties' => ['Dentist']
            ],
        ];

        foreach ($doctors as $doctorData) {
            $specialties = $doctorData['specialties'];
            unset($doctorData['specialties']);

            $doctor = User::firstOrCreate(
                ['email' => $doctorData['email']],
                $doctorData
            );

            // Assign specializations
            foreach ($specialties as $specialtyName) {
                $specialty = Specialization::where('specialization_name', $specialtyName)->first();
                if ($specialty) {
                    UserSpecialization::firstOrCreate([
                        'user_id' => $doctor->id,
                        'specialization_id' => $specialty->id,
                    ]);
                }
            }
        }
    }
}