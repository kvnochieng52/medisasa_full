"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Users, MapPin, Globe, Lock, EyeOff, Tag, ArrowLeft,
  Calendar, Loader2, CheckCircle2, ChevronRight, Heart,
} from "lucide-react";
import { getImageUrl } from "@/lib/api";
import api from "@/lib/api";

interface Category    { id: number; name: string; slug: string }
interface Subcategory { id: number; name: string; slug: string }

interface Group {
  id: number;
  group_name: string;
  group_description?: string;
  group_location?: string;
  group_tags?: string[];
  group_privacy: "public" | "private" | "closed";
  require_approval?: boolean;
  group_image?: string;
  cover_image?: string;
  category?: Category | null;
  subcategories?: Subcategory[];
  created_at?: string;
  meeting_schedule?: string;
  contact_email?: string;
  contact_phone?: string;
  website_url?: string;
  max_members?: number;
}

const privacyConfig = {
  public:  { icon: Globe,   label: "Public",  cls: "bg-green-100 text-green-700",  desc: "Anyone can view and join this group." },
  private: { icon: Lock,    label: "Private", cls: "bg-amber-100 text-amber-700",  desc: "Only members can see the group content." },
  closed:  { icon: EyeOff,  label: "Closed",  cls: "bg-red-100 text-red-700",      desc: "This group is no longer accepting members." },
};

export default function SupportGroupDetailPage() {
  const { id }   = useParams<{ id: string }>();
  const router   = useRouter();
  const [group, setGroup]     = useState<Group | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get(`/public-groups/${id}`)
      .then(res => setGroup(res.data?.group ?? null))
      .catch(() => router.push("/support-groups"))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex justify-center pt-40">
          <Loader2 className="w-8 h-8 animate-spin text-orange-400" />
        </div>
      </main>
    );
  }

  if (!group) return null;

  const pc       = privacyConfig[group.group_privacy] ?? privacyConfig.public;
  const PrivIcon = pc.icon;
  const coverImg = getImageUrl(group.cover_image);
  const groupImg = getImageUrl(group.group_image);
  const joinable = group.group_privacy !== "closed";

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Cover / hero */}
      <div className="relative pt-16">
        <div
          className="h-52 sm:h-64 bg-gradient-to-r from-orange-400 to-amber-500"
          style={coverImg ? { backgroundImage: `url(${coverImg})`, backgroundSize: "cover", backgroundPosition: "center" } : undefined}
        >
          {coverImg && <div className="absolute inset-0 bg-black/30" />}
        </div>

        {/* Back button */}
        <div className="absolute top-20 left-4 sm:left-8">
          <Link
            href="/support-groups"
            className="inline-flex items-center gap-1.5 bg-white/80 hover:bg-white backdrop-blur-sm text-gray-700 text-sm font-semibold px-3 py-1.5 rounded-xl shadow-sm transition-colors"
          >
            <ArrowLeft className="w-4 h-4" /> All Groups
          </Link>
        </div>

        {/* Group avatar + name row */}
        <div className="max-w-3xl mx-auto px-4 sm:px-6 relative -mt-10">
          <div className="flex items-end gap-4">
            <div className="w-20 h-20 rounded-2xl border-4 border-white shadow-md bg-orange-50 flex items-center justify-center flex-shrink-0 overflow-hidden">
              {groupImg
                ? <img src={groupImg} alt={group.group_name} className="w-full h-full object-cover" />
                : <Users className="w-9 h-9 text-orange-400" />}
            </div>
            <div className="pb-1 min-w-0">
              <h1 className="text-xl sm:text-2xl font-bold text-gray-900 leading-tight">{group.group_name}</h1>
              <div className="flex items-center flex-wrap gap-2 mt-1">
                <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${pc.cls}`}>
                  <PrivIcon className="w-3 h-3" /> {pc.label}
                </span>
                {group.require_approval && (
                  <span className="text-xs font-semibold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">Approval needed</span>
                )}
                {group.category && (
                  <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full font-semibold">
                    {group.category.name}
                  </span>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 pb-16 space-y-5">

        {/* About */}
        {group.group_description && (
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <h2 className="font-bold text-gray-900 mb-2 text-sm uppercase tracking-wide text-gray-400">About</h2>
            <p className="text-gray-700 text-sm leading-relaxed">{group.group_description}</p>
          </div>
        )}

        {/* Details grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {group.group_location && (
            <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center flex-shrink-0">
                <MapPin className="w-4.5 h-4.5 text-orange-500" />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-0.5">Location</p>
                <p className="text-sm font-semibold text-gray-800">{group.group_location}</p>
              </div>
            </div>
          )}

          {group.meeting_schedule && (
            <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center flex-shrink-0">
                <Calendar className="w-4.5 h-4.5 text-orange-500" />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-0.5">Meets</p>
                <p className="text-sm font-semibold text-gray-800">{group.meeting_schedule}</p>
              </div>
            </div>
          )}

          {group.max_members && (
            <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center flex-shrink-0">
                <Users className="w-4.5 h-4.5 text-orange-500" />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-0.5">Max Members</p>
                <p className="text-sm font-semibold text-gray-800">{group.max_members}</p>
              </div>
            </div>
          )}

          {group.created_at && (
            <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center flex-shrink-0">
                <Calendar className="w-4.5 h-4.5 text-orange-500" />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-0.5">Founded</p>
                <p className="text-sm font-semibold text-gray-800">
                  {new Date(group.created_at).toLocaleDateString("en-KE", { year: "numeric", month: "long" })}
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Subcategories */}
        {group.subcategories && group.subcategories.length > 0 && (
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <h2 className="font-bold text-gray-900 mb-3 text-sm">Focus Areas</h2>
            <div className="flex flex-wrap gap-2">
              {group.subcategories.map(s => (
                <span key={s.id} className="text-xs bg-orange-50 text-orange-700 font-semibold px-3 py-1 rounded-full border border-orange-100">
                  {s.name}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Tags */}
        {group.group_tags && group.group_tags.length > 0 && (
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <h2 className="font-bold text-gray-900 mb-3 text-sm flex items-center gap-2">
              <Tag className="w-4 h-4 text-gray-400" /> Tags
            </h2>
            <div className="flex flex-wrap gap-2">
              {group.group_tags.map(t => (
                <span key={t} className="text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full">{t}</span>
              ))}
            </div>
          </div>
        )}

        {/* Membership / CTA */}
        <div className={`rounded-2xl p-5 shadow-sm border ${joinable ? "bg-gradient-to-r from-orange-500 to-amber-500 border-orange-400" : "bg-white border-gray-100"}`}>
          {joinable ? (
            <div className="text-white">
              <h2 className="font-bold text-lg mb-1 flex items-center gap-2">
                <Heart className="w-5 h-5" /> Join This Group
              </h2>
              <p className="text-orange-100 text-sm mb-4">{pc.desc}</p>
              <div className="space-y-2">
                {group.require_approval ? (
                  <div className="flex items-start gap-2 text-orange-100 text-xs">
                    <CheckCircle2 className="w-4 h-4 mt-0.5 flex-shrink-0" />
                    <span>Membership requires admin approval before you can access group content.</span>
                  </div>
                ) : (
                  <div className="flex items-start gap-2 text-orange-100 text-xs">
                    <CheckCircle2 className="w-4 h-4 mt-0.5 flex-shrink-0" />
                    <span>Open membership — anyone can join immediately.</span>
                  </div>
                )}
              </div>
              {group.contact_email && (
                <a
                  href={`mailto:${group.contact_email}`}
                  className="inline-flex items-center gap-2 mt-4 bg-white text-orange-600 font-bold text-sm px-5 py-2.5 rounded-xl hover:bg-orange-50 transition-colors shadow-sm"
                >
                  Contact to Join <ChevronRight className="w-4 h-4" />
                </a>
              )}
            </div>
          ) : (
            <div className="text-center py-4">
              <EyeOff className="w-10 h-10 text-gray-300 mx-auto mb-3" />
              <p className="font-semibold text-gray-600">{pc.desc}</p>
            </div>
          )}
        </div>

        {/* Mental health resources nudge */}
        <div className="bg-white rounded-2xl border border-brand-100 p-5 shadow-sm">
          <p className="text-xs font-bold text-brand-500 uppercase tracking-wide mb-1">Also explore</p>
          <h3 className="font-bold text-gray-900 mb-1">Mental Health Resources</h3>
          <p className="text-sm text-gray-500 mb-3">Guides, videos and free tools to support your wellbeing alongside this group.</p>
          <Link
            href="/mental-health"
            className="inline-flex items-center gap-2 text-sm font-bold text-brand-600 hover:text-brand-700 transition-colors"
          >
            Browse resources <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </main>
  );
}
