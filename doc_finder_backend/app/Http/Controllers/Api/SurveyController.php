<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Survey;
use App\Models\SurveyQuestion;
use App\Models\SurveyOption;
use App\Models\SurveyResultBand;
use App\Models\SurveyResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SurveyController extends Controller
{
    // ── Public ──────────────────────────────────────────────

    public function index()
    {
        $surveys = Survey::where('is_active', true)
            ->withCount('questions')
            ->orderBy('id')
            ->get(['id', 'title', 'description', 'slug', 'is_active']);

        return response()->json(['success' => true, 'data' => $surveys]);
    }

    public function show(int $id)
    {
        $survey = Survey::where('is_active', true)
            ->with(['questions.options'])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $survey]);
    }

    public function showBySlug(string $slug)
    {
        $survey = Survey::where('is_active', true)
            ->where('slug', $slug)
            ->with(['questions.options'])
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $survey]);
    }

    public function respond(Request $request, int $id)
    {
        $survey = Survey::where('is_active', true)
            ->with(['questions.options', 'resultBands.materials'])
            ->findOrFail($id);

        $request->validate([
            'answers'   => 'required|array',
            'answers.*' => 'integer|min:0',
        ]);

        $answers     = $request->input('answers'); // [question_id => score_value]
        $totalScore  = array_sum($answers);

        // Find matching band
        $band = $survey->resultBands
            ->first(fn($b) => $totalScore >= $b->min_score && $totalScore <= $b->max_score);

        $response = SurveyResponse::create([
            'survey_id'   => $survey->id,
            'user_id'     => $request->user()?->id,
            'total_score' => $totalScore,
            'band_id'     => $band?->id,
            'answers'     => $answers,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'response_id' => $response->id,
                'total_score' => $totalScore,
                'band'        => $band ? [
                    'id'                 => $band->id,
                    'label'              => $band->label,
                    'message'            => $band->message,
                    'result_type'        => $band->result_type,
                    'show_therapist_cta' => $band->show_therapist_cta,
                    'materials'          => $band->materials->map(fn($m) => [
                        'id'         => $m->id,
                        'title'      => $m->title,
                        'file_type'  => $m->file_type,
                        'is_free'    => $m->is_free,
                        'price'      => $m->price,
                        'image_path' => $m->image_path,
                    ]),
                ] : null,
            ],
        ]);
    }

    public function myResponses(Request $request)
    {
        $responses = SurveyResponse::where('user_id', $request->user()->id)
            ->with(['survey:id,title,slug', 'band:id,label,result_type'])
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['success' => true, 'data' => $responses]);
    }

    // ── Admin ────────────────────────────────────────────────

    public function store(Request $request)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'title'        => 'required|string|max:255',
            'description'  => 'nullable|string',
            'instructions' => 'nullable|string',
            'slug'         => 'nullable|string|unique:surveys,slug',
            'is_active'    => 'boolean',
            'questions'    => 'required|array|min:1',
            'questions.*.question_text' => 'required|string',
            'questions.*.hint'          => 'nullable|string',
            'questions.*.order_index'   => 'integer',
            'questions.*.options'       => 'required|array|min:2',
            'questions.*.options.*.label'       => 'required|string',
            'questions.*.options.*.score_value' => 'required|integer|min:0',
            'questions.*.options.*.color'       => 'nullable|string',
            'questions.*.options.*.order_index' => 'integer',
            'result_bands' => 'required|array|min:1',
            'result_bands.*.label'              => 'required|string',
            'result_bands.*.min_score'          => 'required|integer|min:0',
            'result_bands.*.max_score'          => 'required|integer|min:0',
            'result_bands.*.message'            => 'required|string',
            'result_bands.*.result_type'        => 'required|in:low,moderate,high',
            'result_bands.*.show_therapist_cta' => 'boolean',
            'result_bands.*.order_index'        => 'integer',
            'result_bands.*.material_ids'       => 'nullable|array',
            'result_bands.*.material_ids.*'     => 'integer|exists:mental_health_materials,id',
        ]);

        $slug   = $data['slug'] ?? Str::slug($data['title']);
        $survey = Survey::create([
            'title'        => $data['title'],
            'description'  => $data['description'] ?? null,
            'instructions' => $data['instructions'] ?? null,
            'slug'         => $slug,
            'is_active'    => $data['is_active'] ?? true,
            'created_by'   => $request->user()->id,
        ]);

        foreach ($data['questions'] as $qi => $qData) {
            $question = $survey->questions()->create([
                'question_text' => $qData['question_text'],
                'hint'          => $qData['hint'] ?? null,
                'order_index'   => $qData['order_index'] ?? $qi,
            ]);
            foreach ($qData['options'] as $oi => $oData) {
                $question->options()->create([
                    'label'       => $oData['label'],
                    'score_value' => $oData['score_value'],
                    'color'       => $oData['color'] ?? 'green',
                    'order_index' => $oData['order_index'] ?? $oi,
                ]);
            }
        }

        foreach ($data['result_bands'] as $bi => $bData) {
            $band = $survey->resultBands()->create([
                'label'              => $bData['label'],
                'min_score'          => $bData['min_score'],
                'max_score'          => $bData['max_score'],
                'message'            => $bData['message'],
                'result_type'        => $bData['result_type'],
                'show_therapist_cta' => $bData['show_therapist_cta'] ?? false,
                'order_index'        => $bData['order_index'] ?? $bi,
            ]);
            if (!empty($bData['material_ids'])) {
                $band->materials()->sync($bData['material_ids']);
            }
        }

        return response()->json([
            'success' => true,
            'data'    => $survey->load(['questions.options', 'resultBands.materials']),
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $this->requireAdmin($request);

        $survey = Survey::findOrFail($id);

        $data = $request->validate([
            'title'        => 'sometimes|string|max:255',
            'description'  => 'nullable|string',
            'instructions' => 'nullable|string',
            'slug'         => 'nullable|string|unique:surveys,slug,' . $id,
            'is_active'    => 'boolean',
            'questions'    => 'sometimes|array|min:1',
            'questions.*.id'            => 'nullable|integer',
            'questions.*.question_text' => 'required|string',
            'questions.*.hint'          => 'nullable|string',
            'questions.*.order_index'   => 'integer',
            'questions.*.options'       => 'required|array|min:2',
            'questions.*.options.*.id'          => 'nullable|integer',
            'questions.*.options.*.label'       => 'required|string',
            'questions.*.options.*.score_value' => 'required|integer|min:0',
            'questions.*.options.*.color'       => 'nullable|string',
            'questions.*.options.*.order_index' => 'integer',
            'result_bands' => 'sometimes|array|min:1',
            'result_bands.*.id'                 => 'nullable|integer',
            'result_bands.*.label'              => 'required|string',
            'result_bands.*.min_score'          => 'required|integer|min:0',
            'result_bands.*.max_score'          => 'required|integer|min:0',
            'result_bands.*.message'            => 'required|string',
            'result_bands.*.result_type'        => 'required|in:low,moderate,high',
            'result_bands.*.show_therapist_cta' => 'boolean',
            'result_bands.*.order_index'        => 'integer',
            'result_bands.*.material_ids'       => 'nullable|array',
            'result_bands.*.material_ids.*'     => 'integer|exists:mental_health_materials,id',
        ]);

        $survey->update(array_filter([
            'title'        => $data['title'] ?? null,
            'description'  => $data['description'] ?? null,
            'instructions' => $data['instructions'] ?? null,
            'slug'         => $data['slug'] ?? null,
            'is_active'    => $data['is_active'] ?? null,
        ], fn($v) => $v !== null));

        if (isset($data['questions'])) {
            $survey->questions()->delete();
            foreach ($data['questions'] as $qi => $qData) {
                $question = $survey->questions()->create([
                    'question_text' => $qData['question_text'],
                    'hint'          => $qData['hint'] ?? null,
                    'order_index'   => $qData['order_index'] ?? $qi,
                ]);
                foreach ($qData['options'] as $oi => $oData) {
                    $question->options()->create([
                        'label'       => $oData['label'],
                        'score_value' => $oData['score_value'],
                        'color'       => $oData['color'] ?? 'green',
                        'order_index' => $oData['order_index'] ?? $oi,
                    ]);
                }
            }
        }

        if (isset($data['result_bands'])) {
            $survey->resultBands()->each(fn($b) => $b->materials()->detach());
            $survey->resultBands()->delete();
            foreach ($data['result_bands'] as $bi => $bData) {
                $band = $survey->resultBands()->create([
                    'label'              => $bData['label'],
                    'min_score'          => $bData['min_score'],
                    'max_score'          => $bData['max_score'],
                    'message'            => $bData['message'],
                    'result_type'        => $bData['result_type'],
                    'show_therapist_cta' => $bData['show_therapist_cta'] ?? false,
                    'order_index'        => $bData['order_index'] ?? $bi,
                ]);
                if (!empty($bData['material_ids'])) {
                    $band->materials()->sync($bData['material_ids']);
                }
            }
        }

        return response()->json([
            'success' => true,
            'data'    => $survey->fresh()->load(['questions.options', 'resultBands.materials']),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $this->requireAdmin($request);

        $survey = Survey::findOrFail($id);
        $survey->resultBands()->each(fn($b) => $b->materials()->detach());
        $survey->delete();

        return response()->json(['success' => true]);
    }

    public function adminIndex(Request $request)
    {
        $this->requireAdmin($request);

        $surveys = Survey::withCount(['questions', 'responses'])
            ->orderByDesc('id')
            ->get();

        return response()->json(['success' => true, 'data' => $surveys]);
    }

    public function adminShow(Request $request, int $id)
    {
        $this->requireAdmin($request);

        $survey = Survey::with(['questions.options', 'resultBands.materials'])->findOrFail($id);

        return response()->json(['success' => true, 'data' => $survey]);
    }

    // ── Private ──────────────────────────────────────────────

    private function requireAdmin(Request $request): void
    {
        $user = $request->user();
        if (!$user || $user->account_type !== 3) {
            abort(403, 'Forbidden');
        }
    }
}
