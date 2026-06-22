"use client";

import { useEffect, useState } from "react";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import { Brain, Heart, Activity, ChevronRight, Loader2, BookOpen, Globe, Lock, Play, FileText } from "lucide-react";
import api, { getImageUrl } from "@/lib/api";

interface Material {
  id: number;
  title: string;
  description?: string;
  image_path?: string;
  file_type?: "pdf" | "video";
  is_free: boolean;
  price?: number | null;
}

interface Survey {
  id: number;
  title: string;
  description?: string;
  slug: string;
  questions_count: number;
}

const SURVEY_META: Record<string, { icon: React.ReactNode; gradient: string; tag: string }> = {
  "phq-2": {
    icon: <Brain className="w-6 h-6 text-white" />,
    gradient: "from-violet-500 to-purple-600",
    tag: "Depression",
  },
  "gad-7": {
    icon: <Activity className="w-6 h-6 text-white" />,
    gradient: "from-orange-400 to-red-500",
    tag: "Anxiety",
  },
  "pss-10": {
    icon: <Heart className="w-6 h-6 text-white" />,
    gradient: "from-brand-500 to-brand-700",
    tag: "Stress",
  },
};

const DEFAULT_META = {
  icon: <Brain className="w-6 h-6 text-white" />,
  gradient: "from-gray-500 to-gray-700",
  tag: "Screening",
};

export default function SurveysPage() {
  const [surveys, setSurveys]     = useState<Survey[]>([]);
  const [materials, setMaterials] = useState<Material[]>([]);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    Promise.all([
      api.get("/surveys").then(res => Array.isArray(res.data?.data) ? res.data.data : []).catch(() => []),
      api.get("/mental-health-materials").then(res => Array.isArray(res.data?.data) ? res.data.data : []).catch(() => []),
    ]).then(([s, m]) => {
      setSurveys(s);
      setMaterials(m.slice(0, 6));
    }).finally(() => setLoading(false));
  }, []);

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white">
      <Navbar />

      <div className="max-w-3xl mx-auto px-4 pt-28 pb-16">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-brand-500 to-brand-700 shadow-md mb-4">
            <Brain className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Mental Health Screenings</h1>
          <p className="text-gray-500 text-sm max-w-md mx-auto">
            Take a quick evidence-based screening to understand your current mental wellbeing and get personalised resources.
          </p>
        </div>

        {loading ? (
          <div className="flex justify-center py-16">
            <Loader2 className="w-8 h-8 animate-spin text-brand-400" />
          </div>
        ) : surveys.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-brand-100">
            <Brain className="w-10 h-10 text-brand-200 mx-auto mb-3" />
            <p className="text-gray-600 font-semibold">No screenings available yet</p>
          </div>
        ) : (
          <div className="space-y-4">
            {surveys.map(survey => {
              const meta = SURVEY_META[survey.slug] ?? DEFAULT_META;
              return (
                <Link
                  key={survey.id}
                  href={`/surveys/${survey.id}`}
                  className="flex items-center gap-5 bg-white rounded-2xl shadow-sm border border-gray-100 p-5 hover:shadow-md hover:border-brand-200 transition-all group"
                >
                  <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${meta.gradient} flex items-center justify-center flex-shrink-0`}>
                    {meta.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="text-xs font-bold uppercase tracking-wide text-gray-400">{meta.tag}</span>
                      <span className="text-xs text-gray-300">·</span>
                      <span className="text-xs text-gray-400">{survey.questions_count} question{survey.questions_count !== 1 ? "s" : ""}</span>
                    </div>
                    <h2 className="font-bold text-gray-900 text-base leading-snug group-hover:text-brand-700 transition-colors">
                      {survey.title}
                    </h2>
                    {survey.description && (
                      <p className="text-xs text-gray-500 mt-0.5 line-clamp-1">{survey.description}</p>
                    )}
                  </div>
                  <ChevronRight className="w-5 h-5 text-gray-300 group-hover:text-brand-500 flex-shrink-0 transition-colors" />
                </Link>
              );
            })}
          </div>
        )}

        <p className="text-center text-xs text-gray-400 mt-8 mb-12">
          These are screening tools, not clinical diagnoses. Always consult a healthcare professional for medical advice.
        </p>

        {/* ── Resources section ── */}
        {materials.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                  <BookOpen className="w-5 h-5 text-brand-500" /> Mental Health Resources
                </h2>
                <p className="text-sm text-gray-500 mt-0.5">
                  Guides, videos and tools curated to support your wellbeing journey.
                </p>
              </div>
              <Link
                href="/mental-health"
                className="text-sm font-semibold text-brand-600 hover:text-brand-700 flex items-center gap-1 flex-shrink-0"
              >
                View all <ChevronRight className="w-4 h-4" />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {materials.map(m => {
                const img  = getImageUrl(m.image_path);
                const Icon = m.file_type === "video" ? Play : FileText;
                return (
                  <Link
                    key={m.id}
                    href={`/mental-health/${m.id}`}
                    className="bg-white border border-gray-100 rounded-2xl overflow-hidden hover:shadow-md hover:border-brand-200 transition-all group flex flex-col shadow-sm"
                  >
                    <div className="relative h-36 bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0">
                      {img
                        ? <img src={img} alt={m.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                        : <Brain className="w-10 h-10 text-brand-200" />}
                      <div className={`absolute top-2 right-2 flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full ${
                        m.is_free ? "bg-green-500 text-white" : "bg-brand-600 text-white"
                      }`}>
                        {m.is_free ? <Globe className="w-2.5 h-2.5" /> : <Lock className="w-2.5 h-2.5" />}
                        {m.is_free ? "Free" : m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
                      </div>
                      {m.file_type && (
                        <div className="absolute bottom-2 left-2 bg-black/50 text-white text-xs font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
                          <Icon className="w-2.5 h-2.5" />
                          {m.file_type === "video" ? "Video" : "PDF"}
                        </div>
                      )}
                    </div>
                    <div className="p-3">
                      <h3 className="text-sm font-bold text-gray-900 line-clamp-2 leading-snug mb-1 group-hover:text-brand-700 transition-colors">{m.title}</h3>
                      {m.description && (
                        <p className="text-xs text-gray-500 line-clamp-2">{m.description}</p>
                      )}
                    </div>
                  </Link>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
