<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Symptom;
use Illuminate\Http\Request;

class SymptomsController extends Controller
{
    public function index(Request $request)
    {
        try {
            $query = Symptom::active();

            // If search term is provided, filter symptoms
            if ($request->has('search') && !empty($request->search)) {
                $searchTerm = $request->search;
                $query->where('name', 'LIKE', "%{$searchTerm}%");
            }

            $symptoms = $query->orderBy('name')->get(['id', 'name', 'description']);

            return response()->json([
                'success' => true,
                'data' => $symptoms
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching symptoms',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        try {
            $symptom = Symptom::active()->with('specializations')->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $symptom
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Symptom not found',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    public function getRelatedSpecializations(Request $request)
    {
        try {
            $symptomNames = $request->input('symptoms', []);

            if (empty($symptomNames)) {
                return response()->json([
                    'success' => true,
                    'data' => []
                ]);
            }

            // Get specializations related to the provided symptoms
            $specializations = Symptom::whereIn('name', $symptomNames)
                ->with(['specializations' => function($query) {
                    $query->where('specializations.is_active', 1)
                          ->orderBy('symptom_specialization_mappings.priority', 'desc');
                }])
                ->get()
                ->pluck('specializations')
                ->flatten()
                ->unique('id')
                ->values();

            return response()->json([
                'success' => true,
                'data' => $specializations
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching related specializations',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}