<?php

namespace App\Http\Controllers;

use App\Models\DoctorSubscription;
use App\Models\SubscriptionPackage;
use App\Services\DpoPayService;
use Illuminate\Http\Request;

class PaymentCallbackController extends Controller
{
    public function handleCallback(Request $request)
    {
        $transToken = $request->get('TransactionToken') ?? $request->get('token');

        if (!$transToken) {
            return view('payment.result', [
                'status'     => 'error',
                'message'    => 'Invalid payment callback — no transaction token received.',
                'transToken' => null,
            ]);
        }

        $subscription = DoctorSubscription::where('dpo_trans_token', $transToken)->first();

        if (!$subscription) {
            return view('payment.result', [
                'status'     => 'error',
                'message'    => 'Transaction not found.',
                'transToken' => $transToken,
            ]);
        }

        if ($subscription->status === 'paid') {
            return view('payment.result', [
                'status'     => 'success',
                'message'    => 'Payment confirmed! You can return to the app.',
                'transToken' => $transToken,
            ]);
        }

        /** @var DpoPayService $dpoService */
        $dpoService = app(DpoPayService::class);
        $result     = $dpoService->verifyToken($transToken);

        if ($result['success'] && $result['status'] === 'paid') {
            $package = SubscriptionPackage::where('slug', $subscription->plan)->first();
            $days    = $package ? $package->duration_days : 30;

            $subscription->update([
                'status'                 => 'paid',
                'dpo_transaction_id'     => $result['dpo_transaction_id'] ?? null,
                'subscription_starts_at' => now(),
                'subscription_ends_at'   => now()->addDays($days),
            ]);

            return view('payment.result', [
                'status'     => 'success',
                'message'    => 'Payment successful! You can close this tab and return to the app.',
                'transToken' => $transToken,
            ]);
        }

        return view('payment.result', [
            'status'     => 'failed',
            'message'    => $result['message'] ?? 'Payment was not completed successfully.',
            'transToken' => $transToken,
        ]);
    }

    public function handleCancel(Request $request)
    {
        $transToken = $request->get('TransactionToken') ?? $request->get('token');

        return view('payment.result', [
            'status'     => 'cancelled',
            'message'    => 'Payment was cancelled. Return to the app to try again.',
            'transToken' => $transToken,
        ]);
    }
}
