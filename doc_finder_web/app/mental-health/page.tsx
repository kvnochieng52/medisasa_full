"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  BookOpen, Play, FileText, Lock, Globe, Heart,
  Loader2, Brain, ChevronRight, Search, X, ShoppingCart,
  Activity, Sparkles, ArrowRight,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";

interface Survey {
  id: number;
  title: string;
  description?: string;
  slug: string;
  questions_count: number;
}

const SURVEY_META: Record<string, { gradient: string; tag: string; icon: React.ReactNode }> = {
  "phq-2": { gradient: "from-violet-500 to-purple-600", tag: "Depression", icon: <Brain className="w-5 h-5 text-white" /> },
  "gad-7": { gradient: "from-orange-400 to-red-500",   tag: "Anxiety",    icon: <Activity className="w-5 h-5 text-white" /> },
  "pss-10": { gradient: "from-brand-500 to-brand-700",  tag: "Stress",     icon: <Heart className="w-5 h-5 text-white" /> },
};
const DEFAULT_SURVEY_META = { gradient: "from-gray-500 to-gray-600", tag: "Screening", icon: <Brain className="w-5 h-5 text-white" /> };

interface Material {
  id: number;
  title: string;
  description?: string;
  image_path?: string;
  file_path?: string;
  file_type?: "pdf" | "video";
  is_free: boolean;
  price?: number | null;
}

function MaterialCard({
  m,
  hasAccess,
  isLoggedIn,
  purchasing,
  onPurchase,
}: {
  m: Material;
  hasAccess: boolean;
  isLoggedIn: boolean;
  purchasing: boolean;
  onPurchase: (id: number) => void;
}) {
  const img  = getImageUrl(m.image_path);
  const Icon = m.file_type === "video" ? Play : FileText;
  const canAccess = m.is_free || hasAccess;

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow group flex flex-col">
      {/* Clickable thumbnail → detail page */}
      <Link href={`/mental-health/${m.id}`} className="relative h-40 bg-gradient-to-br from-brand-100 to-brand-50 flex items-center justify-center overflow-hidden">
        {img
          ? <img src={img} alt={m.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
          : <Brain className="w-12 h-12 text-brand-200" />}

        {/* Lock overlay for inaccessible paid content */}
        {!canAccess && (
          <div className="absolute inset-0 bg-brand-900/40 backdrop-blur-[2px] flex items-center justify-center">
            <div className="bg-white/90 rounded-2xl p-3 text-center shadow-lg">
              <Lock className="w-6 h-6 text-brand-600 mx-auto mb-1" />
              <p className="text-xs font-bold text-brand-700">
                {m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
              </p>
            </div>
          </div>
        )}

        <div className={`absolute top-3 right-3 flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full shadow-sm ${
          m.is_free ? "bg-green-500 text-white" : "bg-brand-600 text-white"
        }`}>
          {m.is_free ? <Globe className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
          {m.is_free ? "Free" : m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
        </div>

        {m.file_type && (
          <div className="absolute bottom-3 left-3 bg-black/60 text-white text-xs font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
            <Icon className="w-3 h-3" />
            {m.file_type === "video" ? "Video" : "PDF"}
          </div>
        )}
      </Link>

      <div className="p-4 flex flex-col flex-1">
        {/* Title links to detail page */}
        <Link href={`/mental-health/${m.id}`}>
          <h3 className="font-bold text-gray-900 text-sm leading-snug mb-1 line-clamp-2 hover:text-brand-700 transition-colors">{m.title}</h3>
        </Link>
        {m.description && (
          <p className="text-xs text-gray-500 line-clamp-2 mb-3 flex-1">{m.description}</p>
        )}

        <div className="mt-auto">
          {canAccess ? (
            m.file_path ? (
              <a
                href={getImageUrl(m.file_path) ?? "#"}
                target="_blank"
                rel="noreferrer"
                className={`flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-bold transition-colors ${
                  m.is_free
                    ? "bg-green-500 hover:bg-green-600 text-white"
                    : "bg-brand-600 hover:bg-brand-700 text-white"
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                {m.file_type === "video" ? "Watch Now" : "Read Now"}
              </a>
            ) : null
          ) : (
            <button
              onClick={() => onPurchase(m.id)}
              disabled={purchasing}
              className="w-full flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-bold bg-brand-600 hover:bg-brand-700 disabled:opacity-60 text-white transition-colors"
            >
              {purchasing
                ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                : <ShoppingCart className="w-3.5 h-3.5" />}
              {purchasing
                ? "Redirecting…"
                : isLoggedIn
                  ? `Buy — KES ${m.price != null ? Number(m.price).toLocaleString() : "–"}`
                  : "Login to Purchase"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden animate-pulse">
      <div className="h-40 bg-gray-200" />
      <div className="p-4 space-y-2">
        <div className="h-3 bg-gray-200 rounded w-3/4" />
        <div className="h-3 bg-gray-100 rounded w-full" />
        <div className="h-3 bg-gray-100 rounded w-1/2" />
        <div className="h-8 bg-gray-100 rounded mt-3" />
      </div>
    </div>
  );
}

function MentalHealthPageInner() {
  const searchParams = useSearchParams();
  const router       = useRouter();
  const initialType  = searchParams.get("type") ?? "all";

  const [materials, setMaterials]   = useState<Material[]>([]);
  const [loading, setLoading]       = useState(true);
  const [filter, setFilter]         = useState<"all" | "free" | "paid">(
    initialType === "free" ? "free" : initialType === "paid" ? "paid" : "all"
  );
  const [search, setSearch]         = useState("");
  const [purchasedIds, setPurchasedIds] = useState<number[]>([]);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [purchasingId, setPurchasingId] = useState<number | null>(null);
  const [surveys, setSurveys]       = useState<Survey[]>([]);

  useEffect(() => {
    api.get("/surveys")
      .then(res => setSurveys(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setSurveys([]));
  }, []);

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("auth_token") : null;
    setIsLoggedIn(!!token);
    if (token) {
      api.get<{ success: boolean; data: number[] }>("/mental-health-purchases/my")
        .then(res => setPurchasedIds(Array.isArray(res.data?.data) ? res.data.data : []))
        .catch(() => setPurchasedIds([]));
    }
  }, []);

  useEffect(() => {
    setLoading(true);
    const params = filter !== "all" ? { type: filter } : {};
    api.get("/mental-health-materials", { params })
      .then(res => setMaterials(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setMaterials([]))
      .finally(() => setLoading(false));
  }, [filter]);

  const handlePurchase = async (materialId: number) => {
    if (!isLoggedIn) {
      router.push("/login");
      return;
    }
    setPurchasingId(materialId);
    try {
      const res = await api.post<{ success: boolean; data: { payment_url: string; trans_token: string } }>(
        `/mental-health-materials/${materialId}/purchase`
      );
      // Store token so verify page can retrieve it after DPO Pay redirects back
      sessionStorage.setItem("mh_trans_token", res.data.data.trans_token);
      window.location.href = res.data.data.payment_url;
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg ?? "Failed to initiate payment");
      setPurchasingId(null);
    }
  };

  const displayed = search.trim()
    ? materials.filter(m =>
        m.title.toLowerCase().includes(search.toLowerCase()) ||
        m.description?.toLowerCase().includes(search.toLowerCase())
      )
    : materials;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-gradient-to-r from-brand-600 to-brand-700 pt-28 pb-10 px-4">
        <div className="max-w-5xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            <Brain className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">Mental Health Resources</h1>
          </div>
          <p className="text-brand-200 text-sm mb-6">
            Curated materials to support your mental wellbeing journey
          </p>
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text" value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Search materials…"
              className="w-full pl-11 pr-10 py-3.5 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm"
            />
            {search && (
              <button onClick={() => setSearch("")} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-6 pb-16">

        {/* ── Screening Tools Banner ── */}
        {surveys.length > 0 && (
          <div className="mb-8 bg-gradient-to-r from-brand-700 to-brand-900 rounded-3xl overflow-hidden shadow-md">
            <div className="p-6 sm:p-8">
              <div className="flex items-center gap-2 mb-1">
                <Sparkles className="w-4 h-4 text-brand-200" />
                <span className="text-brand-200 text-xs font-bold uppercase tracking-widest">Mental Wellness Screenings</span>
              </div>
              <h2 className="text-xl sm:text-2xl font-bold text-white mb-1">
                How are you feeling today?
              </h2>
              <p className="text-brand-200 text-sm mb-6 max-w-xl">
                Take a free, confidential screening to understand your mental wellbeing. Select a questionnaire below and get personalised resources based on your result.
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {surveys.map(s => {
                  const meta = SURVEY_META[s.slug] ?? DEFAULT_SURVEY_META;
                  return (
                    <Link
                      key={s.id}
                      href={`/surveys/${s.id}`}
                      className="flex items-center gap-3 bg-white/10 hover:bg-white/20 border border-white/20 hover:border-white/40 rounded-2xl p-4 transition-all group"
                    >
                      <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${meta.gradient} flex items-center justify-center flex-shrink-0 shadow-sm`}>
                        {meta.icon}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-bold text-brand-200 uppercase tracking-wide mb-0.5">{meta.tag}</p>
                        <p className="text-sm font-bold text-white line-clamp-1 group-hover:text-brand-100 transition-colors">{s.title}</p>
                        <p className="text-xs text-brand-300">{s.questions_count} question{s.questions_count !== 1 ? "s" : ""}</p>
                      </div>
                      <ArrowRight className="w-4 h-4 text-brand-300 group-hover:text-white group-hover:translate-x-0.5 transition-all flex-shrink-0" />
                    </Link>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* Filter tabs */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div className="flex gap-2">
            {(["all", "free", "paid"] as const).map(t => (
              <button key={t} onClick={() => setFilter(t)}
                className={`px-4 py-2 rounded-xl text-sm font-semibold transition-colors capitalize ${
                  filter === t
                    ? "bg-brand-600 text-white shadow-sm"
                    : "bg-white text-gray-600 border border-gray-200 hover:border-brand-300"
                }`}>
                {t === "paid" ? "Expert / Premium" : t === "free" ? "Free" : "All"}
              </button>
            ))}
          </div>
          <p className="text-xs text-gray-400 italic">Curated resources for your mental wellbeing journey</p>
        </div>

        {loading && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {Array.from({ length: 6 }).map((_, i) => <CardSkeleton key={i} />)}
          </div>
        )}

        {!loading && displayed.length === 0 && (
          <div className="text-center py-20">
            <BookOpen className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-1">No materials found</p>
            <p className="text-sm text-gray-400">
              {search ? "Try a different search term" : "Check back soon — materials are being added"}
            </p>
          </div>
        )}

        {!loading && displayed.length > 0 && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {displayed.map(m => (
              <MaterialCard
                key={m.id}
                m={m}
                hasAccess={purchasedIds.includes(m.id)}
                isLoggedIn={isLoggedIn}
                purchasing={purchasingId === m.id}
                onPurchase={handlePurchase}
              />
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

export default function MentalHealthPage() {
  return (
    <Suspense fallback={
      <main className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
      </main>
    }>
      <MentalHealthPageInner />
    </Suspense>
  );
}
