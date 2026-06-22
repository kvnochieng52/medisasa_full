<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DoctorSubscription;
use App\Models\SubscriptionPackage;
use App\Services\DpoPayService;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    public function __construct(private DpoPayService $dpoService) {}

    public function plans()
    {
        $packages = SubscriptionPackage::where('is_active', true)
            ->orderBy('amount')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => ['plans' => $packages],
        ]);
    }

    public function status(Request $request)
    {
        $subscription = DoctorSubscription::where('user_id', $request->user()->id)
            ->where('status', 'paid')
            ->where('subscription_ends_at', '>', now())
            ->latest()
            ->first();

        return response()->json([
            'success' => true,
            'data'    => [
                'has_active_subscription' => (bool) $subscription,
                'subscription' => $subscription ? [
                    'plan'    => $subscription->plan,
                    'ends_at' => $subscription->subscription_ends_at,
                ] : null,
            ],
        ]);
    }

    public function details(Request $request)
    {
        $subscription = DoctorSubscription::where('user_id', $request->user()->id)
            ->where('status', 'paid')
            ->where('subscription_ends_at', '>', now())
            ->latest()
            ->first();

        return response()->json([
            'success' => true,
            'data'    => $subscription,
        ]);
    }

    public function initiatePayment(Request $request)
    {
        $request->validate([
            'plan'           => 'required|string|exists:subscription_packages,slug',
            'payment_method' => 'nullable|string',
        ]);

        $package = SubscriptionPackage::where('slug', $request->plan)
            ->where('is_active', true)
            ->firstOrFail();

        $user       = $request->user();
        $companyRef = 'SUB_' . $user->id . '_' . time();
        $baseUrl    = rtrim(config('app.url'), '/');

        $tokenResult = $this->dpoService->createToken([
            'amount'       => number_format($package->amount, 2, '.', ''),
            'company_ref'  => $companyRef,
            'description'  => $package->name . ' Subscription - ' . $user->name,
            'redirect_url' => $baseUrl . '/payment/callback',
            'back_url'     => $baseUrl . '/payment/cancel',
        ]);

        if (!$tokenResult['success']) {
            return response()->json([
                'success' => false,
                'message' => $tokenResult['message'],
            ], 502);
        }

        DoctorSubscription::create([
            'user_id'         => $user->id,
            'plan'            => $package->slug,
            'amount'          => $package->amount,
            'payment_method'  => $request->payment_method,
            'status'          => 'pending',
            'dpo_trans_token' => $tokenResult['trans_token'],
            'dpo_trans_ref'   => $tokenResult['trans_ref'] ?? null,
            'company_ref'     => $companyRef,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment initiated',
            'data'    => [
                'payment_url' => $this->dpoService->getPaymentUrl($tokenResult['trans_token']),
                'trans_token' => $tokenResult['trans_token'],
                'company_ref' => $companyRef,
            ],
        ]);
    }

    public function verifyPayment(Request $request, string $transToken)
    {
        $subscription = DoctorSubscription::where('dpo_trans_token', $transToken)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$subscription) {
            return response()->json(['success' => false, 'message' => 'Transaction not found'], 404);
        }

        if ($subscription->status === 'paid') {
            return response()->json([
                'success' => true,
                'data'    => ['status' => 'paid', 'message' => 'Payment confirmed'],
            ]);
        }

        $result = $this->dpoService->verifyToken($transToken);

        if ($result['success'] && $result['status'] === 'paid') {
            $package = SubscriptionPackage::where('slug', $subscription->plan)->first();
            $days    = $package ? $package->duration_days : 30;

            $subscription->update([
                'status'                 => 'paid',
                'dpo_transaction_id'     => $result['dpo_transaction_id'] ?? null,
                'subscription_starts_at' => now(),
                'subscription_ends_at'   => now()->addDays($days),
            ]);
        } elseif (in_array($result['status'], ['failed', 'cancelled'])) {
            $subscription->update(['status' => $result['status']]);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'status'  => $subscription->fresh()->status,
                'message' => $result['message'] ?? '',
            ],
        ]);
    }

    public function cancel(Request $request)
    {
        $subscription = DoctorSubscription::where('user_id', $request->user()->id)
            ->where('status', 'paid')
            ->where('subscription_ends_at', '>', now())
            ->latest()
            ->first();

        if (!$subscription) {
            return response()->json(['success' => false, 'message' => 'No active subscription found'], 404);
        }

        $subscription->update(['status' => 'cancelled']);

        return response()->json([
            'success' => true,
            'message' => 'Subscription cancelled successfully',
        ]);
    }
}
