<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Condition;
use Illuminate\Http\Request;

class ConditionsController extends Controller
{
    public function index(Request $request)
    {
        try {
            $query = Condition::active();

            // If search term is provided, filter conditions
            if ($request->has('search') && !empty($request->search)) {
                $searchTerm = $request->search;
                $query->where('name', 'LIKE', "%{$searchTerm}%");
            }

            $conditions = $query->orderBy('name')->get(['id', 'name', 'description']);

            return response()->json([
                'success' => true,
                'data' => $conditions
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching conditions',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        try {
            $condition = Condition::active()->with('specializations')->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $condition
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Condition not found',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    public function getRelatedSpecializations(Request $request)
    {
        try {
            $conditionNames = $request->input('conditions', []);

            if (empty($conditionNames)) {
                return response()->json([
                    'success' => true,
                    'data' => []
                ]);
            }

            // Get specializations related to the provided conditions
            $specializations = Condition::whereIn('name', $conditionNames)
                ->with(['specializations' => function($query) {
                    $query->where('specializations.is_active', 1)
                          ->orderBy('condition_specialization_mappings.priority', 'desc');
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