"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Brain, Heart, Activity, ChevronRight, ArrowLeft,
  CheckCircle2, Loader2, BookOpen, Calendar, Lock, Globe,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";

// ── Types ─────────────────────────────────────────────────────────────────────

interface SurveyOption {
  id: number;
  label: string;
  score_value: number;
  color: string;
  order_index: number;
}

interface SurveyQuestion {
  id: number;
  question_text: string;
  hint?: string;
  order_index: number;
  options: SurveyOption[];
}

interface Survey {
  id: number;
  title: string;
  description?: string;
  instructions?: string;
  slug: string;
  questions: SurveyQuestion[];
}

interface ResultMaterial {
  id: number;
  title: string;
  file_type?: string;
  is_free: boolean;
  price?: number | null;
  image_path?: string;
}

interface ResultBand {
  id: number;
  label: string;
  message: string;
  result_type: "low" | "moderate" | "high";
  show_therapist_cta: boolean;
  materials: ResultMaterial[];
}

interface SubmitResult {
  response_id: number;
  total_score: number;
  band: ResultBand | null;
}

// ── Colour helpers ────────────────────────────────────────────────────────────

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
function colorClass(color: string, selected: boolean) {
  return selected ? (SELECTED_MAP[color] ?? SELECTED_MAP.green) : (COLOR_MAP[color] ?? COLOR_MAP.green);
}

// ── Result card ────────────────────────────────────────────────────────────────

function ResultBandIcon({ type }: { type: string }) {
  if (type === "high")     return <Heart className="w-10 h-10 text-white" />;
  if (type === "moderate") return <Activity className="w-10 h-10 text-white" />;
  return <CheckCircle2 className="w-10 h-10 text-white" />;
}
function bandGradient(type: string) {
  if (type === "high")     return "from-red-500 to-rose-600";
  if (type === "moderate") return "from-orange-400 to-amber-500";
  return "from-green-400 to-emerald-500";
}
function bandScoreBg(type: string) {
  if (type === "high")     return "bg-red-100 text-red-700";
  if (type === "moderate") return "bg-orange-100 text-orange-700";
  return "bg-green-100 text-green-700";
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default function TakeSurveyPage() {
  const { id } = useParams<{ id: string }>();
  const router  = useRouter();

  const [survey, setSurvey]   = useState<Survey | null>(null);
  const [loading, setLoading] = useState(true);
  const [step, setStep]       = useState<"intro" | "question" | "submitting" | "result">("intro");
  const [qIndex, setQIndex]   = useState(0);
  const [answers, setAnswers] = useState<Record<number, number>>({}); // question_id → score_value
  const [result, setResult]   = useState<SubmitResult | null>(null);

  useEffect(() => {
    api.get(`/surveys/${id}`)
      .then(res => setSurvey(res.data?.data ?? null))
      .catch(() => { toast.error("Survey not found"); router.push("/surveys"); })
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <main className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white">
        <Navbar />
        <div className="flex justify-center pt-40">
          <Loader2 className="w-8 h-8 animate-spin text-brand-400" />
        </div>
      </main>
    );
  }

  if (!survey) return null;

  const questions  = survey.questions;
  const totalQ     = questions.length;
  const progress   = step === "intro" ? 0 : step === "question" ? Math.round(((qIndex) / totalQ) * 100) : 100;
  const currentQ   = questions[qIndex];

  const selectAnswer = (questionId: number, value: number) => {
    setAnswers(a => ({ ...a, [questionId]: value }));
  };

  const handleNext = async () => {
    if (answers[currentQ.id] === undefined) {
      toast.error("Please select an answer to continue.");
      return;
    }
    if (qIndex < totalQ - 1) {
      setQIndex(i => i + 1);
      return;
    }
    // Last question — submit
    setStep("submitting");
    try {
      const res = await api.post<{ success: boolean; data: SubmitResult }>(
        `/surveys/${survey.id}/respond`,
        { answers }
      );
      setResult(res.data.data);
      setStep("result");
    } catch {
      toast.error("Something went wrong. Please try again.");
      setStep("question");
    }
  };

  const handleBack = () => {
    if (qIndex === 0) { setStep("intro"); return; }
    setQIndex(i => i - 1);
  };

  const reset = () => {
    setStep("intro");
    setQIndex(0);
    setAnswers({});
    setResult(null);
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white">
      <Navbar />

      <div className="max-w-2xl mx-auto px-4 pt-28 pb-16">

        {/* ── INTRO ── */}
        {step === "intro" && (
          <div className="text-center">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-brand-500 to-brand-700 flex items-center justify-center mx-auto mb-6 shadow-lg">
              <Brain className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">{survey.title}</h1>
            {survey.description && (
              <p className="text-gray-500 text-sm mb-3 max-w-md mx-auto">{survey.description}</p>
            )}
            {survey.instructions && (
              <p className="text-xs text-gray-400 mb-6 max-w-md mx-auto leading-relaxed italic">
                {survey.instructions}
              </p>
            )}

            <div className="grid grid-cols-3 gap-4 mb-8 text-center">
              {[
                { icon: "🕐", label: `${totalQ} question${totalQ !== 1 ? "s" : ""}` },
                { icon: "🔒", label: "Confidential" },
                { icon: "💙", label: "Non-judgmental" },
              ].map(({ icon, label }) => (
                <div key={label} className="bg-white rounded-2xl p-4 shadow-sm border border-brand-100">
                  <p className="text-2xl mb-1">{icon}</p>
                  <p className="text-xs font-semibold text-gray-600">{label}</p>
                </div>
              ))}
            </div>

            <button
              onClick={() => setStep("question")}
              className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-brand-500 to-brand-700 hover:from-brand-600 hover:to-brand-800 text-white font-bold text-base rounded-2xl transition-all shadow-md hover:shadow-lg active:scale-[0.98]"
            >
              Start Check-In <ChevronRight className="w-5 h-5" />
            </button>
            <p className="text-xs text-gray-400 mt-4">
              Screening tool only — not a clinical diagnosis. Consult a professional for medical advice.
            </p>
          </div>
        )}

        {/* ── QUESTION ── */}
        {step === "question" && currentQ && (
          <div>
            <div className="mb-8">
              <div className="flex items-center justify-between text-sm text-gray-500 mb-2">
                <span>Question {qIndex + 1} of {totalQ}</span>
                <span className="font-semibold text-brand-600">{Math.round(((qIndex + 1) / totalQ) * 100)}%</span>
              </div>
              <div className="h-2 bg-brand-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-brand-400 to-brand-600 rounded-full transition-all duration-500"
                  style={{ width: `${Math.round(((qIndex + 1) / totalQ) * 100)}%` }}
                />
              </div>
            </div>

            <div className="bg-white rounded-3xl shadow-sm border border-brand-100 p-7">
              {survey.instructions && (
                <p className="text-xs font-bold text-brand-500 uppercase tracking-widest mb-3">
                  {survey.instructions}
                </p>
              )}
              <h2 className="text-xl font-bold text-gray-900 mb-2">{currentQ.question_text}</h2>
              {currentQ.hint && (
                <p className="text-sm text-gray-400 mb-6 italic">{currentQ.hint}</p>
              )}

              <div className="space-y-3">
                {currentQ.options.map(opt => {
                  const selected = answers[currentQ.id] === opt.score_value &&
                    /* handle same score_value across options by tracking option id */
                    answers[currentQ.id] !== undefined;
                  // Use option id to track selection precisely
                  const isSelected = answers[currentQ.id] === opt.score_value;
                  return (
                    <button
                      key={opt.id}
                      onClick={() => selectAnswer(currentQ.id, opt.score_value)}
                      className={`w-full flex items-center gap-4 px-5 py-4 rounded-2xl border-2 text-left transition-all font-semibold ${
                        colorClass(opt.color, isSelected)
                      }`}
                    >
                      <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                        isSelected ? "border-white bg-white/30" : "border-current"
                      }`}>
                        {isSelected && <div className="w-3 h-3 rounded-full bg-white" />}
                      </div>
                      <span className="text-sm">{opt.label}</span>
                    </button>
                  );
                })}
              </div>

              <div className="flex items-center justify-between mt-6">
                <button
                  onClick={handleBack}
                  className="flex items-center gap-1.5 text-sm text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <ArrowLeft className="w-4 h-4" /> Back
                </button>
                <button
                  onClick={handleNext}
                  disabled={answers[currentQ.id] === undefined}
                  className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-brand-500 to-brand-700 hover:from-brand-600 hover:to-brand-800 disabled:from-gray-300 disabled:to-gray-300 disabled:cursor-not-allowed text-white font-bold text-sm rounded-xl transition-all shadow-sm"
                >
                  {qIndex === totalQ - 1 ? "See Results" : "Next"} <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── SUBMITTING ── */}
        {step === "submitting" && (
          <div className="text-center py-16">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-brand-500 to-brand-700 flex items-center justify-center mx-auto mb-6 shadow-lg animate-pulse">
              <Brain className="w-10 h-10 text-white" />
            </div>
            <Loader2 className="w-8 h-8 animate-spin text-brand-500 mx-auto mb-4" />
            <p className="font-bold text-gray-700">Analysing your responses…</p>
            <p className="text-sm text-gray-400 mt-1">This only takes a moment</p>
          </div>
        )}

        {/* ── RESULT ── */}
        {step === "result" && result && (
          <ResultScreen result={result} survey={survey} onReset={reset} />
        )}
      </div>
    </main>
  );
}

// ── Result screen (extracted for clarity) ────────────────────────────────────

function ResultScreen({
  result,
  survey,
  onReset,
}: {
  result: SubmitResult;
  survey: Survey;
  onReset: () => void;
}) {
  const band = result.band;
  const type = band?.result_type ?? "low";
  const maxScore = survey.questions.reduce((acc, q) => {
    const max = Math.max(...q.options.map(o => o.score_value));
    return acc + max;
  }, 0);

  const [surveyMaterials, setSurveyMaterials] = useState<ResultMaterial[]>([]);

  useEffect(() => {
    api.get(`/surveys/${survey.id}/materials`)
      .then(res => setSurveyMaterials(res.data?.data ?? []))
      .catch(() => {});
  }, [survey.id]);

  const bandMaterialIds = new Set((band?.materials ?? []).map(m => m.id));
  const extraMaterials = surveyMaterials.filter(m => !bandMaterialIds.has(m.id));
  const hasAnyMaterials = (band && band.materials.length > 0) || extraMaterials.length > 0;

  return (
    <div>
      {/* Score header */}
      <div className="text-center mb-8">
        <div className={`w-20 h-20 rounded-3xl bg-gradient-to-br ${bandGradient(type)} flex items-center justify-center mx-auto mb-5 shadow-lg`}>
          <ResultBandIcon type={type} />
        </div>
        <div className={`inline-flex items-center gap-2 font-bold text-sm px-4 py-1.5 rounded-full mb-4 ${bandScoreBg(type)}`}>
          Score: {result.total_score} / {maxScore}
          {band && ` — ${band.label}`}
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-3">
          {type === "high" ? "You Deserve Support" : type === "moderate" ? "Consider Some Support" : "You're Doing Well"}
        </h2>
        {band?.message && (
          <p className="text-gray-600 text-sm leading-relaxed max-w-lg mx-auto">{band.message}</p>
        )}
      </div>

      {/* Therapist CTA */}
      {band?.show_therapist_cta && (
        <div className="bg-gradient-to-r from-brand-600 to-brand-700 rounded-3xl p-6 text-white mb-4">
          <h3 className="font-bold text-lg mb-2 flex items-center gap-2">
            <Calendar className="w-5 h-5" /> Book a Session with a Therapist
          </h3>
          <p className="text-brand-100 text-sm mb-5 leading-relaxed">
            A specialist can provide expert assessment and personalised support.
          </p>
          <Link
            href="/doctors?q=therapist"
            className="inline-flex items-center gap-2 bg-white text-brand-700 font-bold text-sm px-5 py-3 rounded-xl hover:bg-brand-50 transition-colors shadow-sm"
          >
            <Calendar className="w-4 h-4" /> Book Session Now
          </Link>
        </div>
      )}

      {/* Band-specific materials */}
      {band && band.materials.length > 0 && (
        <MaterialList title="Recommended for Your Result" materials={band.materials} />
      )}

      {/* Survey-level materials (linked to this questionnaire) */}
      {extraMaterials.length > 0 && (
        <MaterialList title="Resources for This Screening" materials={extraMaterials} />
      )}

      {/* Fallback — no materials at all */}
      {!hasAnyMaterials && (
        <div className="bg-white rounded-3xl shadow-sm border border-brand-100 p-6 mb-4">
          <h3 className="font-bold text-gray-900 mb-2 flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-brand-500" /> Browse Mental Health Resources
          </h3>
          <Link
            href={type === "low" ? "/mental-health?type=free" : "/mental-health"}
            className="w-full flex items-center justify-center gap-2 py-3.5 bg-gradient-to-r from-brand-500 to-brand-700 hover:from-brand-600 hover:to-brand-800 text-white font-bold text-sm rounded-xl transition-all shadow-sm mt-3"
          >
            <BookOpen className="w-4 h-4" /> View Resources
          </Link>
        </div>
      )}

      <div className="flex flex-col sm:flex-row gap-3 mt-2">
        <button
          onClick={onReset}
          className="flex-1 py-3 rounded-xl border border-brand-200 text-brand-600 font-semibold text-sm hover:bg-brand-50 transition-colors"
        >
          Take Again
        </button>
        <Link
          href="/surveys"
          className="flex-1 py-3 rounded-xl bg-brand-600 text-white font-bold text-sm text-center hover:bg-brand-700 transition-colors"
        >
          Other Screenings
        </Link>
      </div>
    </div>
  );
}

// ── Reusable material list ────────────────────────────────────────────────────

function MaterialList({ title, materials }: { title: string; materials: ResultMaterial[] }) {
  return (
    <div className="bg-white rounded-3xl shadow-sm border border-brand-100 p-6 mb-4">
      <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
        <BookOpen className="w-5 h-5 text-brand-500" /> {title}
      </h3>
      <div className="space-y-3">
        {materials.map(m => (
          <Link
            key={m.id}
            href={`/mental-health/${m.id}`}
            className="flex items-center gap-3 p-3 rounded-xl border border-gray-100 hover:border-brand-200 hover:bg-brand-50 transition-all group"
          >
            {m.image_path ? (
              <img src={getImageUrl(m.image_path) ?? ""} alt={m.title} className="w-10 h-10 rounded-lg object-cover flex-shrink-0" />
            ) : (
              <div className="w-10 h-10 rounded-lg bg-brand-100 flex items-center justify-center flex-shrink-0">
                <BookOpen className="w-5 h-5 text-brand-400" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 line-clamp-1 group-hover:text-brand-700 transition-colors">{m.title}</p>
              <div className="flex items-center gap-1 mt-0.5">
                {m.is_free ? (
                  <span className="text-xs text-green-600 font-semibold flex items-center gap-0.5">
                    <Globe className="w-3 h-3" /> Free
                  </span>
                ) : (
                  <span className="text-xs text-brand-600 font-semibold flex items-center gap-0.5">
                    <Lock className="w-3 h-3" />
                    {m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
                  </span>
                )}
                {m.file_type && (
                  <span className="text-xs text-gray-400 ml-1 capitalize">{m.file_type}</span>
                )}
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-brand-500 transition-colors flex-shrink-0" />
          </Link>
        ))}
      </div>
    </div>
  );
}
