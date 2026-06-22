"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Eye, EyeOff, Mail, Lock, Loader2, KeyRound, RefreshCw, ArrowLeft,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

type Step = "email" | "code" | "password";

export default function ResetPasswordPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");

  const [email, setEmail] = useState("");
  const [digits, setDigits] = useState(["", "", "", ""]);
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);

  const ref0 = useRef<HTMLInputElement>(null);
  const ref1 = useRef<HTMLInputElement>(null);
  const ref2 = useRef<HTMLInputElement>(null);
  const ref3 = useRef<HTMLInputElement>(null);
  const inputRefs = [ref0, ref1, ref2, ref3];

  useEffect(() => {
    if (step === "code") inputRefs[0].current?.focus();
  }, [step]);

  useEffect(() => {
    if (resendCooldown <= 0) return;
    const t = setTimeout(() => setResendCooldown((c) => c - 1), 1000);
    return () => clearTimeout(t);
  }, [resendCooldown]);

  const code = digits.join("");

  const sendCode = async () => {
    setIsLoading(true);
    try {
      await api.post("/send-reset-code", { email: email.trim() });
      toast.success("Reset code sent to your email.");
      setStep("code");
      setResendCooldown(60);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { message?: string } } };
      const data = axiosErr?.response?.data;
      toast.error(data?.message ?? "Failed to send reset code.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !/\S+@\S+\.\S+/.test(email)) {
      toast.error("Enter a valid email address.");
      return;
    }
    await sendCode();
  };

  const handleDigitChange = (index: number, value: string) => {
    const char = value.replace(/\D/g, "").slice(-1);
    const next = [...digits];
    next[index] = char;
    setDigits(next);
    if (char && index < 3) inputRefs[index + 1].current?.focus();
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

  const handleCodeSubmit = async () => {
    if (code.length !== 4) {
      toast.error("Please enter the complete 4-digit code.");
      return;
    }
    setIsLoading(true);
    try {
      await api.post("/verify-reset-code", { email: email.trim(), code });
      toast.success("Code verified. Set your new password.");
      setStep("password");
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      toast.error(axiosErr?.response?.data?.message ?? "Invalid verification code.");
      setDigits(["", "", "", ""]);
      inputRefs[0].current?.focus();
    } finally {
      setIsLoading(false);
    }
  };

  const handleResend = async () => {
    if (resendCooldown > 0 || isResending) return;
    setIsResending(true);
    try {
      await api.post("/send-reset-code", { email: email.trim() });
      toast.success("Reset code resent.");
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

  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password.length < 6) {
      toast.error("Password must be at least 6 characters.");
      return;
    }
    if (password !== passwordConfirm) {
      toast.error("Passwords do not match.");
      return;
    }
    setIsLoading(true);
    try {
      await api.post("/reset-password", {
        email: email.trim(),
        code,
        password,
        password_confirmation: passwordConfirm,
      });
      toast.success("Password reset successfully. Please log in.");
      setTimeout(() => router.push("/login"), 800);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = axiosErr?.response?.data;
      const msg = data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? "Failed to reset password.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-3xl shadow-xl p-8 sm:p-10">
          <div className="flex flex-col items-center mb-8">
            <img src="/logo.png" alt="MediSasa" className="w-16 h-16 rounded-2xl object-cover shadow-md mb-4" />
            <h1 className="text-2xl font-bold text-gray-900">MediSasa</h1>
          </div>

          <div className="text-center mb-6">
            <div className="w-16 h-16 rounded-full bg-brand-50 flex items-center justify-center mx-auto mb-4">
              <KeyRound className="w-8 h-8 text-brand-500" />
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {step === "email" && "Reset Your Password"}
              {step === "code" && "Enter Reset Code"}
              {step === "password" && "Choose a New Password"}
            </h2>
            <p className="text-gray-500 text-sm leading-relaxed">
              {step === "email" && "Enter your email and we'll send you a 4-digit code."}
              {step === "code" && (
                <>
                  Enter the <strong>4-digit code</strong> sent to:
                  <br />
                  <span className="text-brand-500 font-semibold text-sm bg-brand-50 px-3 py-1.5 rounded-xl inline-block mt-2">
                    {email}
                  </span>
                </>
              )}
              {step === "password" && "Pick a strong password you haven't used before."}
            </p>
          </div>

          {step === "email" && (
            <form onSubmit={handleEmailSubmit} noValidate className="space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  Email Address
                </label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    disabled={isLoading}
                    className="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none transition-all focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  "Send Reset Code"
                )}
              </button>
            </form>
          )}

          {step === "code" && (
            <>
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
                    disabled={isLoading}
                    className={`w-14 h-14 text-center text-2xl font-bold rounded-xl border-2 outline-none transition-all bg-gray-50
                      ${d ? "border-brand-500 bg-brand-50 text-brand-600" : "border-gray-200"}
                      focus:border-brand-400 focus:ring-2 focus:ring-brand-100 focus:bg-white
                      disabled:opacity-50`}
                  />
                ))}
              </div>

              <button
                onClick={handleCodeSubmit}
                disabled={isLoading || code.length !== 4}
                className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm mb-5"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Verifying...
                  </>
                ) : (
                  "Verify Code"
                )}
              </button>

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

              <button
                onClick={() => setStep("email")}
                className="mt-5 inline-flex items-center gap-1 text-xs text-gray-500 hover:text-gray-700 transition-colors"
              >
                <ArrowLeft className="w-3 h-3" />
                Use a different email
              </button>
            </>
          )}

          {step === "password" && (
            <form onSubmit={handlePasswordSubmit} noValidate className="space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  New Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="At least 6 characters"
                    disabled={isLoading}
                    className="w-full pl-10 pr-12 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none transition-all focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                  Confirm Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type={showConfirm ? "text" : "password"}
                    value={passwordConfirm}
                    onChange={(e) => setPasswordConfirm(e.target.value)}
                    placeholder="Repeat new password"
                    disabled={isLoading}
                    className="w-full pl-10 pr-12 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none transition-all focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm(!showConfirm)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    tabIndex={-1}
                  >
                    {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Resetting...
                  </>
                ) : (
                  "Reset Password"
                )}
              </button>
            </form>
          )}
        </div>

        <p className="text-center mt-6 text-sm text-gray-500">
          <Link href="/login" className="hover:text-brand-500 transition-colors">
            ← Back to Login
          </Link>
        </p>
      </div>
    </div>
  );
}
