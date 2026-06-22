<?php

namespace Database\Seeders;

use App\Models\Survey;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class SurveysSeeder extends Seeder
{
    public function run(): void
    {
        // ── PHQ-2: Depression Screening ───────────────────────────────────────────
        $this->createSurvey(
            title: 'PHQ-2 Depression Screening',
            description: 'A brief 2-question screening tool to identify possible depression.',
            instructions: 'Over the past 2 weeks, how often have you been bothered by the following problems?',
            slug: 'phq-2',
            questions: [
                [
                    'question_text' => 'Little interest or pleasure in doing things',
                    'options' => self::FREQ_OPTIONS_0_3,
                ],
                [
                    'question_text' => 'Feeling down, depressed, or hopeless',
                    'options' => self::FREQ_OPTIONS_0_3,
                ],
            ],
            bands: [
                ['label' => 'Minimal', 'min' => 0, 'max' => 2, 'type' => 'low',
                 'message' => 'Your score suggests minimal or no depression symptoms. Keep practising healthy habits like regular exercise, good sleep, and social connection.',
                 'cta' => false],
                ['label' => 'Possible Depression', 'min' => 3, 'max' => 6, 'type' => 'high',
                 'message' => 'Your score suggests you may be experiencing depressive symptoms. We recommend speaking with a mental health professional for a full evaluation.',
                 'cta' => true],
            ]
        );

        // ── GAD-7: Anxiety Screening ──────────────────────────────────────────────
        $this->createSurvey(
            title: 'GAD-7 Anxiety Screening',
            description: 'A 7-question tool for measuring generalised anxiety disorder severity.',
            instructions: 'Over the past 2 weeks, how often have you been bothered by the following problems?',
            slug: 'gad-7',
            questions: [
                ['question_text' => 'Feeling nervous, anxious, or on edge',             'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Not being able to stop or control worrying',        'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Worrying too much about different things',          'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Trouble relaxing',                                  'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Being so restless that it is hard to sit still',   'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Becoming easily annoyed or irritable',              'options' => self::FREQ_OPTIONS_0_3],
                ['question_text' => 'Feeling afraid as if something awful might happen', 'options' => self::FREQ_OPTIONS_0_3],
            ],
            bands: [
                ['label' => 'Minimal Anxiety',  'min' => 0,  'max' => 4,  'type' => 'low',
                 'message' => 'Your anxiety level appears minimal. Continue nurturing your wellbeing with mindfulness practices and regular exercise.',
                 'cta' => false],
                ['label' => 'Mild Anxiety',     'min' => 5,  'max' => 9,  'type' => 'low',
                 'message' => 'You show signs of mild anxiety. Explore our resources below and consider monitoring your symptoms over the next few weeks.',
                 'cta' => false],
                ['label' => 'Moderate Anxiety', 'min' => 10, 'max' => 14, 'type' => 'moderate',
                 'message' => 'Your score indicates moderate anxiety. Speaking with a mental health professional would be beneficial.',
                 'cta' => true],
                ['label' => 'Severe Anxiety',   'min' => 15, 'max' => 21, 'type' => 'high',
                 'message' => 'Your score indicates severe anxiety. We strongly encourage you to seek professional support as soon as possible.',
                 'cta' => true],
            ]
        );

        // ── PSS-10: Perceived Stress Scale ────────────────────────────────────────
        $this->createSurvey(
            title: 'PSS-10 Stress Scale',
            description: 'The Perceived Stress Scale measures the degree to which situations in your life are appraised as stressful.',
            instructions: 'In the last month, how often have you felt or thought the following?',
            slug: 'pss-10',
            questions: [
                // Positively framed (reversed): Q4, Q5, Q7, Q8 — scores flipped 0↔4
                ['question_text' => 'Felt upset because of something that happened unexpectedly',
                 'options' => self::FREQ_OPTIONS_0_4],
                ['question_text' => 'Felt unable to control the important things in your life',
                 'options' => self::FREQ_OPTIONS_0_4],
                ['question_text' => 'Felt nervous and stressed',
                 'options' => self::FREQ_OPTIONS_0_4],
                ['question_text' => 'Felt confident about your ability to handle personal problems', // reversed
                 'options' => self::FREQ_OPTIONS_0_4_REVERSED],
                ['question_text' => 'Felt that things were going your way', // reversed
                 'options' => self::FREQ_OPTIONS_0_4_REVERSED],
                ['question_text' => 'Found that you could not cope with all the things you had to do',
                 'options' => self::FREQ_OPTIONS_0_4],
                ['question_text' => 'Been able to control irritations in your life', // reversed
                 'options' => self::FREQ_OPTIONS_0_4_REVERSED],
                ['question_text' => 'Felt that you were on top of things', // reversed
                 'options' => self::FREQ_OPTIONS_0_4_REVERSED],
                ['question_text' => 'Been angered because of things that were outside of your control',
                 'options' => self::FREQ_OPTIONS_0_4],
                ['question_text' => 'Felt difficulties were piling up so high that you could not overcome them',
                 'options' => self::FREQ_OPTIONS_0_4],
            ],
            bands: [
                ['label' => 'Low Stress',      'min' => 0,  'max' => 13, 'type' => 'low',
                 'message' => 'Your stress levels appear low. Continue with your healthy coping strategies and self-care routines.',
                 'cta' => false],
                ['label' => 'Moderate Stress', 'min' => 14, 'max' => 26, 'type' => 'moderate',
                 'message' => 'You are experiencing moderate stress. Exploring stress-management resources and speaking with a therapist may help.',
                 'cta' => true],
                ['label' => 'High Stress',     'min' => 27, 'max' => 40, 'type' => 'high',
                 'message' => 'Your stress levels are high. We recommend consulting a psychologist or mental health professional for personalised support.',
                 'cta' => true],
            ]
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────────

    private function createSurvey(
        string $title,
        string $description,
        string $instructions,
        string $slug,
        array  $questions,
        array  $bands,
    ): void {
        // Skip if already seeded
        if (Survey::where('slug', $slug)->exists()) {
            return;
        }

        $survey = Survey::create([
            'title'        => $title,
            'description'  => $description,
            'instructions' => $instructions,
            'slug'         => $slug,
            'is_active'    => true,
            'created_by'   => null,
        ]);

        foreach ($questions as $qi => $qData) {
            $q = $survey->questions()->create([
                'question_text' => $qData['question_text'],
                'hint'          => $qData['hint'] ?? null,
                'order_index'   => $qi,
            ]);
            foreach ($qData['options'] as $oi => $opt) {
                $q->options()->create([
                    'label'       => $opt['label'],
                    'score_value' => $opt['score_value'],
                    'color'       => $opt['color'] ?? 'green',
                    'order_index' => $oi,
                ]);
            }
        }

        foreach ($bands as $bi => $bData) {
            $survey->resultBands()->create([
                'label'              => $bData['label'],
                'min_score'          => $bData['min'],
                'max_score'          => $bData['max'],
                'message'            => $bData['message'],
                'result_type'        => $bData['type'],
                'show_therapist_cta' => $bData['cta'],
                'order_index'        => $bi,
            ]);
        }
    }

    // ── Shared option sets ────────────────────────────────────────────────────────

    const FREQ_OPTIONS_0_3 = [
        ['label' => 'Not at all',        'score_value' => 0, 'color' => 'green'],
        ['label' => 'Several days',      'score_value' => 1, 'color' => 'yellow'],
        ['label' => 'More than half the days', 'score_value' => 2, 'color' => 'orange'],
        ['label' => 'Nearly every day',  'score_value' => 3, 'color' => 'red'],
    ];

    const FREQ_OPTIONS_0_4 = [
        ['label' => 'Never',     'score_value' => 0, 'color' => 'green'],
        ['label' => 'Almost Never', 'score_value' => 1, 'color' => 'green'],
        ['label' => 'Sometimes', 'score_value' => 2, 'color' => 'yellow'],
        ['label' => 'Fairly Often', 'score_value' => 3, 'color' => 'orange'],
        ['label' => 'Very Often', 'score_value' => 4, 'color' => 'red'],
    ];

    // Reversed scoring for positively-framed PSS questions (high frequency → low stress)
    const FREQ_OPTIONS_0_4_REVERSED = [
        ['label' => 'Never',        'score_value' => 4, 'color' => 'red'],
        ['label' => 'Almost Never', 'score_value' => 3, 'color' => 'orange'],
        ['label' => 'Sometimes',    'score_value' => 2, 'color' => 'yellow'],
        ['label' => 'Fairly Often', 'score_value' => 1, 'color' => 'green'],
        ['label' => 'Very Often',   'score_value' => 0, 'color' => 'green'],
    ];
}
