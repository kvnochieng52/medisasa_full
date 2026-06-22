"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import {
  Users, Plus, Search, Loader2, Shield, Stethoscope, User as UserIcon,
  CheckCircle2, XCircle, Clock, Eye, Pencil, Trash2, Power, MoreHorizontal,
} from "lucide-react";

interface AdminUser {
  id: number;
  name: string;
  email: string;
  telephone?: string | null;
  account_type: number | null;
  is_active: number | boolean;
  sp_approved: number | null;
  profile_image?: string | null;
  created_at?: string;
  specializations?: { id: number; name: string }[];
  documents?: unknown[];
}

const ACCOUNT_TYPE_LABEL: Record<number, string> = { 1: "Standard", 2: "Service Provider", 3: "Admin" };
const SP_STATUS_LABEL: Record<number, string> = { 0: "Pending", 1: "Approved", 3: "Declined" };

function initials(name: string) {
  return name.split(" ").map(p => p[0]).filter(Boolean).slice(0, 2).join("").toUpperCase();
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [accountFilter, setAccountFilter] = useState<string>("all");
  const [spFilter, setSpFilter] = useState<string>("all");
  const [actingId, setActingId] = useState<number | null>(null);
  const [meta, setMeta] = useState<{ total: number } | null>(null);

  const load = () => {
    setLoading(true);
    const params: Record<string, string> = { per_page: "50" };
    if (search) params.search = search;
    if (accountFilter !== "all") params.account_type = accountFilter;
    if (spFilter !== "all") params.sp_approved = spFilter;
    api.get("/admin/users", { params })
      .then(res => {
        setUsers(Array.isArray(res.data?.data) ? res.data.data : []);
        setMeta(res.data?.meta ?? null);
      })
      .catch(() => toast.error("Failed to load users"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [accountFilter, spFilter]);

  const onSearch = (e: React.FormEvent) => { e.preventDefault(); load(); };

  const act = async (id: number, kind: "approve" | "decline" | "toggle" | "delete") => {
    setActingId(id);
    try {
      if (kind === "delete") {
        if (!confirm("Delete this user? This cannot be undone.")) { setActingId(null); return; }
        await api.delete(`/admin/users/${id}`);
        toast.success("User deleted");
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

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 pt-28 pb-16">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-brand-500 to-brand-600 flex items-center justify-center shadow-sm">
              <Users className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">User Management</h1>
              <p className="text-sm text-gray-400">
                {meta?.total != null ? `${meta.total} users` : "Manage admins, service providers, and standard accounts"}
              </p>
            </div>
          </div>
          <Link href="/admin/users/new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-500 hover:bg-brand-600 text-white text-sm font-bold rounded-xl transition-colors shadow-sm">
            <Plus className="w-4 h-4" /> New User
          </Link>
        </div>

        {/* Filters */}
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
            <Pill active={accountFilter === "all"} onClick={() => setAccountFilter("all")}>All Roles</Pill>
            <Pill active={accountFilter === "3"} onClick={() => setAccountFilter("3")}><Shield className="w-3.5 h-3.5" /> Admins</Pill>
            <Pill active={accountFilter === "2"} onClick={() => setAccountFilter("2")}><Stethoscope className="w-3.5 h-3.5" /> Service Providers</Pill>
            <Pill active={accountFilter === "1"} onClick={() => setAccountFilter("1")}><UserIcon className="w-3.5 h-3.5" /> Standard</Pill>
          </div>

          {accountFilter === "2" && (
            <div className="flex flex-wrap gap-2">
              <Pill active={spFilter === "all"} onClick={() => setSpFilter("all")} subtle>All SP Statuses</Pill>
              <Pill active={spFilter === "0"} onClick={() => setSpFilter("0")} subtle><Clock className="w-3.5 h-3.5" /> Pending</Pill>
              <Pill active={spFilter === "1"} onClick={() => setSpFilter("1")} subtle><CheckCircle2 className="w-3.5 h-3.5" /> Approved</Pill>
              <Pill active={spFilter === "3"} onClick={() => setSpFilter("3")} subtle><XCircle className="w-3.5 h-3.5" /> Declined</Pill>
            </div>
          )}
        </div>

        {/* List */}
        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : users.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-gray-100">
            <Users className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600">No users match these filters</p>
          </div>
        ) : (
          <div className="space-y-3">
            {users.map(u => {
              const isSP = u.account_type === 2;
              const isAdmin = u.account_type === 3;
              const isActive = Number(u.is_active) === 1;
              const sp = Number(u.sp_approved ?? 0);
              const busy = actingId === u.id;

              return (
                <div key={u.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex flex-col sm:flex-row sm:items-center gap-4">
                  {/* Avatar */}
                  <div className="w-12 h-12 rounded-xl bg-brand-50 flex-shrink-0 overflow-hidden flex items-center justify-center text-brand-600 font-bold">
                    {u.profile_image
                      ? <img src={getImageUrl(u.profile_image)} alt={u.name} className="w-full h-full object-cover" />
                      : initials(u.name)}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1">
                      <p className="text-sm font-bold text-gray-900 truncate">{u.name}</p>
                      <RoleBadge type={u.account_type} />
                      <StatusBadge active={isActive} />
                      {isSP && <SpBadge status={sp} />}
                    </div>
                    <div className="text-xs text-gray-500 flex flex-wrap gap-x-3 gap-y-0.5">
                      <span className="truncate">{u.email}</span>
                      {u.telephone && <span>{u.telephone}</span>}
                      {!!u.specializations?.length && <span>{u.specializations.length} specialization{u.specializations.length === 1 ? "" : "s"}</span>}
                      {!!u.documents?.length && <span>{u.documents.length} doc{u.documents.length === 1 ? "" : "s"}</span>}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {isSP && sp === 0 && (
                      <>
                        <ActionBtn onClick={() => act(u.id, "approve")} disabled={busy} title="Approve" tone="green">
                          <CheckCircle2 className="w-4 h-4" />
                        </ActionBtn>
                        <ActionBtn onClick={() => act(u.id, "decline")} disabled={busy} title="Decline" tone="red">
                          <XCircle className="w-4 h-4" />
                        </ActionBtn>
                      </>
                    )}
                    <ActionBtn onClick={() => act(u.id, "toggle")} disabled={busy}
                      title={isActive ? "Deactivate" : "Activate"} tone={isActive ? "amber" : "green"}>
                      <Power className="w-4 h-4" />
                    </ActionBtn>
                    <Link href={`/admin/users/${u.id}`}
                      className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-brand-300 hover:text-brand-600 transition-colors" title="View">
                      <Eye className="w-4 h-4" />
                    </Link>
                    <Link href={`/admin/users/${u.id}/edit`}
                      className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-blue-300 hover:text-blue-600 transition-colors" title="Edit">
                      <Pencil className="w-4 h-4" />
                    </Link>
                    {!isAdmin && (
                      <ActionBtn onClick={() => act(u.id, "delete")} disabled={busy} title="Delete" tone="red">
                        {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                      </ActionBtn>
                    )}
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

function Pill({ children, active, onClick, subtle = false }: {
  children: React.ReactNode; active: boolean; onClick: () => void; subtle?: boolean;
}) {
  const baseActive = subtle
    ? "bg-gray-700 text-white border-gray-700"
    : "bg-brand-500 text-white border-brand-500";
  return (
    <button type="button" onClick={onClick}
      className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all ${
        active ? baseActive : "border-gray-200 text-gray-500 hover:border-brand-300"
      }`}>
      {children}
    </button>
  );
}

function RoleBadge({ type }: { type: number | null }) {
  const cls =
    type === 3 ? "bg-purple-100 text-purple-700" :
    type === 2 ? "bg-blue-100 text-blue-700" :
                 "bg-gray-100 text-gray-700";
  return <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${cls}`}>{ACCOUNT_TYPE_LABEL[type ?? 1] ?? "Unknown"}</span>;
}

function StatusBadge({ active }: { active: boolean }) {
  return (
    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${active ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"}`}>
      {active ? "Active" : "Inactive"}
    </span>
  );
}

function SpBadge({ status }: { status: number }) {
  const cls =
    status === 1 ? "bg-green-100 text-green-700" :
    status === 3 ? "bg-red-100 text-red-700" :
                   "bg-yellow-100 text-yellow-700";
  return <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${cls}`}>{SP_STATUS_LABEL[status] ?? "Pending"}</span>;
}

function ActionBtn({ children, onClick, disabled, title, tone }: {
  children: React.ReactNode; onClick: () => void; disabled?: boolean; title: string;
  tone: "green" | "red" | "amber" | "blue";
}) {
  const tones: Record<string, string> = {
    green: "border-gray-200 text-gray-500 hover:border-green-300 hover:text-green-600",
    red:   "border-gray-200 text-gray-500 hover:border-red-300 hover:text-red-600",
    amber: "border-gray-200 text-gray-500 hover:border-amber-300 hover:text-amber-600",
    blue:  "border-gray-200 text-gray-500 hover:border-blue-300 hover:text-blue-600",
  };
  return (
    <button type="button" onClick={onClick} disabled={disabled} title={title}
      className={`p-2 rounded-xl border transition-colors disabled:opacity-50 ${tones[tone]}`}>
      {children}
    </button>
  );
}
