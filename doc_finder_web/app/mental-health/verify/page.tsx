"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import { Brain, CheckCircle2, XCircle, Loader2, BookOpen, ArrowLeft } from "lucide-react";
import api from "@/lib/api";

type Status = "verifying" | "paid" | "failed" | "cancelled" | "not_found";

function VerifyPageInner() {
  const searchParams = useSearchParams();
  const router       = useRouter();
  const cancelled    = searchParams.get("cancelled");
  // Token comes from ?token= URL param (if DPO appends it) or sessionStorage
  const urlToken     = searchParams.get("token");
  const token        = urlToken || (typeof window !== "undefined" ? sessionStorage.getItem("mh_trans_token") : null);

  const [status, setStatus]       = useState<Status>(cancelled ? "cancelled" : "verifying");
  const [materialId, setMaterialId] = useState<number | null>(null);
  const [attempts, setAttempts]   = useState(0);

  useEffect(() => {
    if (cancelled || !token) {
      setStatus(cancelled ? "cancelled" : "not_found");
      return;
    }

    let interval: NodeJS.Timeout;
    let count = 0;

    const check = async () => {
      count++;
      setAttempts(count);
      try {
        const res = await api.get<{ success: boolean; data: { status: string; material_id: number } }>(
          `/mental-health-purchases/verify/${token}`
        );
        const s = res.data.data.status;
        if (s === "paid") {
          setMaterialId(res.data.data.material_id);
          setStatus("paid");
          sessionStorage.removeItem("mh_trans_token");
          clearInterval(interval);
        } else if (s === "failed" || s === "cancelled") {
          setStatus(s as Status);
          sessionStorage.removeItem("mh_trans_token");
          clearInterval(interval);
        } else if (count >= 24) {
          setStatus("failed");
          clearInterval(interval);
        }
      } catch {
        if (count >= 24) {
          setStatus("not_found");
          clearInterval(interval);
        }
      }
    };

    check();
    interval = setInterval(check, 5000);
    return () => clearInterval(interval);
  }, [token, cancelled]);

  return (
    <main className="min-h-screen bg-gradient-to-br from-violet-50 via-purple-50 to-pink-50">
      <Navbar />
      <div className="max-w-lg mx-auto px-4 pt-32 pb-16 text-center">

        {status === "verifying" && (
          <div>
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center mx-auto mb-6 shadow-lg animate-pulse">
              <Brain className="w-10 h-10 text-white" />
            </div>
            <Loader2 className="w-8 h-8 animate-spin text-purple-500 mx-auto mb-4" />
            <h2 className="text-xl font-bold text-gray-900 mb-2">Confirming your payment…</h2>
            <p className="text-sm text-gray-500">This usually takes a few seconds. Please don&apos;t close this page.</p>
            {attempts > 3 && (
              <p className="text-xs text-gray-400 mt-3">Still checking ({attempts * 5}s)…</p>
            )}
          </div>
        )}

        {status === "paid" && (
          <div>
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-green-400 to-emerald-500 flex items-center justify-center mx-auto mb-6 shadow-lg">
              <CheckCircle2 className="w-10 h-10 text-white" />
            </div>
            <div className="inline-flex items-center gap-2 bg-green-100 text-green-700 font-bold text-sm px-4 py-1.5 rounded-full mb-4">
              Payment Successful
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-3">You&apos;re all set!</h2>
            <p className="text-gray-500 text-sm mb-8">
              Your purchase is confirmed. You now have full access to this resource.
            </p>
            <div className="flex flex-col gap-3">
              <Link href="/mental-health"
                className="inline-flex items-center justify-center gap-2 px-6 py-3.5 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 text-white font-bold text-sm rounded-xl transition-all shadow-sm">
                <BookOpen className="w-4 h-4" /> Go to Resources
              </Link>
              <button onClick={() => router.back()}
                className="inline-flex items-center justify-center gap-2 text-sm text-gray-500 hover:text-gray-700 font-semibold">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
            </div>
          </div>
        )}

        {(status === "failed" || status === "cancelled" || status === "not_found") && (
          <div>
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-red-400 to-rose-500 flex items-center justify-center mx-auto mb-6 shadow-lg">
              <XCircle className="w-10 h-10 text-white" />
            </div>
            <div className="inline-flex items-center gap-2 bg-red-100 text-red-700 font-bold text-sm px-4 py-1.5 rounded-full mb-4">
              {status === "cancelled" ? "Payment Cancelled" : "Payment Failed"}
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-3">
              {status === "cancelled" ? "You cancelled the payment" : "Something went wrong"}
            </h2>
            <p className="text-gray-500 text-sm mb-8">
              {status === "cancelled"
                ? "Your payment was cancelled. No charge was made."
                : "The payment could not be completed. Please try again."}
            </p>
            <div className="flex flex-col gap-3">
              <Link href="/mental-health"
                className="inline-flex items-center justify-center gap-2 px-6 py-3.5 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 text-white font-bold text-sm rounded-xl transition-all shadow-sm">
                <BookOpen className="w-4 h-4" /> Back to Resources
              </Link>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}

export default function MentalHealthVerifyPage() {
  return (
    <Suspense fallback={
      <main className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-purple-500" />
      </main>
    }>
      <VerifyPageInner />
    </Suspense>
  );
}
