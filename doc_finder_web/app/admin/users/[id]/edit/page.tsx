"use client";

import { useEffect, useState, use as usePromise } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import api from "@/lib/api";
import toast from "react-hot-toast";
import { Loader2, ArrowLeft, Save } from "lucide-react";
import UserForm, { UserFormValues } from "../../user-form";

interface SpecRef { id: number; name: string }
interface UserDetail extends UserFormValues {
  id: number;
  specializations?: SpecRef[];
}

export default function EditAdminUserPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const { id } = usePromise(params);

  const [user, setUser] = useState<UserDetail | null>(null);
  const [specs, setSpecs] = useState<SpecRef[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    Promise.all([
      api.get(`/admin/users/${id}`),
      api.get(`/admin/users/specializations`),
    ])
      .then(([uRes, sRes]) => {
        const u = uRes.data?.data ?? null;
        setUser(u);
        setSpecs(Array.isArray(sRes.data?.data) ? sRes.data.data : []);
      })
      .catch(() => toast.error("Failed to load user"))
      .finally(() => setLoading(false));
  }, [id]);

  const submit = async (values: UserFormValues) => {
    setSaving(true);
    try {
      await api.put(`/admin/users/${id}`, values);
      toast.success("User updated");
      router.push(`/admin/users/${id}`);
    } catch (err: unknown) {
      const errors = (err as { response?: { data?: { errors?: Record<string, string[]> } } })?.response?.data?.errors;
      if (errors) {
        Object.values(errors).flat().slice(0, 3).forEach(m => toast.error(m as string));
      } else {
        toast.error("Failed to update user");
      }
    } finally {
      setSaving(false);
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
        <div className="max-w-3xl mx-auto px-4 pt-28">
          <p className="text-center text-gray-500">User not found.</p>
        </div>
      </main>
    );
  }

  const initial: UserFormValues = {
    name: user.name,
    email: user.email,
    telephone: user.telephone ?? "",
    id_number: user.id_number ?? "",
    address: user.address ?? "",
    dob: user.dob ? String(user.dob).substring(0, 10) : "",
    account_type: Number(user.account_type),
    licence_number: user.licence_number ?? "",
    professional_bio: user.professional_bio ?? "",
    specializations: (user.specializations ?? []).map(s => s.id),
    is_active: Number(user.is_active) === 1,
    sp_approved: Number(user.sp_approved ?? 0),
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-3xl mx-auto px-4 pt-28 pb-16">
        <Link href={`/admin/users/${id}`} className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-brand-600 mb-4">
          <ArrowLeft className="w-4 h-4" /> Back to user
        </Link>

        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-2xl bg-blue-500 flex items-center justify-center">
            <Save className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">Edit User</h1>
            <p className="text-sm text-gray-400">{user.name} · {user.email}</p>
          </div>
        </div>

        <UserForm
          initial={initial}
          specs={specs}
          mode="edit"
          onSubmit={submit}
          submitting={saving}
          submitLabel={saving ? "Saving…" : "Save Changes"}
          submitIcon={saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
        />
      </div>
    </main>
  );
}
