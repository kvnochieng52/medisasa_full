"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import {
  Stethoscope, Plus, Search, Loader2, CheckCircle2, XCircle, Clock,
  Eye, Pencil, Trash2, Power, FileText, Mail, Phone, BadgeCheck,
} from "lucide-react";

interface SpUser {
  id: number;
  name: string;
  email: string;
  telephone?: string | null;
  account_type: number;
  is_active: number | boolean;
  sp_approved: number | null;
  licence_number?: string | null;
  professional_bio?: string | null;
  profile_image?: string | null;
  created_at?: string;
  specializations?: { id: number; name: string }[];
  documents?: unknown[];
}

type SpFilter = "all" | "0" | "1" | "3";

const SP_FILTER_LABEL: Record<SpFilter, string> = {
  all: "All",
  "0": "Pending",
  "1": "Approved",
  "3": "Declined",
};

const SP_FILTER_ICON: Record<SpFilter, React.ReactNode> = {
  all: <Stethoscope className="w-3.5 h-3.5" />,
  "0": <Clock className="w-3.5 h-3.5" />,
  "1": <CheckCircle2 className="w-3.5 h-3.5" />,
  "3": <XCircle className="w-3.5 h-3.5" />,
};

function initials(name: string) {
  return name.split(" ").map(p => p[0]).filter(Boolean).slice(0, 2).join("").toUpperCase();
}

export default function AdminServiceProvidersPage() {
  const [users, setUsers] = useState<SpUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [spFilter, setSpFilter] = useState<SpFilter>("all");
  const [actingId, setActingId] = useState<number | null>(null);
  const [meta, setMeta] = useState<{ total: number } | null>(null);

  const load = () => {
    setLoading(true);
    const params: Record<string, string> = { per_page: "50", account_type: "2" };
    if (search) params.search = search;
    if (spFilter !== "all") params.sp_approved = spFilter;

    api.get("/admin/users", { params })
      .then(res => {
        setUsers(Array.isArray(res.data?.data) ? res.data.data : []);
        setMeta(res.data?.meta ?? null);
      })
      .catch(() => toast.error("Failed to load service providers"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [spFilter]);

  const onSearch = (e: React.FormEvent) => { e.preventDefault(); load(); };

  const act = async (id: number, kind: "approve" | "decline" | "toggle" | "delete") => {
    setActingId(id);
    try {
      if (kind === "delete") {
        if (!confirm("Delete this service provider? This cannot be undone.")) { setActingId(null); return; }
        await api.delete(`/admin/users/${id}`);
        toast.success("Service provider deleted");
        setUsers(prev => prev.filter(u => u.id !== id));
      } else {
        const path =
          kind === "approve" ? `/admin/users/${id}/approve` :
          kind === "decline" ? `/admin/users/${id}/decline` :
                               `/admin/users/${id}/toggle-status`;
        const res = await api.patch(path);
        toast.success(res.data?.message || "Updated");
        setUsers(prev => prev.map(u => u.id === id ? { ...u, ...res.data?.data } : u));
      }
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg || "Action failed");
    } finally {
      setActingId(null);
    }
  };

  // Summary counts
  const pending = users.filter(u => Number(u.sp_approved ?? 0) === 0).length;
  const approved = users.filter(u => Number(u.sp_approved ?? 0) === 1).length;
  const declined = users.filter(u => Number(u.sp_approved ?? 0) === 3).length;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 pt-28 pb-16">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-sm">
              <Stethoscope className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">Service Providers</h1>
              <p className="text-sm text-gray-400">
                {meta?.total != null ? `${meta.total} providers` : "Review applications and manage approved providers"}
              </p>
            </div>
          </div>
          <Link href="/admin/users/new?type=2"
            className="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 hover:opacity-95 text-white text-sm font-bold rounded-xl transition-all shadow-sm">
            <Plus className="w-4 h-4" /> Add Provider
          </Link>
        </div>

        {/* Summary cards */}
        {!loading && (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-6">
            <StatCard tone="yellow" icon={<Clock className="w-5 h-5" />} label="Pending approval" value={pending} active={spFilter === "0"} onClick={() => setSpFilter("0")} />
            <StatCard tone="green" icon={<CheckCircle2 className="w-5 h-5" />} label="Approved" value={approved} active={spFilter === "1"} onClick={() => setSpFilter("1")} />
            <StatCard tone="red" icon={<XCircle className="w-5 h-5" />} label="Declined" value={declined} active={spFilter === "3"} onClick={() => setSpFilter("3")} />
          </div>
        )}

        {/* Search + filter */}
        <div className="bg-white rounded-2xl border border-gray-100 p-4 mb-6 space-y-3">
          <form onSubmit={onSearch} className="flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input type="text" value={search} onChange={e => setSearch(e.target.value)}
                placeholder="Search by name, email, or phone…"
                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-brand-200 focus:border-brand-400" />
            </div>
            <button type="submit"
              className="px-5 py-2.5 bg-gray-900 hover:bg-gray-800 text-white text-sm font-semibold rounded-xl transition-colors">
              Search
            </button>
          </form>

          <div className="flex flex-wrap gap-2">
            {(["all", "0", "1", "3"] as SpFilter[]).map(f => (
              <Pill key={f} active={spFilter === f} onClick={() => setSpFilter(f)}>
                {SP_FILTER_ICON[f]} {SP_FILTER_LABEL[f]}
              </Pill>
            ))}
          </div>
        </div>

        {/* List */}
        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
          </div>
        ) : users.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-gray-100">
            <Stethoscope className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600">No service providers match these filters</p>
          </div>
        ) : (
          <div className="space-y-3">
            {users.map(u => {
              const isActive = Number(u.is_active) === 1;
              const sp = Number(u.sp_approved ?? 0);
              const busy = actingId === u.id;
              const docs = u.documents?.length ?? 0;

              return (
                <div key={u.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
                  <div className="flex flex-col sm:flex-row sm:items-start gap-4">
                    {/* Avatar */}
                    <div className="w-14 h-14 rounded-2xl bg-blue-50 flex-shrink-0 overflow-hidden flex items-center justify-center text-blue-600 font-bold">
                      {u.profile_image
                        ? <img src={getImageUrl(u.profile_image)} alt={u.name} className="w-full h-full object-cover" />
                        : initials(u.name)}
                    </div>

                    {/* Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap mb-1.5">
                        <p className="text-sm font-bold text-gray-900 truncate">{u.name}</p>
                        <SpStatusBadge status={sp} />
                        <StatusBadge active={isActive} />
                        {u.licence_number && (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-50 text-blue-700">
                            <BadgeCheck className="w-2.5 h-2.5" /> Lic. {u.licence_number}
                          </span>
                        )}
                      </div>

                      <div className="text-xs text-gray-500 flex flex-wrap gap-x-3 gap-y-0.5 mb-2">
                        <span className="flex items-center gap-1"><Mail className="w-3 h-3" /> {u.email}</span>
                        {u.telephone && <span className="flex items-center gap-1"><Phone className="w-3 h-3" /> {u.telephone}</span>}
                        {docs > 0 && <span className="flex items-center gap-1"><FileText className="w-3 h-3" /> {docs} document{docs === 1 ? "" : "s"}</span>}
                      </div>

                      {/* Specializations */}
                      {!!u.specializations?.length && (
                        <div className="flex flex-wrap gap-1 mb-2">
                          {u.specializations.slice(0, 4).map(s => (
                            <span key={s.id} className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700">{s.name}</span>
                          ))}
                          {u.specializations.length > 4 && (
                            <span className="text-[10px] font-semibold text-gray-400">+{u.specializations.length - 4} more</span>
                          )}
                        </div>
                      )}

                      {u.professional_bio && (
                        <p className="text-xs text-gray-500 line-clamp-2">{u.professional_bio}</p>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 flex-shrink-0 flex-wrap sm:justify-end">
                      {sp !== 1 && (
                        <button onClick={() => act(u.id, "approve")} disabled={busy}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold rounded-lg bg-green-500 hover:bg-green-600 disabled:opacity-50 text-white transition-colors">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Approve
                        </button>
                      )}
                      {sp !== 3 && (
                        <button onClick={() => act(u.id, "decline")} disabled={busy}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50 transition-colors">
                          <XCircle className="w-3.5 h-3.5" /> Decline
                        </button>
                      )}
                      <button onClick={() => act(u.id, "toggle")} disabled={busy}
                        className={`p-2 rounded-lg border transition-colors disabled:opacity-50 ${isActive ? "border-amber-200 text-amber-600 hover:bg-amber-50" : "border-green-200 text-green-600 hover:bg-green-50"}`}
                        title={isActive ? "Deactivate" : "Activate"}>
                        <Power className="w-4 h-4" />
                      </button>
                      <Link href={`/admin/users/${u.id}`}
                        className="p-2 rounded-lg border border-gray-200 text-gray-500 hover:border-blue-300 hover:text-blue-600 transition-colors" title="View">
                        <Eye className="w-4 h-4" />
                      </Link>
                      <Link href={`/admin/users/${u.id}/edit`}
                        className="p-2 rounded-lg border border-gray-200 text-gray-500 hover:border-blue-300 hover:text-blue-600 transition-colors" title="Edit">
                        <Pencil className="w-4 h-4" />
                      </Link>
                      <button onClick={() => act(u.id, "delete")} disabled={busy}
                        className="p-2 rounded-lg border border-gray-200 text-gray-500 hover:border-red-300 hover:text-red-600 transition-colors disabled:opacity-50" title="Delete">
                        {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
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

function StatCard({
  tone, icon, label, value, active, onClick,
}: {
  tone: "yellow" | "green" | "red";
  icon: React.ReactNode;
  label: string;
  value: number;
  active: boolean;
  onClick: () => void;
}) {
  const tones: Record<string, string> = {
    yellow: active ? "bg-yellow-50 border-yellow-300 text-yellow-800" : "bg-white border-gray-100 hover:border-yellow-200",
    green:  active ? "bg-green-50 border-green-300 text-green-800"   : "bg-white border-gray-100 hover:border-green-200",
    red:    active ? "bg-red-50 border-red-300 text-red-800"         : "bg-white border-gray-100 hover:border-red-200",
  };
  const iconBg: Record<string, string> = {
    yellow: "bg-yellow-100 text-yellow-700",
    green: "bg-green-100 text-green-700",
    red: "bg-red-100 text-red-700",
  };
  return (
    <button onClick={onClick}
      className={`text-left p-4 rounded-2xl border-2 transition-all ${tones[tone]}`}>
      <div className="flex items-center gap-3">
        <div className={`p-2 rounded-xl ${iconBg[tone]}`}>{icon}</div>
        <div>
          <p className="text-xs font-bold uppercase tracking-widest opacity-70">{label}</p>
          <p className="text-2xl font-bold">{value}</p>
        </div>
      </div>
    </button>
  );
}

function Pill({ children, active, onClick }: {
  children: React.ReactNode; active: boolean; onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick}
      className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all ${
        active ? "bg-blue-500 text-white border-blue-500" : "border-gray-200 text-gray-500 hover:border-blue-300"
      }`}>
      {children}
    </button>
  );
}

function StatusBadge({ active }: { active: boolean }) {
  return (
    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${active ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"}`}>
      {active ? "Active" : "Inactive"}
    </span>
  );
}

function SpStatusBadge({ status }: { status: number }) {
  const cls =
    status === 1 ? "bg-green-100 text-green-700" :
    status === 3 ? "bg-red-100 text-red-700" :
                   "bg-yellow-100 text-yellow-700";
  const label =
    status === 1 ? "Approved" :
    status === 3 ? "Declined" :
                   "Pending";
  const icon =
    status === 1 ? <CheckCircle2 className="w-2.5 h-2.5" /> :
    status === 3 ? <XCircle className="w-2.5 h-2.5" /> :
                   <Clock className="w-2.5 h-2.5" />;
  return (
    <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full ${cls}`}>
      {icon} {label}
    </span>
  );
}
