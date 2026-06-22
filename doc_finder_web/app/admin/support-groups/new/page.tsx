"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  Users, MapPin, Tag, ChevronRight, Loader2, Upload,
  Globe, Lock, EyeOff, ChevronDown, X, CheckCircle,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Category {
  id: number;
  name: string;
  slug: string;
}

interface SubCategory {
  id: number;
  name: string;
  slug: string;
  category_id: number;
}

const PRIVACY_OPTIONS = [
  { value: "public",  label: "Public",  desc: "Anyone can see and join", icon: Globe,  color: "text-green-600" },
  { value: "private", label: "Private", desc: "Only members can see content", icon: Lock, color: "text-amber-600" },
  { value: "closed",  label: "Closed",  desc: "Invite only, completely private", icon: EyeOff, color: "text-red-600" },
] as const;

export default function NewSupportGroupPage() {
  const router = useRouter();
  const coverRef = useRef<HTMLInputElement>(null);
  const imageRef = useRef<HTMLInputElement>(null);

  const [categories, setCategories] = useState<Category[]>([]);
  const [subcategories, setSubcategories] = useState<SubCategory[]>([]);
  const [loadingCats, setLoadingCats] = useState(true);
  const [loadingSubs, setLoadingSubs] = useState(false);
  const [saving, setSaving] = useState(false);

  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState("");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState("");

  const [form, setForm] = useState({
    group_name: "",
    group_description: "",
    group_location: "",
    group_tags: "",
    group_privacy: "public" as "public" | "private" | "closed",
    require_approval: false,
    category_id: "",
    subcategory_ids: [] as number[],
  });

  useEffect(() => {
    api.get<{ success: boolean; data: Category[] }>("/group-categories")
      .then(res => setCategories(res.data.data ?? []))
      .catch(() => toast.error("Failed to load categories"))
      .finally(() => setLoadingCats(false));
  }, []);

  const handleCategoryChange = (catId: string) => {
    setForm(f => ({ ...f, category_id: catId, subcategory_ids: [] }));
    setSubcategories([]);
    if (!catId) return;
    setLoadingSubs(true);
    api.get<{ success: boolean; data: SubCategory[] }>("/group-subcategories", { params: { category_id: catId } })
      .then(res => setSubcategories(res.data.data ?? []))
      .catch(() => toast.error("Failed to load subcategories"))
      .finally(() => setLoadingSubs(false));
  };

  const toggleSub = (id: number) => {
    setForm(f => ({
      ...f,
      subcategory_ids: f.subcategory_ids.includes(id)
        ? f.subcategory_ids.filter(x => x !== id)
        : [...f.subcategory_ids, id],
    }));
  };

  const handleCoverChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCoverFile(file);
    setCoverPreview(URL.createObjectURL(file));
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.group_name.trim()) { toast.error("Group name is required"); return; }
    if (!form.group_description.trim()) { toast.error("Description is required"); return; }
    if (!form.group_location.trim()) { toast.error("Location is required"); return; }
    if (!form.category_id) { toast.error("Please select a category"); return; }
    if (form.subcategory_ids.length === 0) { toast.error("Select at least one subcategory"); return; }

    setSaving(true);
    try {
      const res = await api.post<{ success: boolean; group: { id: number } }>("/groups", {
        group_name: form.group_name.trim(),
        group_description: form.group_description.trim(),
        group_location: form.group_location.trim(),
        group_tags: form.group_tags.trim() || undefined,
        group_privacy: form.group_privacy,
        require_approval: form.require_approval,
        category_id: Number(form.category_id),
        subcategory_ids: form.subcategory_ids,
      });

      const groupId = res.data.group?.id;
      if (!groupId) throw new Error("No group ID returned");

      if (imageFile) {
        const fd = new FormData();
        fd.append("group_id", String(groupId));
        fd.append("group_image", imageFile);
        await api.post("/upload-group-image", fd, { headers: { "Content-Type": "multipart/form-data" } });
      }

      if (coverFile) {
        const fd = new FormData();
        fd.append("group_id", String(groupId));
        fd.append("cover_image", coverFile);
        await api.post("/upload-group-cover-image", fd, { headers: { "Content-Type": "multipart/form-data" } });
      }

      toast.success("Support group created!");
      router.push("/admin/support-groups");
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const errors = e?.response?.data?.errors;
      if (errors) {
        Object.values(errors).flat().forEach(msg => toast.error(msg));
      } else {
        toast.error(e?.response?.data?.message ?? "Failed to create group");
      }
    } finally {
      setSaving(false);
    }
  };

  const set = (k: keyof typeof form, v: unknown) => setForm(f => ({ ...f, [k]: v }));

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-2xl mx-auto px-4 pt-24 pb-16">

        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/support-groups" className="hover:text-brand-500">Support Groups</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">New Group</span>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-6">Create Support Group</h1>

        <form onSubmit={handleSubmit} className="space-y-6">

          {/* ── Cover Image ── */}
          <div
            className="relative h-40 rounded-2xl overflow-hidden bg-gradient-to-br from-brand-100 to-purple-100 cursor-pointer border-2 border-dashed border-brand-200 hover:border-brand-400 transition-colors"
            onClick={() => coverRef.current?.click()}
          >
            {coverPreview
              ? <img src={coverPreview} alt="" className="w-full h-full object-cover" />
              : (
                <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 text-brand-400">
                  <Upload className="w-7 h-7" />
                  <span className="text-sm font-medium">Upload Cover Image</span>
                  <span className="text-xs text-brand-300">Landscape · max 5MB</span>
                </div>
              )}
            {coverPreview && (
              <div className="absolute inset-0 bg-black/30 opacity-0 hover:opacity-100 transition-opacity flex items-center justify-center">
                <Upload className="w-7 h-7 text-white" />
              </div>
            )}

            {/* Group image overlay */}
            <div
              className="absolute bottom-3 left-4 w-16 h-16 rounded-xl border-2 border-white shadow-lg overflow-hidden bg-white cursor-pointer flex items-center justify-center"
              onClick={e => { e.stopPropagation(); imageRef.current?.click(); }}
            >
              {imagePreview
                ? <img src={imagePreview} alt="" className="w-full h-full object-cover" />
                : <Users className="w-7 h-7 text-gray-300" />}
            </div>
            <span className="absolute bottom-1 left-4 text-[10px] text-white/80 ml-1">Group icon</span>
          </div>
          <input ref={coverRef} type="file" accept="image/*" className="hidden" onChange={handleCoverChange} />
          <input ref={imageRef} type="file" accept="image/*" className="hidden" onChange={handleImageChange} />

          {/* ── Card ── */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-5">

            {/* Group Name */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Group Name <span className="text-red-500">*</span></label>
              <input
                type="text" value={form.group_name} maxLength={255}
                onChange={e => set("group_name", e.target.value)}
                placeholder="e.g. Diabetes Support Network"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300"
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Description <span className="text-red-500">*</span></label>
              <textarea
                rows={4} value={form.group_description}
                onChange={e => set("group_description", e.target.value)}
                placeholder="Describe the purpose and goals of this group…"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 resize-none"
              />
            </div>

            {/* Location */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <MapPin className="inline w-3.5 h-3.5 mr-1 text-gray-400" />
                Location <span className="text-red-500">*</span>
              </label>
              <input
                type="text" value={form.group_location} maxLength={255}
                onChange={e => set("group_location", e.target.value)}
                placeholder="e.g. Nairobi, Kenya"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300"
              />
            </div>

            {/* Tags */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                <Tag className="inline w-3.5 h-3.5 mr-1 text-gray-400" />
                Tags <span className="text-xs text-gray-400 font-normal">(comma-separated)</span>
              </label>
              <input
                type="text" value={form.group_tags} maxLength={500}
                onChange={e => set("group_tags", e.target.value)}
                placeholder="e.g. diabetes, mental health, chronic illness"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300"
              />
            </div>

            {/* Privacy */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Privacy <span className="text-red-500">*</span></label>
              <div className="space-y-2">
                {PRIVACY_OPTIONS.map(opt => {
                  const Icon = opt.icon;
                  return (
                    <label key={opt.value} className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-colors ${form.group_privacy === opt.value ? "border-brand-400 bg-brand-50" : "border-gray-200 hover:bg-gray-50"}`}>
                      <input type="radio" name="privacy" value={opt.value} checked={form.group_privacy === opt.value}
                        onChange={() => set("group_privacy", opt.value)} className="sr-only" />
                      <Icon className={`w-4 h-4 ${opt.color}`} />
                      <div className="flex-1">
                        <p className="text-sm font-semibold text-gray-800">{opt.label}</p>
                        <p className="text-xs text-gray-500">{opt.desc}</p>
                      </div>
                      {form.group_privacy === opt.value && <CheckCircle className="w-4 h-4 text-brand-500" />}
                    </label>
                  );
                })}
              </div>
            </div>

            {/* Require Approval */}
            <label className="flex items-center gap-3 p-3 rounded-xl border border-gray-200 cursor-pointer hover:bg-gray-50">
              <input type="checkbox" checked={form.require_approval}
                onChange={e => set("require_approval", e.target.checked)}
                className="w-4 h-4 rounded accent-brand-500" />
              <div>
                <p className="text-sm font-semibold text-gray-800">Require approval to join</p>
                <p className="text-xs text-gray-500">New members need admin approval before joining</p>
              </div>
            </label>

            {/* Category */}
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Category <span className="text-red-500">*</span></label>
              <div className="relative">
                <select
                  value={form.category_id}
                  onChange={e => handleCategoryChange(e.target.value)}
                  disabled={loadingCats}
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 appearance-none bg-white pr-10 disabled:bg-gray-50"
                >
                  <option value="">{loadingCats ? "Loading…" : "Select a category"}</option>
                  {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
              </div>
            </div>

            {/* Subcategories */}
            {form.category_id && (
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Subcategories <span className="text-red-500">*</span>
                  <span className="text-xs text-gray-400 font-normal ml-1">Select at least one</span>
                </label>
                {loadingSubs ? (
                  <div className="flex items-center gap-2 text-sm text-gray-400">
                    <Loader2 className="w-4 h-4 animate-spin" /> Loading subcategories…
                  </div>
                ) : subcategories.length === 0 ? (
                  <p className="text-sm text-gray-400">No subcategories for this category</p>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {subcategories.map(sub => {
                      const selected = form.subcategory_ids.includes(sub.id);
                      return (
                        <button key={sub.id} type="button" onClick={() => toggleSub(sub.id)}
                          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold border transition-colors ${selected ? "bg-brand-500 text-white border-brand-500" : "bg-white text-gray-600 border-gray-200 hover:border-brand-300"}`}>
                          {selected && <X className="w-3 h-3" />}
                          {sub.name}
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex gap-3">
            <Link href="/admin/support-groups"
              className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 text-center hover:bg-gray-50 transition-colors">
              Cancel
            </Link>
            <button type="submit" disabled={saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white font-semibold text-sm transition-colors shadow-sm">
              {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Creating…</> : "Create Group"}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
