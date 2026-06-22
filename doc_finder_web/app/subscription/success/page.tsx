"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { CheckCircle2, Sparkles, ChevronRight, Loader2 } from "lucide-react";
import api from "@/lib/api";
import Navbar from "@/components/Navbar";

interface SubscriptionInfo {
  plan: string;
  ends_at: string;
}

const UNLOCKED_FEATURES = [
  "Manage clinics & hospitals",
  "Receive patient appointments",
  "Support group management",
  "Pharmacy listing",
];

export default function PaymentSuccessPage() {
  const router = useRouter();
  const [subscription, setSubscription] = useState<SubscriptionInfo | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    api.get<{ data: { has_active_subscription: boolean; subscription: SubscriptionInfo } }>("/subscription/status")
      .then(res => {
        if (res.data.data?.has_active_subscription) {
          setSubscription(res.data.data.subscription);
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [router]);

  return (
    <main className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-brand-50">
      <Navbar />
      <div className="max-w-lg mx-auto px-4 pt-28 pb-16 text-center">

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : (
          <>
            {/* Success icon */}
            <div className="relative inline-flex mb-8">
              <div className="w-24 h-24 rounded-full bg-green-100 flex items-center justify-center">
                <CheckCircle2 className="w-12 h-12 text-green-500" />
              </div>
              <div className="absolute -top-1 -right-1 w-8 h-8 rounded-full bg-purple-500 flex items-center justify-center shadow-lg">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
            </div>

            <h1 className="text-3xl font-bold text-gray-900 mb-2">Payment Received!</h1>
            <p className="text-gray-500 mb-8">
              Your subscription is now active. You have full access to all premium features.
            </p>

            {/* Subscription summary */}
            {subscription && (() => {
              const endsAt = new Date(subscription.ends_at);
              const daysRemaining = Math.max(0, Math.ceil((endsAt.getTime() - Date.now()) / 86_400_000));
              const planLabel = subscription.plan.charAt(0).toUpperCase() + subscription.plan.slice(1);
              return (
                <div className="bg-white rounded-2xl shadow-card p-6 mb-8 text-left">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="font-bold text-gray-800">{planLabel} Plan</h3>
                    <span className="text-xs bg-green-100 text-green-700 font-semibold px-2.5 py-1 rounded-full">Active</span>
                  </div>
                  <p className="text-xs text-gray-500 mb-5">
                    Expires {endsAt.toLocaleDateString("en-KE", {
                      day: "numeric", month: "long", year: "numeric",
                    })} &nbsp;·&nbsp; {daysRemaining} days remaining
                  </p>
                  <div className="border-t pt-4 space-y-2">
                    {UNLOCKED_FEATURES.map(f => (
                      <div key={f} className="flex items-center gap-2 text-sm text-gray-600">
                        <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0" />
                        {f}
                      </div>
                    ))}
                  </div>
                </div>
              );
            })()}

            {/* Actions */}
            <div className="flex flex-col sm:flex-row gap-3">
              <Link href="/admin/facilities/new"
                className="flex-1 flex items-center justify-center gap-2 py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors shadow-sm">
                Add Your First Facility
                <ChevronRight className="w-4 h-4" />
              </Link>
              <Link href="/dashboard"
                className="flex-1 flex items-center justify-center py-3.5 rounded-xl border border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition-colors">
                Go to Dashboard
              </Link>
            </div>
          </>
        )}
      </div>
    </main>
  );
}
