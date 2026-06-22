<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PharmacyOrder;
use App\Services\DpoPayService;
use Illuminate\Http\Request;

class PharmacyOrderController extends Controller
{
    public function __construct(private DpoPayService $dpoService) {}

    // POST /pharmacy-orders
    public function store(Request $request)
    {
        $request->validate([
            'customer_name'    => 'required|string',
            'customer_phone'   => 'required|string',
            'delivery_option'  => 'required|in:standard,express,pickup',
            'delivery_fee'     => 'required|numeric|min:0',
            'subtotal'         => 'required|numeric|min:0',
            'total'            => 'required|numeric|min:0',
            'items'            => 'required|array|min:1',
            'delivery_address' => 'nullable|string',
            'delivery_city'    => 'nullable|string',
            'notes'            => 'nullable|string',
        ]);

        $orderRef = 'ORD_' . strtoupper(uniqid());
        $baseUrl  = rtrim(config('app.url'), '/');

        $order = PharmacyOrder::create([
            'user_id'          => $request->user()?->id,
            'order_ref'        => $orderRef,
            'customer_name'    => $request->customer_name,
            'customer_phone'   => $request->customer_phone,
            'delivery_option'  => $request->delivery_option,
            'delivery_fee'     => $request->delivery_fee,
            'subtotal'         => $request->subtotal,
            'total'            => $request->total,
            'delivery_address' => $request->delivery_address,
            'delivery_city'    => $request->delivery_city,
            'notes'            => $request->notes,
            'items'            => $request->items,
            'status'           => 'pending',
        ]);

        $tokenResult = $this->dpoService->createToken([
            'amount'       => number_format($request->total, 2, '.', ''),
            'company_ref'  => $orderRef,
            'description'  => 'Pharmacy Order ' . $orderRef . ' - ' . $request->customer_name,
            'redirect_url' => $baseUrl . '/payment/callback',
            'back_url'     => $baseUrl . '/payment/cancel',
        ]);

        if (!$tokenResult['success']) {
            $order->delete();
            return response()->json(['success' => false, 'message' => $tokenResult['message']], 502);
        }

        $order->update([
            'dpo_trans_token' => $tokenResult['trans_token'],
            'dpo_trans_ref'   => $tokenResult['trans_ref'] ?? null,
            'company_ref'     => $orderRef,
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'order_ref'   => $orderRef,
                'order_id'    => $order->id,
                'payment_url' => $this->dpoService->getPaymentUrl($tokenResult['trans_token']),
                'trans_token' => $tokenResult['trans_token'],
            ],
        ]);
    }

    // GET /pharmacy-orders/verify/{transToken}
    public function verify(Request $request, string $transToken)
    {
        $order = PharmacyOrder::where('dpo_trans_token', $transToken)->first();

        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found'], 404);
        }

        if ($order->status === 'paid') {
            return response()->json(['success' => true, 'data' => ['status' => 'paid', 'order_ref' => $order->order_ref]]);
        }

        $result = $this->dpoService->verifyToken($transToken);

        if ($result['success'] && $result['status'] === 'paid') {
            $order->update(['status' => 'paid']);
        } elseif (in_array($result['status'] ?? '', ['failed', 'cancelled'])) {
            $order->update(['status' => $result['status']]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'status'    => $order->fresh()->status,
                'order_ref' => $order->order_ref,
            ],
        ]);
    }
}
