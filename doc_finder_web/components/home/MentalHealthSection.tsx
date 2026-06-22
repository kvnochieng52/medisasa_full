"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Brain, Globe, Lock, Play, FileText,
  ChevronRight, Heart, Loader2, Activity, ArrowRight, Sparkles,
} from "lucide-react";
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
  slug: string;
  questions_count: number;
}

const SURVEY_META: Record<string, { gradient: string; tag: string; icon: React.ReactNode }> = {
  "phq-2":  { gradient: "from-violet-500 to-purple-600", tag: "Depression", icon: <Brain className="w-4 h-4 text-white" /> },
  "gad-7":  { gradient: "from-orange-400 to-red-500",   tag: "Anxiety",    icon: <Activity className="w-4 h-4 text-white" /> },
  "pss-10": { gradient: "from-brand-500 to-brand-700",  tag: "Stress",     icon: <Heart className="w-4 h-4 text-white" /> },
};
const DEFAULT_META = { gradient: "from-gray-500 to-gray-600", tag: "Screening", icon: <Brain className="w-4 h-4 text-white" /> };

function ResourceCard({ m }: { m: Material }) {
  const img  = getImageUrl(m.image_path);
  const Icon = m.file_type === "video" ? Play : FileText;

  return (
    <Link
      href={`/mental-health/${m.id}`}
      className="bg-white border border-brand-100 rounded-2xl overflow-hidden hover:bg-brand-50 hover:border-brand-200 transition-all duration-200 group flex flex-col shadow-sm"
    >
      {/* Thumbnail */}
      <div className="relative h-36 bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0">
        {img
          ? <img src={img} alt={m.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
          : <Brain className="w-10 h-10 text-brand-200" />}

        {/* Badge */}
        <div className={`absolute top-2 right-2 flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full ${
          m.is_free ? "bg-green-500 text-white" : "bg-brand-50 text-brand-700"
        }`}>
          {m.is_free ? <Globe className="w-2.5 h-2.5" /> : <Lock className="w-2.5 h-2.5" />}
          {m.is_free ? "Free" : m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
        </div>

        {/* File type pill */}
        {m.file_type && (
          <div className="absolute bottom-2 left-2 bg-black/50 text-white text-xs font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
            <Icon className="w-2.5 h-2.5" />
            {m.file_type === "video" ? "Video" : "PDF"}
          </div>
        )}
      </div>

      {/* Body */}
      <div className="p-3 flex flex-col flex-1">
        <h3 className="text-sm font-bold text-gray-900 line-clamp-2 leading-snug mb-1">{m.title}</h3>
        {m.description && (
          <p className="text-xs text-gray-500 line-clamp-2 flex-1">{m.description}</p>
        )}
        <p className="text-xs font-semibold text-brand-600 mt-2 flex items-center gap-1 group-hover:text-brand-700 transition-colors">
          View resource <ChevronRight className="w-3 h-3" />
        </p>
      </div>
    </Link>
  );
}

export default function MentalHealthSection() {
  const [materials, setMaterials] = useState<Material[]>([]);
  const [surveys, setSurveys]     = useState<Survey[]>([]);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    Promise.all([
      api.get("/mental-health-materials").then(res => Array.isArray(res.data?.data) ? res.data.data : []).catch(() => []),
      api.get("/surveys").then(res => Array.isArray(res.data?.data) ? res.data.data : []).catch(() => []),
    ]).then(([mats, survs]) => {
      setMaterials(mats.slice(0, 6));
      setSurveys(survs);
    }).finally(() => setLoading(false));
  }, []);

  return (
    <section className="py-14 bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white overflow-hidden relative">
      {/* Decorative blobs */}
      <div className="absolute -top-20 -right-20 w-72 h-72 rounded-full bg-brand-200 opacity-20 pointer-events-none" />
      <div className="absolute -bottom-16 -left-16 w-56 h-56 rounded-full bg-brand-100 opacity-30 pointer-events-none" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Section header */}
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-8">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <div className="p-1.5 rounded-lg bg-brand-100">
                <Heart className="w-4 h-4 text-brand-600" />
              </div>
              <span className="text-sm font-semibold text-brand-600 uppercase tracking-wide">
                Mental Health
              </span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-bold leading-tight text-gray-900">
              Your Mental Wellbeing, Supported
            </h2>
            <p className="text-gray-500 text-sm mt-1 max-w-lg">
              Free screening tools, expert-curated resources, and guides to support your mental health journey.
            </p>
          </div>
          <Link
            href="/mental-health"
            className="inline-flex items-center gap-2 bg-brand-600 text-white font-bold text-sm px-4 py-2.5 rounded-xl hover:bg-brand-700 transition-colors shadow-sm flex-shrink-0"
          >
            View All <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* ── Screening tools strip ── */}
        {surveys.length > 0 && (
          <div className="bg-gradient-to-r from-brand-700 via-brand-800 to-brand-900 rounded-2xl p-5 mb-8 shadow-md">
            <div className="flex items-center gap-2 mb-3">
              <Sparkles className="w-4 h-4 text-brand-200" />
              <span className="text-brand-200 text-xs font-bold uppercase tracking-widest">Free Screening Tools</span>
            </div>
            <p className="text-white font-bold text-base sm:text-lg mb-1">
              Not sure how you&apos;re feeling? Take a free check-in.
            </p>
            <p className="text-brand-200 text-sm mb-5">
              Our evidence-based screenings take under 3 minutes. Select one to start and get personalised resources.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {surveys.map(s => {
                const meta = SURVEY_META[s.slug] ?? DEFAULT_META;
                return (
                  <Link
                    key={s.id}
                    href={`/surveys/${s.id}`}
                    className="flex items-center gap-3 bg-white/10 hover:bg-white/20 border border-white/15 hover:border-white/40 rounded-xl p-3.5 transition-all group"
                  >
                    <div className={`w-9 h-9 rounded-lg bg-gradient-to-br ${meta.gradient} flex items-center justify-center flex-shrink-0`}>
                      {meta.icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[10px] font-bold text-brand-200 uppercase tracking-wide">{meta.tag}</p>
                      <p className="text-sm font-bold text-white line-clamp-1 group-hover:text-brand-100 transition-colors">{s.title}</p>
                      <p className="text-[11px] text-brand-300">{s.questions_count} question{s.questions_count !== 1 ? "s" : ""} · Free</p>
                    </div>
                    <ArrowRight className="w-4 h-4 text-brand-300 group-hover:text-white group-hover:translate-x-0.5 transition-all flex-shrink-0" />
                  </Link>
                );
              })}
              <Link
                href="/surveys"
                className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-dashed border-white/20 hover:border-white/40 rounded-xl p-3.5 transition-all text-brand-200 hover:text-white text-sm font-semibold"
              >
                View all screenings <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        )}

        {/* Resource grid */}
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-gray-800 text-base flex items-center gap-2">
            <Brain className="w-4 h-4 text-brand-500" /> Resources for Your Wellbeing
          </h3>
          <Link href="/mental-health" className="text-xs font-semibold text-brand-600 hover:text-brand-700 flex items-center gap-1">
            Browse all <ChevronRight className="w-3.5 h-3.5" />
          </Link>
        </div>
        {loading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-brand-400" />
          </div>
        ) : materials.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-2xl border border-brand-100">
            <Brain className="w-10 h-10 text-brand-200 mx-auto mb-3" />
            <p className="text-gray-600 text-sm font-semibold">Resources coming soon</p>
            <p className="text-gray-400 text-xs mt-1">Check back shortly — our team is uploading materials.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {materials.map(m => <ResourceCard key={m.id} m={m} />)}
          </div>
        )}
      </div>
    </section>
  );
}
