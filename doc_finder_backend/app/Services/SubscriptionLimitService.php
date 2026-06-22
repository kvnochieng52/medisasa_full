<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\DoctorSubscription;
use App\Models\Facility;
use App\Models\SubscriptionPackage;
use App\Models\User;

class SubscriptionLimitService
{
    private function getActiveSubscription(User $user): ?DoctorSubscription
    {
        return DoctorSubscription::where('user_id', $user->id)
            ->where('status', 'paid')
            ->where('subscription_ends_at', '>', now())
            ->latest()
            ->first();
    }

    private function getPackage(DoctorSubscription $subscription): ?SubscriptionPackage
    {
        return SubscriptionPackage::where('slug', $subscription->plan)->first();
    }

    /** Returns ['allowed' => bool, 'message' => string] */
    public function canCreateFacility(User $user): array
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription) {
            return [
                'allowed' => false,
                'message' => 'An active subscription is required to create facilities.',
            ];
        }

        $package = $this->getPackage($subscription);

        if (!$package || $package->max_facilities === null) {
            return ['allowed' => true];
        }

        $current = Facility::where('created_by', $user->id)->count();

        if ($current >= $package->max_facilities) {
            $word = $package->max_facilities === 1 ? 'facility' : 'facilities';
            return [
                'allowed' => false,
                'message' => "Your {$package->name} plan allows up to {$package->max_facilities} {$word}. Upgrade your plan to add more.",
            ];
        }

        return ['allowed' => true];
    }

    /** Checks the DOCTOR's subscription limit for incoming appointments. */
    public function canReceiveAppointment(User $doctor): array
    {
        $subscription = $this->getActiveSubscription($doctor);

        if (!$subscription) {
            return [
                'allowed' => false,
                'message' => 'This doctor does not have an active subscription.',
            ];
        }

        $package = $this->getPackage($subscription);

        if (!$package || $package->max_appointments_per_month === null) {
            return ['allowed' => true];
        }

        $usedThisMonth = Appointment::where('doctor_id', $doctor->id)
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->count();

        if ($usedThisMonth >= $package->max_appointments_per_month) {
            return [
                'allowed' => false,
                'message' => "This doctor has reached their monthly appointment limit ({$package->max_appointments_per_month}). Please try again next month or contact them directly.",
            ];
        }

        return ['allowed' => true];
    }

    /** Returns full subscription info for a user, or null if none active. */
    public function getSubscriptionInfo(User $user): ?array
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription) {
            return null;
        }

        $package = $this->getPackage($subscription);

        return [
            'id'                          => $subscription->id,
            'plan'                        => $subscription->plan,
            'plan_name'                   => $package?->name ?? ucfirst($subscription->plan),
            'amount'                      => $subscription->amount,
            'currency'                    => $subscription->currency,
            'status'                      => $subscription->status,
            'subscription_starts_at'      => $subscription->subscription_starts_at,
            'subscription_ends_at'        => $subscription->subscription_ends_at,
            'days_remaining'              => (int) now()->diffInDays($subscription->subscription_ends_at, false),
            'limits'                      => [
                'max_appointments_per_month' => $package?->max_appointments_per_month,
                'max_facilities'             => $package?->max_facilities,
                'max_hospitals'              => $package?->max_hospitals,
            ],
        ];
    }
}
