"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  CheckCircle2, Sparkles, ChevronRight, Loader2,
  X, ExternalLink, RefreshCw, AlertCircle,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Plan {
  id: number;
  slug: string;
  name: string;
  amount: string;
  currency: string;
  duration_days: number;
  description: string;
  features: string[];
  is_popular: boolean;
  max_facilities: number | null;
  max_hospitals: number | null;
  max_appointments_per_month: number | null;
}

type PaymentState = "idle" | "initiating" | "polling" | "timeout" | "failed";

const POLL_INTERVAL_MS = 5000;
const MAX_POLLS = 36; // 3 minutes

export default function SubscriptionPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [paymentState, setPaymentState] = useState<PaymentState>("idle");
  const [transToken, setTransToken] = useState("");
  const [pollCount, setPollCount] = useState(0);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    api.get<{ data: { plans: Plan[] } }>("/subscription/plans")
      .then(res => setPlans(res.data.data?.plans ?? []))
      .catch(() => toast.error("Failed to load plans"))
      .finally(() => setLoading(false));
  }, []);

  // Cleanup polling on unmount
  useEffect(() => {
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, []);

  const stopPolling = () => {
    if (pollRef.current) { clearInterval(pollRef.current); pollRef.current = null; }
  };

  const startPolling = (token: string) => {
    let count = 0;
    pollRef.current = setInterval(async () => {
      count++;
      setPollCount(count);

      if (count >= MAX_POLLS) {
        stopPolling();
        setPaymentState("timeout");
        return;
      }

      try {
        const res = await api.get<{ data: { status: string } }>(`/subscription/verify-payment/${token}`);
        const status = res.data.data?.status;
        if (status === "paid") {
          stopPolling();
          router.push("/subscription/success");
        } else if (status === "failed" || status === "cancelled") {
          stopPolling();
          setPaymentState("failed");
        }
      } catch {
        // silently continue polling on network blip
      }
    }, POLL_INTERVAL_MS);
  };

  const handleSelectPlan = (plan: Plan) => {
    setSelectedPlan(plan);
    setPaymentState("idle");
    setTransToken("");
    setPollCount(0);
    setShowModal(true);
  };

  const handlePay = async () => {
    if (!selectedPlan) return;
    setPaymentState("initiating");
    try {
      const res = await api.post<{ data: { payment_url: string; trans_token: string } }>(
        "/subscription/payment",
        { plan: selectedPlan.slug, payment_method: "dpo" }
      );
      const { payment_url, trans_token } = res.data.data;
      setTransToken(trans_token);

      // Open DPO payment in new tab
      window.open(payment_url, "_blank", "noopener,noreferrer");

      setPaymentState("polling");
      setPollCount(0);
      startPolling(trans_token);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      toast.error(e?.response?.data?.message ?? "Failed to initiate payment");
      setPaymentState("idle");
    }
  };

  const handleCheckStatus = async () => {
    if (!transToken) return;
    setPaymentState("polling");
    setPollCount(0);
    startPolling(transToken);
  };

  const handleClose = () => {
    stopPolling();
    setShowModal(false);
    setPaymentState("idle");
    setTransToken("");
    setPollCount(0);
  };

  const formatAmount = (amount: string) =>
    new Intl.NumberFormat("en-KE", { style: "currency", currency: "KES", minimumFractionDigits: 0 }).format(Number(amount));

  const formatDuration = (days: number) => {
    if (days === 30) return "/ month";
    if (days === 90) return "/ quarter";
    if (days === 365) return "/ year";
    return `/ ${days} days`;
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-white to-white">
      <Navbar />
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-28 pb-16">

        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-8">
          <Link href="/dashboard" className="hover:text-brand-500 transition-colors">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Subscription Plans</span>
        </div>

        {/* Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-purple-100 text-purple-700 rounded-full text-sm font-semibold mb-4">
            <Sparkles className="w-4 h-4" /> Premium Plans
          </div>
          <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
            Choose Your Plan
          </h1>
          <p className="text-gray-500 max-w-xl mx-auto">
            Unlock full access to manage facilities, receive appointments, and grow your healthcare practice.
          </p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {plans.map(plan => (
              <PlanCard
                key={plan.slug}
                plan={plan}
                formatAmount={formatAmount}
                formatDuration={formatDuration}
                onSelect={() => handleSelectPlan(plan)}
              />
            ))}
          </div>
        )}

        <p className="text-center text-xs text-gray-400 mt-8">
          Payments are processed securely via DPO Pay. All amounts in KES.
        </p>
      </div>

      {/* ── Payment Modal ── */}
      {showModal && selectedPlan && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-md shadow-2xl overflow-hidden">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b">
              <h3 className="font-bold text-gray-800">
                {paymentState === "idle" || paymentState === "initiating" ? "Confirm Subscription" : "Payment Status"}
              </h3>
              {paymentState !== "polling" && (
                <button type="button" onClick={handleClose}>
                  <X className="w-5 h-5 text-gray-400" />
                </button>
              )}
            </div>

            <div className="p-6">
              {/* idle / initiating */}
              {(paymentState === "idle" || paymentState === "initiating") && (
                <>
                  <div className="bg-gray-50 rounded-2xl p-4 mb-6">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-sm font-semibold text-gray-700">{selectedPlan.name} Plan</span>
                      {selectedPlan.is_popular && (
                        <span className="text-xs bg-purple-100 text-purple-700 font-semibold px-2 py-0.5 rounded-full">
                          Most Popular
                        </span>
                      )}
                    </div>
                    <p className="text-2xl font-bold text-gray-900">
                      {formatAmount(selectedPlan.amount)}
                      <span className="text-sm font-normal text-gray-400 ml-1">{formatDuration(selectedPlan.duration_days)}</span>
                    </p>
                    <p className="text-xs text-gray-500 mt-2">{selectedPlan.description}</p>
                  </div>
                  <p className="text-xs text-gray-500 mb-5 text-center">
                    You&apos;ll be redirected to a secure payment page in a new tab. Keep this tab open.
                  </p>
                  <button
                    type="button"
                    onClick={handlePay}
                    disabled={paymentState === "initiating"}
                    className="w-full py-3.5 rounded-xl bg-purple-600 hover:bg-purple-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm"
                  >
                    {paymentState === "initiating"
                      ? <><Loader2 className="w-4 h-4 animate-spin" /> Opening payment…</>
                      : <><ExternalLink className="w-4 h-4" /> Pay Now</>}
                  </button>
                </>
              )}

              {/* polling */}
              {paymentState === "polling" && (
                <div className="text-center py-4">
                  <div className="w-16 h-16 rounded-full bg-purple-50 flex items-center justify-center mx-auto mb-4">
                    <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
                  </div>
                  <p className="font-bold text-gray-800 mb-2">Waiting for Payment</p>
                  <p className="text-sm text-gray-500 mb-1">
                    Complete the payment in the tab that just opened.
                  </p>
                  <p className="text-xs text-gray-400 mb-6">
                    Checking status… ({pollCount}/{MAX_POLLS})
                  </p>
                  <div className="w-full bg-gray-100 rounded-full h-1.5 mb-6">
                    <div
                      className="bg-purple-500 h-1.5 rounded-full transition-all"
                      style={{ width: `${(pollCount / MAX_POLLS) * 100}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400">
                    Do not close this tab. We&apos;ll automatically confirm your payment.
                  </p>
                </div>
              )}

              {/* timeout */}
              {paymentState === "timeout" && (
                <div className="text-center py-4">
                  <div className="w-16 h-16 rounded-full bg-amber-50 flex items-center justify-center mx-auto mb-4">
                    <AlertCircle className="w-8 h-8 text-amber-500" />
                  </div>
                  <p className="font-bold text-gray-800 mb-2">Taking Longer Than Expected</p>
                  <p className="text-sm text-gray-500 mb-6">
                    If you completed the payment, click &quot;Check Status&quot; to try again. Otherwise close and retry later.
                  </p>
                  <div className="flex gap-3">
                    <button type="button" onClick={handleClose}
                      className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50">
                      Close
                    </button>
                    <button type="button" onClick={handleCheckStatus}
                      className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-sm font-semibold transition-colors">
                      <RefreshCw className="w-4 h-4" /> Check Status
                    </button>
                  </div>
                </div>
              )}

              {/* failed */}
              {paymentState === "failed" && (
                <div className="text-center py-4">
                  <div className="w-16 h-16 rounded-full bg-red-50 flex items-center justify-center mx-auto mb-4">
                    <X className="w-8 h-8 text-red-500" />
                  </div>
                  <p className="font-bold text-gray-800 mb-2">Payment Failed or Cancelled</p>
                  <p className="text-sm text-gray-500 mb-6">
                    Your payment was not completed. You can try again with any plan.
                  </p>
                  <button type="button" onClick={handleClose}
                    className="w-full py-3 rounded-xl bg-gray-100 hover:bg-gray-200 text-sm font-semibold text-gray-700 transition-colors">
                    Close & Try Again
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

function PlanCard({ plan, formatAmount, formatDuration, onSelect }: {
  plan: Plan;
  formatAmount: (a: string) => string;
  formatDuration: (d: number) => string;
  onSelect: () => void;
}) {
  return (
    <div className={`relative bg-white rounded-2xl flex flex-col overflow-hidden transition-all ${
      plan.is_popular
        ? "shadow-xl ring-2 ring-purple-500 scale-[1.02]"
        : "shadow-card hover:shadow-card-hover"
    }`}>
      {plan.is_popular && (
        <div className="bg-purple-600 text-white text-xs font-bold text-center py-2 tracking-wide uppercase">
          Most Popular
        </div>
      )}
      <div className="p-6 flex flex-col flex-1">
        <h3 className="text-lg font-bold text-gray-900 mb-1">{plan.name}</h3>
        <p className="text-xs text-gray-400 mb-4">{plan.description}</p>

        <div className="mb-6">
          <span className="text-3xl font-bold text-gray-900">{formatAmount(plan.amount)}</span>
          <span className="text-sm text-gray-400 ml-1">{formatDuration(plan.duration_days)}</span>
        </div>

        {/* Limits */}
        <div className="flex gap-3 mb-5">
          <LimitBadge label="Facilities" value={plan.max_facilities} />
          <LimitBadge label="Hospitals" value={plan.max_hospitals} />
          <LimitBadge label="Appts/mo" value={plan.max_appointments_per_month} />
        </div>

        {/* Features */}
        <ul className="space-y-2 mb-8 flex-1">
          {(plan.features ?? []).map((f, i) => (
            <li key={i} className="flex items-start gap-2 text-sm text-gray-600">
              <CheckCircle2 className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
              {f}
            </li>
          ))}
        </ul>

        <button
          type="button"
          onClick={onSelect}
          className={`w-full py-3 rounded-xl font-semibold text-sm transition-colors ${
            plan.is_popular
              ? "bg-purple-600 hover:bg-purple-700 text-white shadow-sm"
              : "border-2 border-brand-500 text-brand-600 hover:bg-brand-50"
          }`}
        >
          Get Started
        </button>
      </div>
    </div>
  );
}

function LimitBadge({ label, value }: { label: string; value: number | null }) {
  return (
    <div className="flex-1 bg-gray-50 rounded-lg px-2 py-1.5 text-center">
      <p className="text-xs font-bold text-gray-700">{value === null ? "∞" : value}</p>
      <p className="text-xs text-gray-400 leading-tight">{label}</p>
    </div>
  );
}
