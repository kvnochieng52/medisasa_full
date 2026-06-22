"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import api from "@/lib/api";
import toast from "react-hot-toast";
import { Loader2, ArrowLeft, UserPlus } from "lucide-react";
import UserForm, { UserFormValues } from "../user-form";

export default function NewAdminUserPage() {
  const router = useRouter();
  const [specs, setSpecs] = useState<{ id: number; name: string }[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.get("/admin/users/specializations")
      .then(res => setSpecs(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setSpecs([]));
  }, []);

  const submit = async (values: UserFormValues) => {
    if (!values.password) { toast.error("Password is required"); return; }
    setSaving(true);
    try {
      await api.post("/admin/users", values);
      toast.success("User created");
      router.push("/admin/users");
    } catch (err: unknown) {
      const errors = (err as { response?: { data?: { errors?: Record<string, string[]> } } })?.response?.data?.errors;
      if (errors) {
        Object.values(errors).flat().slice(0, 3).forEach(m => toast.error(m as string));
      } else {
        toast.error("Failed to create user");
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-3xl mx-auto px-4 pt-28 pb-16">
        <Link href="/admin/users" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-brand-600 mb-4">
          <ArrowLeft className="w-4 h-4" /> Back to users
        </Link>

        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-2xl bg-brand-500 flex items-center justify-center">
            <UserPlus className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">Create User</h1>
            <p className="text-sm text-gray-400">Add an admin, service provider, or standard account</p>
          </div>
        </div>

        <UserForm
          initial={{ name: "", email: "", password: "", account_type: 1, is_active: true, sp_approved: 0, specializations: [] }}
          specs={specs}
          mode="create"
          onSubmit={submit}
          submitting={saving}
          submitLabel={saving ? "Creating…" : "Create User"}
          submitIcon={saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <UserPlus className="w-4 h-4" />}
        />
      </div>
    </main>
  );
}
