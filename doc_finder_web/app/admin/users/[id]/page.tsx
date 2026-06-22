"use client";

import { useEffect, useState, use as usePromise } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import {
  Loader2, ArrowLeft, Pencil, Trash2, Power, CheckCircle2, XCircle, Clock,
  Shield, Stethoscope, User as UserIcon, FileText, Mail, Phone, MapPin, Calendar,
  ExternalLink,
} from "lucide-react";

interface UserDoc { id: number; document_path: string; document_type?: string | null; created_at?: string }
interface AdminUserDetail {
  id: number;
  name: string;
  email: string;
  telephone?: string | null;
  id_number?: string | null;
  address?: string | null;
  dob?: string | null;
  profile_image?: string | null;
  account_type: number;
  licence_number?: string | null;
  professional_bio?: string | null;
  is_active: number;
  sp_approved: number;
  created_at?: string;
  specializations?: { id: number; name: string }[];
  documents?: UserDoc[];
}

const ROLE_LABEL: Record<number, { label: string; cls: string; icon: React.ReactNode }> = {
  1: { label: "Standard", cls: "bg-gray-100 text-gray-700", icon: <UserIcon className="w-3.5 h-3.5" /> },
  2: { label: "Service Provider", cls: "bg-blue-100 text-blue-700", icon: <Stethoscope className="w-3.5 h-3.5" /> },
  3: { label: "Admin", cls: "bg-purple-100 text-purple-700", icon: <Shield className="w-3.5 h-3.5" /> },
};

function initials(name: string) {
  return name.split(" ").map(p => p[0]).filter(Boolean).slice(0, 2).join("").toUpperCase();
}

export default function AdminUserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const { id } = usePromise(params);
  const [user, setUser] = useState<AdminUserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);

  const load = () => {
    setLoading(true);
    api.get(`/admin/users/${id}`)
      .then(res => setUser(res.data?.data ?? null))
      .catch(() => toast.error("Failed to load user"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [id]);

  const act = async (kind: "approve" | "decline" | "toggle" | "delete") => {
    if (!user) return;
    setBusy(true);
    try {
      if (kind === "delete") {
        if (!confirm("Delete this user? This cannot be undone.")) { setBusy(false); return; }
        await api.delete(`/admin/users/${user.id}`);
        toast.success("User deleted");
        router.push("/admin/users");
        return;
      }
      const path =
        kind === "approve" ? `/admin/users/${user.id}/approve` :
        kind === "decline" ? `/admin/users/${user.id}/decline` :
                             `/admin/users/${user.id}/toggle-status`;
      const res = await api.patch(path);
      toast.success(res.data?.message || "Updated");
      setUser(prev => prev ? { ...prev, ...res.data?.data } : prev);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg || "Action failed");
    } finally {
      setBusy(false);
    }
  };

  const openDocument = async (docId: number) => {
    try {
      const res = await api.get(`/admin/user-documents/${docId}/url`);
      const url = res.data?.data?.url;
      if (!url) { toast.error("Document URL unavailable"); return; }
      window.open(url, "_blank", "noopener,noreferrer");
    } catch {
      toast.error("Could not open document");
    }
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex justify-center pt-40">
          <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
        </div>
      </main>
    );
  }

  if (!user) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="max-w-4xl mx-auto px-4 pt-28">
          <p className="text-center text-gray-500">User not found.</p>
        </div>
      </main>
    );
  }

  const role = ROLE_LABEL[user.account_type] ?? ROLE_LABEL[1];
  const isSP = user.account_type === 2;
  const isAdmin = user.account_type === 3;
  const isActive = Number(user.is_active) === 1;
  const sp = Number(user.sp_approved ?? 0);

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-4xl mx-auto px-4 pt-28 pb-16 space-y-6">
        <Link href="/admin/users" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-brand-600">
          <ArrowLeft className="w-4 h-4" /> Back to users
        </Link>

        {/* Profile card */}
        <div className="bg-white rounded-3xl border border-gray-100 p-6 sm:p-8 shadow-sm">
          <div className="flex flex-col sm:flex-row sm:items-start gap-6">
            <div className="w-20 h-20 rounded-2xl bg-brand-50 flex-shrink-0 overflow-hidden flex items-center justify-center text-brand-600 text-2xl font-bold">
              {user.profile_image
                ? <img src={getImageUrl(user.profile_image)} alt={user.name} className="w-full h-full object-cover" />
                : initials(user.name)}
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap mb-2">
                <h1 className="text-2xl font-bold text-gray-900">{user.name}</h1>
                <span className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full ${role.cls}`}>
                  {role.icon} {role.label}
                </span>
                <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${isActive ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"}`}>
                  {isActive ? "Active" : "Inactive"}
                </span>
                {isSP && (
                  <span className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full ${
                    sp === 1 ? "bg-green-100 text-green-700" :
                    sp === 3 ? "bg-red-100 text-red-700" :
                               "bg-yellow-100 text-yellow-700"
                  }`}>
                    {sp === 1 ? <CheckCircle2 className="w-3.5 h-3.5" /> : sp === 3 ? <XCircle className="w-3.5 h-3.5" /> : <Clock className="w-3.5 h-3.5" />}
                    {sp === 1 ? "Approved" : sp === 3 ? "Declined" : "Pending Approval"}
                  </span>
                )}
              </div>

              <ul className="text-sm text-gray-600 space-y-1.5">
                <li className="flex items-center gap-2"><Mail className="w-4 h-4 text-gray-400" /> {user.email}</li>
                {user.telephone && <li className="flex items-center gap-2"><Phone className="w-4 h-4 text-gray-400" /> {user.telephone}</li>}
                {user.address && <li className="flex items-center gap-2"><MapPin className="w-4 h-4 text-gray-400" /> {user.address}</li>}
                {user.dob && <li className="flex items-center gap-2"><Calendar className="w-4 h-4 text-gray-400" /> {new Date(user.dob).toLocaleDateString()}</li>}
                {user.id_number && <li className="text-xs text-gray-400">ID: {user.id_number}</li>}
              </ul>
            </div>
          </div>

          {/* Quick actions */}
          <div className="mt-6 pt-6 border-t border-gray-100 flex flex-wrap gap-2">
            {isSP && sp !== 1 && (
              <Btn onClick={() => act("approve")} disabled={busy} tone="green" icon={<CheckCircle2 className="w-4 h-4" />}>
                Approve
              </Btn>
            )}
            {isSP && sp !== 3 && (
              <Btn onClick={() => act("decline")} disabled={busy} tone="red" icon={<XCircle className="w-4 h-4" />}>
                Decline
              </Btn>
            )}
            <Btn onClick={() => act("toggle")} disabled={busy} tone={isActive ? "amber" : "green"} icon={<Power className="w-4 h-4" />}>
              {isActive ? "Deactivate" : "Activate"}
            </Btn>
            <Link href={`/admin/users/${user.id}/edit`}
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-bold rounded-xl border border-gray-200 text-gray-700 hover:bg-gray-50 transition-colors">
              <Pencil className="w-4 h-4" /> Edit
            </Link>
            {!isAdmin && (
              <Btn onClick={() => act("delete")} disabled={busy} tone="red" icon={<Trash2 className="w-4 h-4" />}>
                Delete
              </Btn>
            )}
          </div>
        </div>

        {/* Service provider details */}
        {isSP && (
          <div className="bg-white rounded-3xl border border-gray-100 p-6 sm:p-8 shadow-sm">
            <h2 className="text-base font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Stethoscope className="w-5 h-5 text-blue-500" /> Service Provider Details
            </h2>
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3 text-sm">
              <Dd label="Licence Number" value={user.licence_number} />
              <Dd label="Account Created" value={user.created_at ? new Date(user.created_at).toLocaleDateString() : null} />
              <div className="sm:col-span-2">
                <Dd label="Professional Bio" value={user.professional_bio} />
              </div>
              {!!user.specializations?.length && (
                <div className="sm:col-span-2">
                  <p className="text-xs font-bold text-gray-500 uppercase tracking-widest mb-1">Specializations</p>
                  <div className="flex flex-wrap gap-2 mt-1">
                    {user.specializations.map(s => (
                      <span key={s.id} className="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-50 text-blue-700">
                        {s.name}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </dl>
          </div>
        )}

        {/* Documents */}
        {!!user.documents?.length && (
          <div className="bg-white rounded-3xl border border-gray-100 p-6 sm:p-8 shadow-sm">
            <h2 className="text-base font-bold text-gray-900 mb-4 flex items-center gap-2">
              <FileText className="w-5 h-5 text-amber-500" /> Documents ({user.documents.length})
            </h2>
            <ul className="space-y-2">
              {user.documents.map(doc => (
                <li key={doc.id} className="flex items-center justify-between gap-3 p-3 rounded-xl border border-gray-100 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center gap-3 min-w-0">
                    <FileText className="w-5 h-5 text-amber-500 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-gray-800 truncate">{doc.document_type || "Document"}</p>
                      <p className="text-xs text-gray-400 truncate">{doc.document_path}</p>
                    </div>
                  </div>
                  <button onClick={() => openDocument(doc.id)}
                    className="inline-flex items-center gap-1 text-xs font-bold text-brand-600 hover:text-brand-700 px-3 py-1.5 rounded-lg hover:bg-brand-50 transition-colors flex-shrink-0">
                    Open <ExternalLink className="w-3.5 h-3.5" />
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </main>
  );
}

function Btn({ children, icon, onClick, disabled, tone }: {
  children: React.ReactNode; icon: React.ReactNode; onClick: () => void; disabled?: boolean;
  tone: "green" | "red" | "amber";
}) {
  const tones: Record<string, string> = {
    green: "bg-green-500 hover:bg-green-600 text-white",
    red:   "bg-red-500 hover:bg-red-600 text-white",
    amber: "bg-amber-500 hover:bg-amber-600 text-white",
  };
  return (
    <button onClick={onClick} disabled={disabled}
      className={`inline-flex items-center gap-2 px-4 py-2 text-sm font-bold rounded-xl shadow-sm transition-colors disabled:opacity-50 ${tones[tone]}`}>
      {icon} {children}
    </button>
  );
}

function Dd({ label, value }: { label: string; value?: string | null }) {
  return (
    <div>
      <dt className="text-xs font-bold text-gray-500 uppercase tracking-widest mb-0.5">{label}</dt>
      <dd className="text-sm text-gray-800">{value || <span className="text-gray-400">—</span>}</dd>
    </div>
  );
}
