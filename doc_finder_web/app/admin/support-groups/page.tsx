"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Users, Plus, Search, MapPin, Lock, Globe, EyeOff,
  Pencil, Trash2, Loader2, ChevronRight, Tag, ShieldCheck,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Group {
  id: number;
  group_name: string;
  group_description: string;
  group_location: string;
  group_tags?: string;
  group_privacy: "public" | "private" | "closed";
  require_approval: boolean;
  group_image?: string;
  cover_image?: string;
  group_image_url?: string;
  cover_image_url?: string;
}

const PRIVACY_CONFIG = {
  public:  { label: "Public",  icon: Globe,   color: "bg-green-100 text-green-700" },
  private: { label: "Private", icon: Lock,    color: "bg-amber-100 text-amber-700" },
  closed:  { label: "Closed",  icon: EyeOff,  color: "bg-red-100 text-red-700" },
};

export default function SupportGroupsPage() {
  const router = useRouter();
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const fetchGroups = () => {
    setLoading(true);
    api.get<{ success: boolean; data: Group[] }>("/groups")
      .then(res => setGroups(res.data.data ?? []))
      .catch(() => toast.error("Failed to load support groups"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchGroups(); }, []);

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    setDeletingId(id);
    try {
      await api.delete(`/groups/${id}`);
      toast.success("Group deleted");
      setGroups(g => g.filter(x => x.id !== id));
    } catch {
      toast.error("Failed to delete group");
    } finally {
      setDeletingId(null);
    }
  };

  const filtered = groups.filter(g =>
    !search ||
    g.group_name.toLowerCase().includes(search.toLowerCase()) ||
    g.group_location.toLowerCase().includes(search.toLowerCase()) ||
    g.group_description.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-6xl mx-auto px-4 sm:px-6 pt-24 pb-16">

        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500 transition-colors">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Support Groups</span>
        </div>

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Support Groups</h1>
            <p className="text-gray-500 text-sm mt-0.5">Manage your community support groups</p>
          </div>
          <Link href="/admin/support-groups/new"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors shadow-sm">
            <Plus className="w-4 h-4" />
            New Group
          </Link>
        </div>

        {/* Search */}
        <div className="relative mb-6">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search groups by name, location…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-brand-300"
          />
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-24">
            <div className="w-16 h-16 rounded-2xl bg-brand-50 flex items-center justify-center mx-auto mb-4">
              <Users className="w-8 h-8 text-brand-400" />
            </div>
            <h3 className="font-semibold text-gray-700 mb-1">
              {search ? "No groups match your search" : "No support groups yet"}
            </h3>
            <p className="text-sm text-gray-400 mb-6">
              {search ? "Try a different keyword" : "Create your first support group to get started"}
            </p>
            {!search && (
              <Link href="/admin/support-groups/new"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 text-white font-semibold text-sm hover:bg-brand-600 transition-colors">
                <Plus className="w-4 h-4" /> Create Support Group
              </Link>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filtered.map(g => {
              const privacy = PRIVACY_CONFIG[g.group_privacy] ?? PRIVACY_CONFIG.public;
              const PrivacyIcon = privacy.icon;
              const coverSrc = getImageUrl(g.cover_image_url || g.cover_image);
              const imageSrc = getImageUrl(g.group_image_url || g.group_image);
              const tags = g.group_tags ? g.group_tags.split(",").map(t => t.trim()).filter(Boolean) : [];

              return (
                <div key={g.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden flex flex-col hover:shadow-md transition-shadow">
                  {/* Cover */}
                  <div className="relative h-32 bg-gradient-to-br from-brand-100 to-purple-100">
                    {coverSrc && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={coverSrc} alt="" className="w-full h-full object-cover" />
                    )}
                    {/* Privacy badge */}
                    <span className={`absolute top-2 right-2 inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${privacy.color}`}>
                      <PrivacyIcon className="w-3 h-3" />
                      {privacy.label}
                    </span>
                    {/* Group image */}
                    {imageSrc && (
                      <div className="absolute -bottom-6 left-4 w-12 h-12 rounded-xl border-2 border-white shadow overflow-hidden bg-white">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img src={imageSrc} alt="" className="w-full h-full object-cover" />
                      </div>
                    )}
                  </div>

                  <div className={`flex-1 flex flex-col p-4 ${imageSrc ? "pt-9" : "pt-4"}`}>
                    <h3 className="font-bold text-gray-900 text-sm mb-1 line-clamp-1">{g.group_name}</h3>
                    <p className="text-xs text-gray-500 line-clamp-2 mb-3">{g.group_description}</p>

                    <div className="flex items-center gap-1 text-xs text-gray-400 mb-2">
                      <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
                      <span className="line-clamp-1">{g.group_location}</span>
                    </div>

                    {g.require_approval && (
                      <div className="flex items-center gap-1 text-xs text-blue-600 mb-2">
                        <ShieldCheck className="w-3.5 h-3.5 flex-shrink-0" />
                        <span>Approval required</span>
                      </div>
                    )}

                    {tags.length > 0 && (
                      <div className="flex items-center gap-1 flex-wrap mb-3">
                        <Tag className="w-3 h-3 text-gray-300 flex-shrink-0" />
                        {tags.slice(0, 3).map(t => (
                          <span key={t} className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded-md">{t}</span>
                        ))}
                        {tags.length > 3 && <span className="text-xs text-gray-400">+{tags.length - 3}</span>}
                      </div>
                    )}

                    {/* Actions */}
                    <div className="mt-auto flex gap-2 pt-2 border-t border-gray-50">
                      <button
                        onClick={() => router.push(`/admin/support-groups/${g.id}/edit`)}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg border border-gray-200 text-xs font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
                      >
                        <Pencil className="w-3.5 h-3.5" /> Edit
                      </button>
                      <button
                        onClick={() => handleDelete(g.id, g.group_name)}
                        disabled={deletingId === g.id}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-red-50 text-xs font-semibold text-red-600 hover:bg-red-100 transition-colors disabled:opacity-50"
                      >
                        {deletingId === g.id
                          ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          : <Trash2 className="w-3.5 h-3.5" />}
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
