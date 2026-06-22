<?php

namespace Database\Seeders;

use App\Models\MentalHealthMaterial;
use App\Models\User;
use Illuminate\Database\Seeder;

class MentalHealthMaterialsSeeder extends Seeder
{
    public function run(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        $materials = [
            [
                'title'       => 'Understanding Depression: A Beginner\'s Guide',
                'description' => 'A comprehensive PDF guide explaining what depression is, its symptoms, causes, and the most effective evidence-based treatments available. Suitable for patients and caregivers.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Mindfulness Meditation for Anxiety - 30-Day Program',
                'description' => 'A structured 30-day guided mindfulness program in video format, helping you build daily meditation habits to reduce anxiety and improve mental clarity.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 500.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Stress Management Workbook',
                'description' => 'An interactive PDF workbook with exercises, journaling prompts, and cognitive restructuring tools to help you identify stress triggers and build healthy coping strategies.',
                'file_type'   => 'pdf',
                'is_free'     => false,
                'price'       => 350.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1517971129774-8a2b38fa128e?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Sleep Hygiene & Insomnia - Expert Talk',
                'description' => 'A 45-minute expert video by a sleep specialist covering the science of sleep, common causes of insomnia, and proven techniques to improve sleep quality without medication.',
                'file_type'   => 'video',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Grief & Loss: Healing After Bereavement',
                'description' => 'A compassionate guide through the stages of grief with practical advice on processing loss, building resilience, and finding meaning after bereavement.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1573497620304-9ed4f55db3b7?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Building Emotional Resilience - Masterclass',
                'description' => 'A 3-part video masterclass covering the pillars of emotional resilience, including positive psychology, social support networks, and practical resilience-building exercises.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 800.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'image_path'  => 'https://images.unsplash.com/photo-1521175628397-9c05e873a4f4?w=600&h=400&fit=crop&auto=format',
            ],
        ];

        foreach ($materials as $m) {
            MentalHealthMaterial::firstOrCreate(['title' => $m['title']], $m);
        }
    }
}
