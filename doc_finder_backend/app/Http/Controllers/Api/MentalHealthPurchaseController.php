<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MentalHealthMaterial;
use App\Models\MentalHealthPurchase;
use App\Services\DpoPayService;
use Illuminate\Http\Request;

class MentalHealthPurchaseController extends Controller
{
    public function __construct(private DpoPayService $dpoService) {}

    // POST /mental-health-materials/{id}/purchase  (auth)
    public function initiate(Request $request, int $id)
    {
        $material = MentalHealthMaterial::where('id', $id)
            ->where('is_active', true)
            ->where('is_free', false)
            ->firstOrFail();

        $userId  = auth()->id();
        $baseUrl = rtrim(config('app.url'), '/');

        $existing = MentalHealthPurchase::where('user_id', $userId)
            ->where('material_id', $material->id)
            ->where('status', 'paid')
            ->first();

        if ($existing) {
            return response()->json(['success' => false, 'message' => 'You already have access to this material'], 422);
        }

        $purchaseRef = 'MHP_' . strtoupper(uniqid());

        $purchase = MentalHealthPurchase::create([
            'user_id'      => $userId,
            'material_id'  => $material->id,
            'purchase_ref' => $purchaseRef,
            'amount'       => $material->price,
            'status'       => 'pending',
        ]);

        $tokenResult = $this->dpoService->createToken([
            'amount'       => number_format($material->price, 2, '.', ''),
            'company_ref'  => $purchaseRef,
            'description'  => 'Mental Health Material: ' . $material->title,
            'redirect_url' => $baseUrl . '/payment/callback',
            'back_url'     => $baseUrl . '/payment/cancel',
        ]);

        if (!$tokenResult['success']) {
            $purchase->delete();
            return response()->json(['success' => false, 'message' => $tokenResult['message']], 502);
        }

        $purchase->update(['dpo_trans_token' => $tokenResult['trans_token']]);

        return response()->json([
            'success' => true,
            'data' => [
                'purchase_ref' => $purchaseRef,
                'payment_url'  => $this->dpoService->getPaymentUrl($tokenResult['trans_token']),
                'trans_token'  => $tokenResult['trans_token'],
            ],
        ]);
    }

    // GET /mental-health-purchases/verify/{transToken}  (public)
    public function verify(string $transToken)
    {
        $purchase = MentalHealthPurchase::where('dpo_trans_token', $transToken)->first();

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found'], 404);
        }

        if ($purchase->status === 'paid') {
            return response()->json(['success' => true, 'data' => ['status' => 'paid', 'material_id' => $purchase->material_id]]);
        }

        $result = $this->dpoService->verifyToken($transToken);

        if ($result['success'] && $result['status'] === 'paid') {
            $purchase->update(['status' => 'paid']);
        } elseif (in_array($result['status'] ?? '', ['failed', 'cancelled'])) {
            $purchase->update(['status' => $result['status']]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'status'      => $purchase->fresh()->status,
                'material_id' => $purchase->material_id,
            ],
        ]);
    }

    // GET /mental-health-purchases/my  (auth)
    public function myPurchases()
    {
        $ids = MentalHealthPurchase::where('user_id', auth()->id())
            ->where('status', 'paid')
            ->pluck('material_id');

        return response()->json(['success' => true, 'data' => $ids]);
    }
}
