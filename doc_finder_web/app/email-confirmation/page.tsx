"use client";

import { Suspense, useState, useRef, useEffect } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { Heart, Loader2, MailCheck, RefreshCw } from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

function EmailConfirmationContent() {
  const params = useSearchParams();
  const router = useRouter();
  const email = params.get("email") ?? "";

  const [digits, setDigits] = useState(["", "", "", ""]);
  const [isVerifying, setIsVerifying] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const ref0 = useRef<HTMLInputElement>(null);
  const ref1 = useRef<HTMLInputElement>(null);
  const ref2 = useRef<HTMLInputElement>(null);
  const ref3 = useRef<HTMLInputElement>(null);
  const inputRefs = [ref0, ref1, ref2, ref3];

  // Focus first box on mount
  useEffect(() => {
    inputRefs[0].current?.focus();
  }, []);

  // Resend cooldown countdown
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const t = setTimeout(() => setResendCooldown((c) => c - 1), 1000);
    return () => clearTimeout(t);
  }, [resendCooldown]);

  const handleDigitChange = (index: number, value: string) => {
    const char = value.replace(/\D/g, "").slice(-1);
    const next = [...digits];
    next[index] = char;
    setDigits(next);
    if (char && index < 3) {
      inputRefs[index + 1].current?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !digits[index] && index > 0) {
      inputRefs[index - 1].current?.focus();
    }
    if (e.key === "ArrowLeft" && index > 0) inputRefs[index - 1].current?.focus();
    if (e.key === "ArrowRight" && index < 3) inputRefs[index + 1].current?.focus();
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 4);
    const next = ["", "", "", ""];
    pasted.split("").forEach((ch, i) => { next[i] = ch; });
    setDigits(next);
    const focusIdx = Math.min(pasted.length, 3);
    inputRefs[focusIdx].current?.focus();
  };

  const code = digits.join("");

  const handleVerify = async () => {
    if (code.length !== 4) {
      toast.error("Please enter the complete 4-digit code.");
      return;
    }
    setIsVerifying(true);
    try {
      const res = await api.post("/verify-email", {
        email,
        verification_code: code,
      });
      if (res.status === 200 || res.status === 201) {
        toast.success("Email verified successfully!");
        setTimeout(() => router.push("/login"), 1000);
      }
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = axiosErr?.response?.data;
      const msg =
        data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? "Verification failed. Please try again.");
      setDigits(["", "", "", ""]);
      inputRefs[0].current?.focus();
    } finally {
      setIsVerifying(false);
    }
  };

  const handleResend = async () => {
    if (resendCooldown > 0 || isResending) return;
    setIsResending(true);
    try {
      await api.post("/resend-verification", { email });
      toast.success("Verification code resent to your email.");
      setResendCooldown(60);
      setDigits(["", "", "", ""]);
      inputRefs[0].current?.focus();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      toast.error(axiosErr?.response?.data?.message ?? "Failed to resend code.");
    } finally {
      setIsResending(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-3xl shadow-xl p-8 sm:p-10">
          {/* Header */}
          <div className="flex flex-col items-center mb-8">
            <div className="w-16 h-16 rounded-2xl bg-brand-500 flex items-center justify-center shadow-md mb-4">
              <Heart className="w-8 h-8 text-white" fill="white" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900">Xyvra Health</h1>
          </div>

          {/* Icon + title */}
          <div className="text-center mb-6">
            <div className="w-16 h-16 rounded-full bg-brand-50 flex items-center justify-center mx-auto mb-4">
              <MailCheck className="w-8 h-8 text-brand-500" />
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">Verify Your Email</h2>
            <p className="text-gray-500 text-sm leading-relaxed">
              Enter the <strong>4-digit code</strong> sent to:
            </p>
            <p className="text-brand-500 font-semibold text-sm bg-brand-50 px-3 py-1.5 rounded-xl inline-block mt-2">
              {email || "your email"}
            </p>
          </div>

          {/* OTP boxes */}
          <div className="flex justify-center gap-3 mb-6">
            {digits.map((d, i) => (
              <input
                key={i}
                ref={inputRefs[i]}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={d}
                onChange={(e) => handleDigitChange(i, e.target.value)}
                onKeyDown={(e) => handleKeyDown(i, e)}
                onPaste={handlePaste}
                disabled={isVerifying}
                className={`w-14 h-14 text-center text-2xl font-bold rounded-xl border-2 outline-none transition-all bg-gray-50
                  ${d ? "border-brand-500 bg-brand-50 text-brand-600" : "border-gray-200"}
                  focus:border-brand-400 focus:ring-2 focus:ring-brand-100 focus:bg-white
                  disabled:opacity-50`}
              />
            ))}
          </div>

          {/* Verify button */}
          <button
            onClick={handleVerify}
            disabled={isVerifying || code.length !== 4}
            className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm mb-5"
          >
            {isVerifying ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Verifying...
              </>
            ) : (
              "Verify Email"
            )}
          </button>

          {/* Resend */}
          <div className="text-center">
            <p className="text-sm text-gray-500 mb-2">Didn&apos;t receive a code?</p>
            <button
              onClick={handleResend}
              disabled={isResending || resendCooldown > 0}
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-brand-500 hover:text-brand-600 disabled:text-gray-400 disabled:cursor-not-allowed transition-colors"
            >
              {isResending ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <RefreshCw className="w-3.5 h-3.5" />
              )}
              {resendCooldown > 0
                ? `Resend in ${resendCooldown}s`
                : isResending
                ? "Sending..."
                : "Resend Code"}
            </button>
          </div>
        </div>

        {/* Back to login */}
        <p className="text-center mt-6 text-sm text-gray-500">
          <Link href="/login" className="hover:text-brand-500 transition-colors">
            ← Back to Login
          </Link>
        </p>
      </div>
    </div>
  );
}

export default function EmailConfirmationPage() {
  return (
    <Suspense>
      <EmailConfirmationContent />
    </Suspense>
  );
}
