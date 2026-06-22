<?php

namespace Database\Seeders;

use App\Models\MentalHealthMaterial;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds the PHQ-9 (depression) and GAD-7 (anxiety) screening tools used by
 * the MediSasa mental-health module: surveys, questions, options, result
 * bands, and the materials linked to each band.
 *
 * Safe to re-run — checks for existing slugs before inserting.
 *
 * Depends on MentalHealthMaterialsSeeder for the generic materials it
 * references by title. If those are missing, PHQ-9 bands simply skip the
 * material link instead of failing.
 */
class MentalHealthSurveysSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedPhq9Survey();
        $this->seedGad7Survey();
    }

    // -------------------------------------------------------------------------
    // PHQ-9 (Depression Screening)
    // -------------------------------------------------------------------------
    private function seedPhq9Survey(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        if (DB::table('surveys')->where('slug', 'phq-9-depression-screening')->exists()) return;

        $surveyId = DB::table('surveys')->insertGetId([
            'title'        => 'PHQ-9 Depression Screening',
            'description'  => 'The Patient Health Questionnaire-9 (PHQ-9) is a validated tool for screening, diagnosing, monitoring, and measuring the severity of depression.',
            'instructions' => 'Over the last 2 weeks, how often have you been bothered by any of the following problems? Answer as honestly as possible.',
            'slug'         => 'phq-9-depression-screening',
            'is_active'    => true,
            'created_by'   => $adminId,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $questions = [
            'Little interest or pleasure in doing things',
            'Feeling down, depressed, or hopeless',
            'Trouble falling or staying asleep, or sleeping too much',
            'Feeling tired or having little energy',
            'Poor appetite or overeating',
            'Feeling bad about yourself — or that you are a failure or have let yourself or your family down',
            'Trouble concentrating on things, such as reading the newspaper or watching television',
            'Moving or speaking so slowly that other people could have noticed, or the opposite — being so fidgety or restless that you have been moving around a lot more than usual',
            'Thoughts that you would be better off dead, or thoughts of hurting yourself in some way',
        ];

        $options = [
            ['label' => 'Not at all',              'score_value' => 0, 'color' => 'green',  'order_index' => 0],
            ['label' => 'Several days',             'score_value' => 1, 'color' => 'yellow', 'order_index' => 1],
            ['label' => 'More than half the days',  'score_value' => 2, 'color' => 'orange', 'order_index' => 2],
            ['label' => 'Nearly every day',         'score_value' => 3, 'color' => 'red',    'order_index' => 3],
        ];

        foreach ($questions as $idx => $qText) {
            $questionId = DB::table('survey_questions')->insertGetId([
                'survey_id'     => $surveyId,
                'question_text' => $qText,
                'order_index'   => $idx,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            foreach ($options as $opt) {
                DB::table('survey_options')->insert([
                    'question_id' => $questionId,
                    'label'       => $opt['label'],
                    'score_value' => $opt['score_value'],
                    'color'       => $opt['color'],
                    'order_index' => $opt['order_index'],
                ]);
            }
        }

        $bands = [
            ['label' => 'Minimal Depression',  'min' => 0,  'max' => 4,  'type' => 'low',      'cta' => false, 'order' => 0, 'message' => 'Your responses suggest minimal or no depression. Continue maintaining healthy lifestyle habits like regular exercise, good sleep, and social connections.'],
            ['label' => 'Mild Depression',     'min' => 5,  'max' => 9,  'type' => 'low',      'cta' => false, 'order' => 1, 'message' => 'Your responses suggest mild depression. Consider monitoring your mood and implementing self-care strategies. Speak with your GP if symptoms persist.'],
            ['label' => 'Moderate Depression', 'min' => 10, 'max' => 14, 'type' => 'moderate', 'cta' => true,  'order' => 2, 'message' => 'Your responses suggest moderate depression. We recommend speaking with a healthcare professional. A therapist or counsellor can provide effective support.'],
            ['label' => 'Moderately Severe',   'min' => 15, 'max' => 19, 'type' => 'high',     'cta' => true,  'order' => 3, 'message' => 'Your responses suggest moderately severe depression. It is important to consult a doctor or mental health professional as soon as possible for proper diagnosis and treatment.'],
            ['label' => 'Severe Depression',   'min' => 20, 'max' => 27, 'type' => 'high',     'cta' => true,  'order' => 4, 'message' => 'Your responses suggest severe depression. Please reach out to a mental health professional or emergency services immediately. You are not alone — help is available.'],
        ];

        $materials = MentalHealthMaterial::where('is_active', true)->get()->keyBy('title');

        foreach ($bands as $band) {
            $bandId = DB::table('survey_result_bands')->insertGetId([
                'survey_id'          => $surveyId,
                'label'              => $band['label'],
                'min_score'          => $band['min'],
                'max_score'          => $band['max'],
                'message'            => $band['message'],
                'result_type'        => $band['type'],
                'show_therapist_cta' => $band['cta'],
                'order_index'        => $band['order'],
            ]);

            if ($band['type'] === 'moderate' || $band['type'] === 'high') {
                $mat1 = $materials->get('Understanding Depression: A Beginner\'s Guide');
                $mat2 = $materials->get('Mindfulness Meditation for Anxiety - 30-Day Program');
                if ($mat1) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat1->id]);
                if ($mat2) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat2->id]);
            } elseif ($band['type'] === 'low') {
                $mat3 = $materials->get('Sleep Hygiene & Insomnia - Expert Talk');
                if ($mat3) DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $mat3->id]);
            }
        }
    }

    // -------------------------------------------------------------------------
    // GAD-7 (Anxiety Screening) — also seeds its own survey-linked materials
    // -------------------------------------------------------------------------
    private function seedGad7Survey(): void
    {
        $adminId = User::where('email', 'admin@docfinder.com')->value('id') ?? 1;

        if (DB::table('surveys')->where('slug', 'gad-7-anxiety-screening')->exists()) return;

        $surveyId = DB::table('surveys')->insertGetId([
            'title'        => 'GAD-7 Anxiety Screening',
            'description'  => 'The Generalized Anxiety Disorder 7-item (GAD-7) scale is a validated self-report tool used to screen for and measure the severity of generalized anxiety disorder.',
            'instructions' => 'Over the last 2 weeks, how often have you been bothered by the following problems? There are no right or wrong answers — please answer as honestly as you can.',
            'slug'         => 'gad-7-anxiety-screening',
            'is_active'    => true,
            'created_by'   => $adminId,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $questions = [
            'Feeling nervous, anxious, or on edge',
            'Not being able to stop or control worrying',
            'Worrying too much about different things',
            'Trouble relaxing',
            'Being so restless that it is hard to sit still',
            'Becoming easily annoyed or irritable',
            'Feeling afraid, as if something awful might happen',
        ];

        $options = [
            ['label' => 'Not at all',              'score_value' => 0, 'color' => 'green',  'order_index' => 0],
            ['label' => 'Several days',             'score_value' => 1, 'color' => 'yellow', 'order_index' => 1],
            ['label' => 'More than half the days',  'score_value' => 2, 'color' => 'orange', 'order_index' => 2],
            ['label' => 'Nearly every day',         'score_value' => 3, 'color' => 'red',    'order_index' => 3],
        ];

        foreach ($questions as $idx => $qText) {
            $questionId = DB::table('survey_questions')->insertGetId([
                'survey_id'     => $surveyId,
                'question_text' => $qText,
                'order_index'   => $idx,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            foreach ($options as $opt) {
                DB::table('survey_options')->insert([
                    'question_id' => $questionId,
                    'label'       => $opt['label'],
                    'score_value' => $opt['score_value'],
                    'color'       => $opt['color'],
                    'order_index' => $opt['order_index'],
                ]);
            }
        }

        $bands = [
            [
                'label'   => 'Minimal Anxiety',
                'min'     => 0, 'max' => 4,
                'type'    => 'low',
                'cta'     => false,
                'order'   => 0,
                'message' => 'Your responses suggest minimal anxiety. Keep up the healthy habits — regular exercise, quality sleep, and staying connected with loved ones all support good mental wellbeing.',
            ],
            [
                'label'   => 'Mild Anxiety',
                'min'     => 5, 'max' => 9,
                'type'    => 'low',
                'cta'     => false,
                'order'   => 1,
                'message' => 'Your responses suggest mild anxiety. Consider practising relaxation techniques such as deep breathing or mindfulness. Monitoring how you feel over the coming weeks is a good idea.',
            ],
            [
                'label'   => 'Moderate Anxiety',
                'min'     => 10, 'max' => 14,
                'type'    => 'moderate',
                'cta'     => true,
                'order'   => 2,
                'message' => 'Your responses suggest moderate anxiety. We recommend speaking with a healthcare professional. Talking therapies like CBT are highly effective at this level.',
            ],
            [
                'label'   => 'Severe Anxiety',
                'min'     => 15, 'max' => 21,
                'type'    => 'high',
                'cta'     => true,
                'order'   => 3,
                'message' => 'Your responses suggest severe anxiety. Please reach out to a doctor or mental health professional as soon as possible. Effective treatments are available and seeking help is a sign of strength.',
            ],
        ];

        $gad7Materials = [
            [
                'title'       => 'Understanding Anxiety: A Complete Guide',
                'description' => 'A comprehensive PDF guide covering what anxiety is, the different types, how it affects your body and mind, and the most effective evidence-based treatments including CBT and medication.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Anxiety Management Techniques — Video Series',
                'description' => 'A 5-part video series by a clinical psychologist covering grounding exercises, progressive muscle relaxation, cognitive restructuring, and exposure techniques for managing anxiety.',
                'file_type'   => 'video',
                'is_free'     => false,
                'price'       => 650.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'The Worry Journal: CBT Workbook for Anxiety',
                'description' => 'An interactive PDF workbook based on Cognitive Behavioural Therapy principles. Includes thought records, worry diaries, exposure hierarchies, and relapse prevention exercises.',
                'file_type'   => 'pdf',
                'is_free'     => false,
                'price'       => 400.00,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1517971129774-8a2b38fa128e?w=600&h=400&fit=crop&auto=format',
            ],
            [
                'title'       => 'Breathing & Grounding Exercises — Quick Reference',
                'description' => 'A free quick-reference PDF card with 5 proven breathing techniques (4-7-8, box breathing, diaphragmatic) and the 5-4-3-2-1 grounding exercise you can use anywhere.',
                'file_type'   => 'pdf',
                'is_free'     => true,
                'price'       => null,
                'is_active'   => true,
                'created_by'  => $adminId,
                'survey_id'   => $surveyId,
                'image_path'  => 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=600&h=400&fit=crop&auto=format',
            ],
        ];

        $createdMaterials = [];
        foreach ($gad7Materials as $mat) {
            $existing = MentalHealthMaterial::where('title', $mat['title'])->first();
            if (!$existing) {
                $existing = MentalHealthMaterial::create($mat);
            }
            $createdMaterials[$mat['title']] = $existing->id;
        }

        foreach ($bands as $band) {
            $bandId = DB::table('survey_result_bands')->insertGetId([
                'survey_id'          => $surveyId,
                'label'              => $band['label'],
                'min_score'          => $band['min'],
                'max_score'          => $band['max'],
                'message'            => $band['message'],
                'result_type'        => $band['type'],
                'show_therapist_cta' => $band['cta'],
                'order_index'        => $band['order'],
            ]);

            if ($band['type'] === 'high' || $band['type'] === 'moderate') {
                foreach ($createdMaterials as $materialId) {
                    DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $materialId]);
                }
            } else {
                $freeIds = [
                    $createdMaterials['Understanding Anxiety: A Complete Guide'] ?? null,
                    $createdMaterials['Breathing & Grounding Exercises — Quick Reference'] ?? null,
                ];
                foreach (array_filter($freeIds) as $materialId) {
                    DB::table('survey_band_materials')->insert(['band_id' => $bandId, 'material_id' => $materialId]);
                }
            }
        }
    }
}
