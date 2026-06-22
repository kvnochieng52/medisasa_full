"use client";

import { useEffect, useState, useCallback } from "react";
import Navbar from "@/components/Navbar";
import { Search, X, Users, MapPin, Globe, Lock, EyeOff, RefreshCw, Tag, ChevronRight } from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";

interface Category { id: number; name: string; slug: string }

interface Group {
  id: number;
  group_name: string;
  group_description?: string;
  group_location?: string;
  group_tags?: string[];
  group_privacy: "public" | "private" | "closed";
  require_approval?: boolean;
  categories?: Category[];
}

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 animate-pulse space-y-2">
      <div className="h-4 bg-gray-200 rounded w-2/3" />
      <div className="h-3 bg-gray-100 rounded w-1/2" />
      <div className="h-3 bg-gray-100 rounded w-full" />
      <div className="h-3 bg-gray-100 rounded w-4/5" />
    </div>
  );
}

const privacyConfig = {
  public:  { icon: Globe,   label: "Public",  cls: "bg-green-100 text-green-700" },
  private: { icon: Lock,    label: "Private", cls: "bg-amber-100 text-amber-700" },
  closed:  { icon: EyeOff,  label: "Closed",  cls: "bg-red-100 text-red-700" },
};

export default function SupportGroupsPage() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [filtered, setFiltered] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState("");

  useEffect(() => {
    api.get("/public-groups")
      .then(res => {
        const list: Group[] = Array.isArray(res.data?.data) ? res.data.data : [];
        setGroups(list);
        setFiltered(list);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);

  const applyFilter = useCallback((query: string, list: Group[]) => {
    if (!query.trim()) { setFiltered(list); return; }
    const q = query.toLowerCase();
    setFiltered(list.filter(g =>
      g.group_name.toLowerCase().includes(q) ||
      g.group_description?.toLowerCase().includes(q) ||
      g.group_location?.toLowerCase().includes(q) ||
      g.group_tags?.some(t => t.toLowerCase().includes(q)) ||
      g.categories?.some(c => c.name.toLowerCase().includes(q))
    ));
  }, []);

  useEffect(() => { applyFilter(search, groups); }, [search, groups, applyFilter]);

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-gradient-to-r from-orange-500 to-amber-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            <Users className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">Support Groups</h1>
          </div>
          <p className="text-orange-100 text-sm mb-6">Connect with communities supporting your health journey</p>
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, location or topic…"
              className="w-full pl-11 pr-10 py-3.5 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm"
            />
            {search && (
              <button onClick={() => setSearch("")} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Bar */}
      <div className="max-w-4xl mx-auto px-4 py-4">
        <p className="text-sm text-gray-500 font-medium">
          {loading ? "Loading…" : `${filtered.length} group${filtered.length !== 1 ? "s" : ""} found`}
        </p>
      </div>

      {/* List */}
      <div className="max-w-4xl mx-auto px-4 pb-12 space-y-3">
        {loading && Array.from({ length: 6 }).map((_, i) => <CardSkeleton key={i} />)}

        {error && (
          <div className="text-center py-16">
            <Users className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-2">Failed to load groups</p>
            <button onClick={() => window.location.reload()}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-semibold text-sm rounded-xl transition-colors">
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <div className="text-center py-16">
            <Search className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-1">No groups found</p>
            <p className="text-sm text-gray-400">Try adjusting your search</p>
          </div>
        )}

        {!loading && !error && filtered.map(g => {
          const pc = privacyConfig[g.group_privacy] ?? privacyConfig.public;
          const PrivIcon = pc.icon;

          return (
            <Link
              key={g.id}
              href={`/support-groups/${g.id}`}
              className="block bg-white rounded-2xl shadow-sm border border-gray-100 p-5 hover:shadow-md hover:border-orange-200 transition-all group"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="font-bold text-gray-900 text-sm group-hover:text-orange-600 transition-colors">{g.group_name}</h3>
                    <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${pc.cls}`}>
                      <PrivIcon className="w-3 h-3" /> {pc.label}
                    </span>
                    {g.require_approval && (
                      <span className="text-xs font-semibold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">Approval needed</span>
                    )}
                  </div>

                  {g.group_location && (
                    <div className="flex items-center gap-1 mt-1.5">
                      <MapPin className="w-3 h-3 text-gray-400 flex-shrink-0" />
                      <span className="text-xs text-gray-500">{g.group_location}</span>
                    </div>
                  )}

                  {g.group_description && (
                    <p className="text-sm text-gray-600 mt-2 leading-relaxed line-clamp-2">{g.group_description}</p>
                  )}

                  {g.categories && g.categories.length > 0 && (
                    <div className="flex flex-wrap gap-1 mt-2">
                      {g.categories.map(c => (
                        <span key={c.id} className="text-xs bg-orange-50 text-orange-700 px-2 py-0.5 rounded-full">{c.name}</span>
                      ))}
                    </div>
                  )}

                  {g.group_tags && g.group_tags.length > 0 && (
                    <div className="flex flex-wrap items-center gap-1 mt-2">
                      <Tag className="w-3 h-3 text-gray-400" />
                      {g.group_tags.slice(0, 5).map(t => (
                        <span key={t} className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">{t}</span>
                      ))}
                    </div>
                  )}
                </div>

                <div className="flex flex-col items-center gap-2 flex-shrink-0">
                  <div className="w-12 h-12 rounded-2xl bg-orange-50 flex items-center justify-center">
                    <Users className="w-6 h-6 text-orange-400" />
                  </div>
                  <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-orange-500 transition-colors" />
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </main>
  );
}
