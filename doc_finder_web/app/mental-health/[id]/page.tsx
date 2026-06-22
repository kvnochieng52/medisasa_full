"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Brain, Globe, Lock, Play, FileText, ArrowLeft,
  Loader2, ShoppingCart, Download, Eye, CheckCircle2,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";

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

export default function MaterialDetailPage() {
  const { id }   = useParams<{ id: string }>();
  const router   = useRouter();

  const [material, setMaterial]     = useState<Material | null>(null);
  const [loading, setLoading]       = useState(true);
  const [notFound, setNotFound]     = useState(false);
  const [hasAccess, setHasAccess]   = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [purchasing, setPurchasing] = useState(false);

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("auth_token") : null;
    setIsLoggedIn(!!token);

    api.get<{ success: boolean; data: Material }>(`/mental-health-materials/${id}`)
      .then(res => {
        const m = res.data.data;
        setMaterial(m);
        if (m.is_free) {
          setHasAccess(true);
        } else if (token) {
          api.get<{ success: boolean; data: number[] }>("/mental-health-purchases/my")
            .then(r => setHasAccess((r.data.data ?? []).includes(m.id)))
            .catch(() => {});
        }
      })
      .catch(() => setNotFound(true))
      .finally(() => setLoading(false));
  }, [id]);

  const handlePurchase = async () => {
    if (!isLoggedIn) { router.push("/login"); return; }
    if (!material) return;
    setPurchasing(true);
    try {
      const res = await api.post<{ success: boolean; data: { payment_url: string; trans_token: string } }>(
        `/mental-health-materials/${material.id}/purchase`
      );
      sessionStorage.setItem("mh_trans_token", res.data.data.trans_token);
      window.location.href = res.data.data.payment_url;
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg ?? "Failed to initiate payment");
      setPurchasing(false);
    }
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Navbar />
        <Loader2 className="w-8 h-8 animate-spin text-purple-500" />
      </main>
    );
  }

  if (notFound || !material) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="max-w-2xl mx-auto px-4 pt-32 text-center">
          <Brain className="w-12 h-12 text-gray-200 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-700 mb-2">Resource not found</h2>
          <p className="text-sm text-gray-400 mb-6">This resource may have been removed or is unavailable.</p>
          <Link href="/mental-health" className="inline-flex items-center gap-2 text-purple-600 font-semibold hover:text-purple-800">
            <ArrowLeft className="w-4 h-4" /> Back to Resources
          </Link>
        </div>
      </main>
    );
  }

  const img  = getImageUrl(material.image_path);
  const fileUrl = getImageUrl(material.file_path);
  const Icon = material.file_type === "video" ? Play : FileText;
  const canAccess = material.is_free || hasAccess;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Cover image hero */}
      <div className="relative w-full h-64 sm:h-80 bg-gradient-to-br from-violet-700 to-purple-800 overflow-hidden">
        {img && (
          <img src={img} alt={material.title} className="w-full h-full object-cover opacity-50" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />

        {/* Back button */}
        <Link href="/mental-health"
          className="absolute top-6 left-4 sm:left-8 mt-16 inline-flex items-center gap-1.5 bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white text-sm font-semibold px-3 py-1.5 rounded-xl transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back
        </Link>

        {/* Badge */}
        <div className={`absolute top-6 right-4 sm:right-8 mt-16 flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full shadow ${
          material.is_free ? "bg-green-500 text-white" : "bg-white text-purple-700"
        }`}>
          {material.is_free ? <Globe className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
          {material.is_free ? "Free" : material.price != null ? `KES ${Number(material.price).toLocaleString()}` : "Premium"}
        </div>

        {/* File type */}
        {material.file_type && (
          <div className="absolute bottom-4 left-4 sm:left-8 flex items-center gap-1.5 bg-black/50 text-white text-xs font-semibold px-3 py-1 rounded-full">
            <Icon className="w-3.5 h-3.5" />
            {material.file_type === "video" ? "Video" : "PDF Document"}
          </div>
        )}
      </div>

      {/* Content card */}
      <div className="max-w-2xl mx-auto px-4 -mt-6 pb-16 relative z-10">
        <div className="bg-white rounded-3xl shadow-lg border border-gray-100 overflow-hidden">

          {/* Header */}
          <div className="p-6 sm:p-8">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-14 h-14 rounded-2xl bg-violet-50 flex items-center justify-center flex-shrink-0">
                {img
                  ? <img src={img} alt="" className="w-full h-full object-cover rounded-2xl" />
                  : <Brain className="w-7 h-7 text-violet-400" />}
              </div>
              <div className="flex-1 min-w-0">
                <h1 className="text-xl sm:text-2xl font-bold text-gray-900 leading-tight">{material.title}</h1>
                <p className="text-sm text-gray-400 mt-1">Mental Health Resource</p>
              </div>
            </div>

            {material.description && (
              <p className="text-gray-600 text-sm leading-relaxed">{material.description}</p>
            )}
          </div>

          {/* Divider */}
          <div className="border-t border-gray-100" />

          {/* Action area */}
          <div className="p-6 sm:p-8">
            {canAccess ? (
              <div>
                {hasAccess && !material.is_free && (
                  <div className="flex items-center gap-2 mb-4 text-sm text-green-600 font-semibold">
                    <CheckCircle2 className="w-4 h-4" /> You have purchased this resource
                  </div>
                )}
                {fileUrl ? (
                  <a
                    href={fileUrl}
                    target="_blank"
                    rel="noreferrer"
                    className={`w-full flex items-center justify-center gap-2 py-3.5 rounded-2xl font-bold text-sm transition-all shadow-sm ${
                      material.is_free
                        ? "bg-green-500 hover:bg-green-600 text-white"
                        : "bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 text-white"
                    }`}
                  >
                    {material.file_type === "video"
                      ? <><Eye className="w-4 h-4" /> Watch Now</>
                      : <><Download className="w-4 h-4" /> Read / Download</>}
                  </a>
                ) : (
                  <p className="text-sm text-gray-400 text-center">No file attached to this resource.</p>
                )}
              </div>
            ) : (
              <div>
                <div className="bg-purple-50 border border-purple-100 rounded-2xl p-4 mb-4">
                  <div className="flex items-start gap-3">
                    <Lock className="w-5 h-5 text-purple-500 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-sm font-bold text-purple-800">Premium Resource</p>
                      <p className="text-xs text-purple-600 mt-0.5">
                        {isLoggedIn
                          ? "Purchase this resource to unlock full access."
                          : "Log in and purchase to unlock full access to this resource."}
                      </p>
                    </div>
                  </div>
                </div>
                <button
                  onClick={handlePurchase}
                  disabled={purchasing}
                  className="w-full flex items-center justify-center gap-2 py-3.5 rounded-2xl font-bold text-sm bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 disabled:opacity-60 text-white transition-all shadow-sm"
                >
                  {purchasing
                    ? <><Loader2 className="w-4 h-4 animate-spin" /> Redirecting to payment…</>
                    : isLoggedIn
                      ? <><ShoppingCart className="w-4 h-4" /> Buy Now — KES {material.price != null ? Number(material.price).toLocaleString() : "–"}</>
                      : <><Lock className="w-4 h-4" /> Login to Purchase</>}
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
