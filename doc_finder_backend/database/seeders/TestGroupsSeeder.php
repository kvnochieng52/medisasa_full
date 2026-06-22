<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class TestGroupsSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();

        // First, get some category IDs from the database
        $mentalHealthCat = DB::table('group_categories')->where('slug', 'mental-emotional-health')->value('id');
        $chronicIllnessCat = DB::table('group_categories')->where('slug', 'chronic-illness-autoimmune-conditions')->value('id');
        $cancerSupportCat = DB::table('group_categories')->where('slug', 'cancer-support')->value('id');
        $womensHealthCat = DB::table('group_categories')->where('slug', 'womens-family-health')->value('id');
        $addictionRecoveryCat = DB::table('group_categories')->where('slug', 'addiction-recovery')->value('id');
        $elderlyCaregivingCat = DB::table('group_categories')->where('slug', 'elderly-caregiving')->value('id');

        // Test groups data
        $groups = [
            [
                'group_name' => 'Nairobi Anxiety & Depression Support',
                'group_description' => 'A supportive community for individuals dealing with anxiety and depression in Nairobi. We meet weekly to share experiences, coping strategies, and provide mutual support.',
                'group_location' => 'Westlands Community Center, Nairobi',
                'group_tags' => 'anxiety,depression,mental health,support',
                'group_privacy' => 'public',
                'require_approval' => false,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$mentalHealthCat]
            ],
            [
                'group_name' => 'Diabetes Warriors Kenya',
                'group_description' => 'Empowering individuals with Type 1 and Type 2 diabetes through education, support, and community. Learn about blood sugar management, nutrition, and living well with diabetes.',
                'group_location' => 'Karen Hospital, Nairobi',
                'group_tags' => 'diabetes,blood sugar,nutrition,health management',
                'group_privacy' => 'public',
                'require_approval' => true,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$chronicIllnessCat]
            ],
            [
                'group_name' => 'Breast Cancer Survivors Network',
                'group_description' => 'A safe space for breast cancer survivors and their families. Share your journey, celebrate milestones, and find strength in our community of warriors.',
                'group_location' => 'Aga Khan University Hospital, Nairobi',
                'group_tags' => 'breast cancer,survivors,oncology,support',
                'group_privacy' => 'public',
                'require_approval' => false,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$cancerSupportCat]
            ],
            [
                'group_name' => 'New Mothers Circle Nairobi',
                'group_description' => 'Support group for new mothers navigating the challenges and joys of motherhood. Share experiences, ask questions, and build lasting friendships.',
                'group_location' => 'Kileleshwa Children\'s Hospital, Nairobi',
                'group_tags' => 'new mothers,parenting,postpartum,breastfeeding',
                'group_privacy' => 'public',
                'require_approval' => true,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$womensHealthCat]
            ],
            [
                'group_name' => 'AA Nairobi Central',
                'group_description' => 'Alcoholics Anonymous meeting group providing support for individuals on their journey to sobriety. Open meetings every Tuesday and Thursday.',
                'group_location' => 'Nairobi Baptist Church, CBD',
                'group_tags' => 'alcoholics anonymous,AA,recovery,sobriety',
                'group_privacy' => 'public',
                'require_approval' => false,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$addictionRecoveryCat]
            ],
            [
                'group_name' => 'Dementia Caregivers Support',
                'group_description' => 'Support network for family members and caregivers of individuals with dementia and Alzheimer\'s disease. Monthly meetings with expert speakers and peer support.',
                'group_location' => 'Gertrude\'s Hospital, Nairobi',
                'group_tags' => 'dementia,alzheimers,caregivers,elderly care',
                'group_privacy' => 'public',
                'require_approval' => true,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$elderlyCaregivingCat]
            ],
            [
                'group_name' => 'Young Adults Mental Health',
                'group_description' => 'Mental health support specifically for young adults (18-25) dealing with life transitions, career stress, and relationship challenges.',
                'group_location' => 'University of Nairobi, Nairobi',
                'group_tags' => 'young adults,mental health,stress,transitions',
                'group_privacy' => 'public',
                'require_approval' => false,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$mentalHealthCat]
            ],
            [
                'group_name' => 'Hypertension Management Group',
                'group_description' => 'Learn to manage high blood pressure through lifestyle changes, medication adherence, and peer support. Monthly blood pressure checks included.',
                'group_location' => 'Kenyatta National Hospital, Nairobi',
                'group_tags' => 'hypertension,blood pressure,heart health,lifestyle',
                'group_privacy' => 'public',
                'require_approval' => true,
                'created_by' => 1,
                'updated_by' => 1,
                'created_at' => $now,
                'updated_at' => $now,
                'categories' => [$chronicIllnessCat]
            ]
        ];

        // Insert groups and their category mappings
        foreach ($groups as $groupData) {
            $categories = $groupData['categories'];
            unset($groupData['categories']);

            // Insert the group
            $groupId = DB::table('groups')->insertGetId($groupData);

            // Insert category mappings
            foreach ($categories as $categoryId) {
                if ($categoryId) {
                    DB::table('group_category_mappings')->insert([
                        'group_id' => $groupId,
                        'category_id' => $categoryId,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]);
                }
            }
        }
    }
}