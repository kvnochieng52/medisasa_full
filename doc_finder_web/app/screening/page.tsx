"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Brain, Heart, ChevronRight, CheckCircle2,
  Loader2, ArrowLeft, BookOpen, Calendar,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

const QUESTIONS = [
  {
    id: "q1",
    text: "Lost interest in things you used to enjoy?",
    hint: "Think about hobbies, activities, or time with people you care about.",
  },
  {
    id: "q2",
    text: "Felt sad or like things will never get better?",
    hint: "Consider your overall mood and outlook over the last two weeks.",
  },
];

const OPTIONS = [
  { label: "Not at all",           value: 0, color: "green"  },
  { label: "Several days",         value: 1, color: "yellow" },
  { label: "More than half the days", value: 2, color: "orange" },
  { label: "Nearly every day",     value: 3, color: "red"    },
];

const COLOR_MAP: Record<string, string> = {
  green:  "border-green-300 bg-green-50 text-green-800 hover:border-green-400 hover:bg-green-100",
  yellow: "border-yellow-300 bg-yellow-50 text-yellow-800 hover:border-yellow-400 hover:bg-yellow-100",
  orange: "border-orange-300 bg-orange-50 text-orange-800 hover:border-orange-400 hover:bg-orange-100",
  red:    "border-red-300 bg-red-50 text-red-800 hover:border-red-400 hover:bg-red-100",
};
const SELECTED_MAP: Record<string, string> = {
  green:  "border-green-500 bg-green-500 text-white",
  yellow: "border-yellow-500 bg-yellow-500 text-white",
  orange: "border-orange-500 bg-orange-500 text-white",
  red:    "border-red-500 bg-red-500 text-white",
};

type Step = "intro" | "q1" | "q2" | "submitting" | "result";

interface Result {
  total_score: number;
  result_type: "low" | "high";
  message: string;
}

export default function ScreeningPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>("intro");
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [result, setResult] = useState<Result | null>(null);

  const selectAnswer = (questionId: string, value: number) => {
    setAnswers(a => ({ ...a, [questionId]: value }));
  };

  const handleNext = async (currentStep: "q1" | "q2") => {
    if (answers[currentStep] === undefined) {
      toast.error("Please select an answer to continue.");
      return;
    }
    if (currentStep === "q1") { setStep("q2"); return; }

    // q2 done → submit
    setStep("submitting");
    try {
      const res = await api.post<{ success: boolean; data: Result }>("/depression-screenings", {
        q1_score: answers.q1,
        q2_score: answers.q2,
        answers: [
          { question: QUESTIONS[0].text, answer: OPTIONS.find(o => o.value === answers.q1)?.label, score: answers.q1 },
          { question: QUESTIONS[1].text, answer: OPTIONS.find(o => o.value === answers.q2)?.label, score: answers.q2 },
        ],
      });
      setResult(res.data.data);
      setStep("result");
    } catch {
      toast.error("Something went wrong. Please try again.");
      setStep("q2");
    }
  };

  const questionIndex = step === "q1" ? 0 : step === "q2" ? 1 : -1;
  const currentQuestion = questionIndex >= 0 ? QUESTIONS[questionIndex] : null;
  const progress = step === "intro" ? 0 : step === "q1" ? 50 : step === "q2" ? 100 : 100;

  return (
    <main className="min-h-screen bg-gradient-to-br from-violet-50 via-purple-50 to-pink-50">
      <Navbar />

      <div className="max-w-2xl mx-auto px-4 pt-28 pb-16">

        {/* ── INTRO ── */}
        {step === "intro" && (
          <div className="text-center">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center mx-auto mb-6 shadow-lg">
              <Brain className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-3">Mental Health Check-In</h1>
            <p className="text-gray-500 text-base mb-2">PHQ-2 Depression Screening Tool</p>
            <p className="text-sm text-gray-400 mb-8 max-w-md mx-auto leading-relaxed">
              This quick 2-question check-in takes under a minute. It helps us understand how you&apos;ve been feeling over the <strong>last 2 weeks</strong> and connect you with the right support.
            </p>

            <div className="grid grid-cols-3 gap-4 mb-8 text-center">
              {[
                { icon: "🕐", label: "< 1 minute" },
                { icon: "🔒", label: "Confidential" },
                { icon: "💙", label: "Non-judgmental" },
              ].map(({ icon, label }) => (
                <div key={label} className="bg-white rounded-2xl p-4 shadow-sm border border-purple-100">
                  <p className="text-2xl mb-1">{icon}</p>
                  <p className="text-xs font-semibold text-gray-600">{label}</p>
                </div>
              ))}
            </div>

            <button
              onClick={() => setStep("q1")}
              className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 text-white font-bold text-base rounded-2xl transition-all shadow-md hover:shadow-lg active:scale-[0.98]"
            >
              Start Check-In <ChevronRight className="w-5 h-5" />
            </button>

            <p className="text-xs text-gray-400 mt-4">
              This is a screening tool, not a diagnosis. Always consult a healthcare professional for medical advice.
            </p>
          </div>
        )}

        {/* ── QUESTION ── */}
        {(step === "q1" || step === "q2") && currentQuestion && (
          <div>
            {/* Progress */}
            <div className="mb-8">
              <div className="flex items-center justify-between text-sm text-gray-500 mb-2">
                <span>Question {questionIndex + 1} of {QUESTIONS.length}</span>
                <span className="font-semibold text-purple-600">{progress}%</span>
              </div>
              <div className="h-2 bg-purple-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-violet-500 to-purple-600 rounded-full transition-all duration-500"
                  style={{ width: `${progress}%` }}
                />
              </div>
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-purple-100 p-7">
              <p className="text-xs font-bold text-purple-500 uppercase tracking-widest mb-3">
                Over the last 2 weeks, how often have you been bothered by…
              </p>
              <h2 className="text-xl font-bold text-gray-900 mb-2">{currentQuestion.text}</h2>
              <p className="text-sm text-gray-400 mb-6 italic">{currentQuestion.hint}</p>

              <div className="space-y-3">
                {OPTIONS.map(opt => {
                  const selected = answers[step] === opt.value;
                  return (
                    <button
                      key={opt.value}
                      onClick={() => selectAnswer(step, opt.value)}
                      className={`w-full flex items-center gap-4 px-5 py-4 rounded-2xl border-2 text-left transition-all font-semibold ${
                        selected ? SELECTED_MAP[opt.color] : COLOR_MAP[opt.color]
                      }`}
                    >
                      <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                        selected ? "border-white bg-white/30" : "border-current"
                      }`}>
                        {selected && <div className="w-3 h-3 rounded-full bg-white" />}
                      </div>
                      <span className="text-sm">{opt.label}</span>
                    </button>
                  );
                })}
              </div>

              <div className="flex items-center justify-between mt-6">
                <button
                  onClick={() => setStep(step === "q2" ? "q1" : "intro")}
                  className="flex items-center gap-1.5 text-sm text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <ArrowLeft className="w-4 h-4" /> Back
                </button>
                <button
                  onClick={() => handleNext(step)}
                  disabled={answers[step] === undefined}
                  className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed text-white font-bold text-sm rounded-xl transition-all shadow-sm"
                >
                  {step === "q2" ? "See Results" : "Next"} <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── SUBMITTING ── */}
        {step === "submitting" && (
          <div className="text-center py-16">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center mx-auto mb-6 shadow-lg animate-pulse">
              <Brain className="w-10 h-10 text-white" />
            </div>
            <Loader2 className="w-8 h-8 animate-spin text-purple-500 mx-auto mb-4" />
            <p className="font-bold text-gray-700">Analysing your responses…</p>
            <p className="text-sm text-gray-400 mt-1">This only takes a moment</p>
          </div>
        )}

        {/* ── RESULT ── */}
        {step === "result" && result && (
          <div>
            {result.result_type === "low" ? (
              /* ── LOW RISK ── */
              <div>
                <div className="text-center mb-8">
                  <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-green-400 to-emerald-500 flex items-center justify-center mx-auto mb-5 shadow-lg">
                    <CheckCircle2 className="w-10 h-10 text-white" />
                  </div>
                  <div className="inline-flex items-center gap-2 bg-green-100 text-green-700 font-bold text-sm px-4 py-1.5 rounded-full mb-4">
                    Score: {result.total_score} / 6 — Low Risk
                  </div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-3">You&apos;re Doing Well</h2>
                  <p className="text-gray-600 text-sm leading-relaxed max-w-lg mx-auto">{result.message}</p>
                </div>

                <div className="bg-white rounded-3xl shadow-sm border border-green-100 p-6 mb-5">
                  <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <BookOpen className="w-5 h-5 text-green-500" /> Free Coping Resources
                  </h3>
                  <p className="text-sm text-gray-500 mb-4">
                    Explore our free mental health materials to maintain and strengthen your wellbeing.
                  </p>
                  <Link href="/mental-health?type=free"
                    className="w-full flex items-center justify-center gap-2 py-3.5 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white font-bold text-sm rounded-xl transition-all shadow-sm">
                    <BookOpen className="w-4 h-4" /> Get Coping Tips
                  </Link>
                </div>

                <div className="text-center">
                  <button onClick={() => { setStep("intro"); setAnswers({}); setResult(null); }}
                    className="text-sm text-purple-500 hover:text-purple-700 font-semibold">
                    Take the check-in again
                  </button>
                </div>
              </div>
            ) : (
              /* ── HIGH RISK ── */
              <div>
                <div className="text-center mb-8">
                  <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-orange-400 to-red-500 flex items-center justify-center mx-auto mb-5 shadow-lg">
                    <Heart className="w-10 h-10 text-white" />
                  </div>
                  <div className="inline-flex items-center gap-2 bg-orange-100 text-orange-700 font-bold text-sm px-4 py-1.5 rounded-full mb-4">
                    Score: {result.total_score} / 6 — Further Assessment Recommended
                  </div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-3">You Deserve Support</h2>
                  <p className="text-gray-600 text-sm leading-relaxed max-w-lg mx-auto">{result.message}</p>
                </div>

                <div className="space-y-4">
                  <div className="bg-gradient-to-r from-purple-600 to-violet-600 rounded-3xl p-6 text-white">
                    <h3 className="font-bold text-lg mb-2 flex items-center gap-2">
                      <Calendar className="w-5 h-5" /> Book a Session with a Therapist
                    </h3>
                    <p className="text-purple-100 text-sm mb-5 leading-relaxed">
                      A specialist will provide expert assessment and personalised support to help you cope better.
                    </p>
                    <Link href="/doctors?q=therapist"
                      className="inline-flex items-center gap-2 bg-white text-purple-700 font-bold text-sm px-5 py-3 rounded-xl hover:bg-purple-50 transition-colors shadow-sm">
                      <Calendar className="w-4 h-4" /> Book Session Now
                    </Link>
                  </div>

                  <div className="bg-white rounded-3xl shadow-sm border border-purple-100 p-6">
                    <h3 className="font-bold text-gray-900 mb-2 flex items-center gap-2">
                      <BookOpen className="w-5 h-5 text-purple-500" /> Expert Resources
                    </h3>
                    <p className="text-sm text-gray-500 mb-4">
                      Access our specialist-curated mental health materials while you wait for your session.
                    </p>
                    <Link href="/mental-health?type=paid"
                      className="w-full flex items-center justify-center gap-2 py-3.5 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 text-white font-bold text-sm rounded-xl transition-all shadow-sm">
                      <BookOpen className="w-4 h-4" /> View Expert Materials
                    </Link>
                  </div>
                </div>

                <div className="text-center mt-5">
                  <button onClick={() => { setStep("intro"); setAnswers({}); setResult(null); }}
                    className="text-sm text-purple-500 hover:text-purple-700 font-semibold">
                    Take the check-in again
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
