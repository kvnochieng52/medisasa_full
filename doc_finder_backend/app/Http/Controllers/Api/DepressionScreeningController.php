<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DepressionScreening;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DepressionScreeningController extends Controller
{
    // POST /depression-screenings  (public)
    public function store(Request $request)
    {
        $request->validate([
            'q1_score' => 'required|integer|min:0|max:3',
            'q2_score' => 'required|integer|min:0|max:3',
            'answers'  => 'required|array',
        ]);

        try {
            $total = $request->integer('q1_score') + $request->integer('q2_score');

            $screening = DepressionScreening::create([
                'user_id'     => auth()->id(),
                'q1_score'    => $request->integer('q1_score'),
                'q2_score'    => $request->integer('q2_score'),
                'total_score' => $total,
                'answers'     => $request->answers,
                'ip_address'  => $request->ip(),
            ]);

            $resultType = $total <= 2 ? 'low' : 'high';

            $message = $resultType === 'low'
                ? 'Thank you very much for using our service today. I can tell from your responses that you have good coping strategies. Please continue using these and get more tips on coping better. However, should you begin to feel worse, get in touch with us again.'
                : 'Thank you very much for using our service today. I can tell from your responses that you need further assessment and screening by a specialist who will also support you with expert information on coping better.';

            return response()->json([
                'success' => true,
                'data'    => [
                    'id'          => $screening->id,
                    'total_score' => $total,
                    'result_type' => $resultType,
                    'message'     => $message,
                ],
            ], 201);
        } catch (\Exception $e) {
            Log::error('DepressionScreening store: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to save screening'], 500);
        }
    }

    // GET /depression-screenings/history  (auth)
    public function userHistory(Request $request)
    {
        try {
            $history = DepressionScreening::where('user_id', auth()->id())
                ->orderByDesc('created_at')
                ->limit(10)
                ->get(['id', 'q1_score', 'q2_score', 'total_score', 'created_at']);

            return response()->json(['success' => true, 'data' => $history]);
        } catch (\Exception $e) {
            Log::error('DepressionScreening history: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to load history'], 500);
        }
    }
}
