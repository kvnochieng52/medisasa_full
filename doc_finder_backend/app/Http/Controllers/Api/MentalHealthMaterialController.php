<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MentalHealthMaterial;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class MentalHealthMaterialController extends Controller
{
    // GET /mental-health-materials/{id}  (public)
    public function show(int $id)
    {
        try {
            $material = MentalHealthMaterial::where('id', $id)->where('is_active', true)->firstOrFail();
            return response()->json(['success' => true, 'data' => $material]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Material not found'], 404);
        }
    }

    // GET /mental-health-materials  (public)
    public function index(Request $request)
    {
        try {
            $query = MentalHealthMaterial::where('is_active', true);

            if ($request->type === 'free') {
                $query->where('is_free', true);
            } elseif ($request->type === 'paid') {
                $query->where('is_free', false);
            }

            if ($request->filled('survey_id')) {
                $query->where('survey_id', $request->survey_id);
            }

            $materials = $query->with('survey:id,title,slug')->orderByDesc('created_at')->get();

            return response()->json(['success' => true, 'data' => $materials]);
        } catch (\Exception $e) {
            Log::error('MentalHealthMaterial index: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to load materials'], 500);
        }
    }

    // GET /surveys/{id}/materials  (public)
    public function bySurvey(int $surveyId)
    {
        try {
            $materials = MentalHealthMaterial::where('is_active', true)
                ->where('survey_id', $surveyId)
                ->orderByDesc('created_at')
                ->get();

            return response()->json(['success' => true, 'data' => $materials]);
        } catch (\Exception $e) {
            Log::error('MentalHealthMaterial bySurvey: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to load materials'], 500);
        }
    }

    // POST /mental-health-materials  (auth)
    public function store(Request $request)
    {
        $request->validate([
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_free'     => 'required|boolean',
            'price'       => 'nullable|numeric|min:0',
            'is_active'   => 'nullable|boolean',
            'survey_id'   => 'nullable|exists:surveys,id',
            'image'       => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
            'file'        => 'nullable|file|mimes:pdf,mp4,mov,avi,webm|max:102400',
        ]);

        try {
            $isFree = $request->boolean('is_free');
            $data = [
                'title'       => $request->title,
                'description' => $request->description,
                'is_free'     => $isFree,
                'price'       => $isFree ? null : $request->price,
                'is_active'   => $request->boolean('is_active', true),
                'created_by'  => auth()->id(),
                'survey_id'   => $request->survey_id ?: null,
            ];

            if ($request->hasFile('image')) {
                $data['image_path'] = $request->file('image')->store('mental_health/images', 'public');
            }

            if ($request->hasFile('file')) {
                $file     = $request->file('file');
                $mime     = $file->getMimeType();
                $fileType = str_starts_with($mime, 'video/') ? 'video' : 'pdf';
                $data['file_path'] = $file->store('mental_health/files', 'public');
                $data['file_type'] = $fileType;
            }

            $material = MentalHealthMaterial::create($data);

            return response()->json(['success' => true, 'message' => 'Material uploaded', 'data' => $material], 201);
        } catch (\Exception $e) {
            Log::error('MentalHealthMaterial store: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to upload material'], 500);
        }
    }

    // PUT /mental-health-materials/{id}  (auth)
    public function update(Request $request, $id)
    {
        $material = MentalHealthMaterial::where('id', $id)->where('created_by', auth()->id())->firstOrFail();

        $request->validate([
            'title'       => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'is_free'     => 'nullable|boolean',
            'price'       => 'nullable|numeric|min:0',
            'is_active'   => 'nullable|boolean',
            'survey_id'   => 'nullable|exists:surveys,id',
            'image'       => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
            'file'        => 'nullable|file|mimes:pdf,mp4,mov,avi,webm|max:102400',
        ]);

        try {
            $isFree = $request->has('is_free') ? $request->boolean('is_free') : $material->is_free;
            $data = array_filter([
                'title'       => $request->title,
                'description' => $request->description,
                'is_free'     => $request->has('is_free') ? $request->boolean('is_free') : null,
                'price'       => $isFree ? null : ($request->has('price') ? $request->price : $material->price),
                'is_active'   => $request->has('is_active') ? $request->boolean('is_active') : null,
                'survey_id'   => $request->has('survey_id') ? ($request->survey_id ?: null) : null,
            ], fn($v) => $v !== null);

            if ($request->hasFile('image')) {
                if ($material->image_path) Storage::disk('public')->delete($material->image_path);
                $data['image_path'] = $request->file('image')->store('mental_health/images', 'public');
            }

            if ($request->hasFile('file')) {
                if ($material->file_path) Storage::disk('public')->delete($material->file_path);
                $file     = $request->file('file');
                $mime     = $file->getMimeType();
                $fileType = str_starts_with($mime, 'video/') ? 'video' : 'pdf';
                $data['file_path'] = $file->store('mental_health/files', 'public');
                $data['file_type'] = $fileType;
            }

            $material->update($data);

            return response()->json(['success' => true, 'message' => 'Material updated', 'data' => $material->fresh()]);
        } catch (\Exception $e) {
            Log::error('MentalHealthMaterial update: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to update material'], 500);
        }
    }

    // DELETE /mental-health-materials/{id}  (auth)
    public function destroy($id)
    {
        $material = MentalHealthMaterial::where('id', $id)->where('created_by', auth()->id())->firstOrFail();

        try {
            if ($material->image_path) Storage::disk('public')->delete($material->image_path);
            if ($material->file_path)  Storage::disk('public')->delete($material->file_path);
            $material->delete();

            return response()->json(['success' => true, 'message' => 'Material deleted']);
        } catch (\Exception $e) {
            Log::error('MentalHealthMaterial destroy: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to delete material'], 500);
        }
    }
}
