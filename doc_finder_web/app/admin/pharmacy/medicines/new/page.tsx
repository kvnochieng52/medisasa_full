"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ChevronRight, Loader2, Upload, Pill, ChevronDown, ShieldAlert } from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";
import FacilityPicker from "@/components/admin/FacilityPicker";

interface Category { id: number; name: string }
interface SubCategory { id: number; name: string; category_id: number }

const DOSAGE_FORMS = ["Tablet", "Capsule", "Syrup", "Injection", "Cream", "Drops", "Powder", "Patch", "Other"];

export default function NewMedicinePage() {
  const router = useRouter();
  const imageRef = useRef<HTMLInputElement>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [subcategories, setSubcategories] = useState<SubCategory[]>([]);
  const [loadingCats, setLoadingCats] = useState(true);
  const [loadingSubs, setLoadingSubs] = useState(false);
  const [saving, setSaving] = useState(false);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState("");

  const [form, setForm] = useState({
    name: "", medicine_number: "", description: "", cost: "",
    category_id: "", subcategory_id: "", facility_id: "", manufacturer: "",
    strength: "", form: "", quantity_available: "0", conditions: "",
    requires_prescription: false,
  });

  useEffect(() => {
    api.get<{ categories: Category[] }>("/medicine-categories")
      .then(res => setCategories(res.data.categories ?? []))
      .catch(() => toast.error("Failed to load categories"))
      .finally(() => setLoadingCats(false));
  }, []);

  const handleCategoryChange = (catId: string) => {
    setForm(f => ({ ...f, category_id: catId, subcategory_id: "" }));
    setSubcategories([]);
    if (!catId) return;
    setLoadingSubs(true);
    api.get<{ subcategories: SubCategory[] }>(`/medicine-categories/${catId}/subcategories`)
      .then(res => setSubcategories(res.data.subcategories ?? []))
      .catch(() => {})
      .finally(() => setLoadingSubs(false));
  };

  const set = (k: keyof typeof form, v: unknown) => setForm(f => ({ ...f, [k]: v }));

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) { toast.error("Name is required"); return; }
    if (!form.medicine_number.trim()) { toast.error("Medicine number is required"); return; }
    if (!form.cost) { toast.error("Cost is required"); return; }
    if (!form.category_id) { toast.error("Category is required"); return; }
    if (!form.facility_id) { toast.error("Facility is required"); return; }

    setSaving(true);
    try {
      const fd = new FormData();
      fd.append("name", form.name.trim());
      fd.append("medicine_number", form.medicine_number.trim());
      fd.append("cost", form.cost);
      fd.append("category_id", form.category_id);
      fd.append("facility_id", form.facility_id);
      if (form.subcategory_id) fd.append("subcategory_id", form.subcategory_id);
      if (form.description.trim()) fd.append("description", form.description.trim());
      if (form.manufacturer.trim()) fd.append("manufacturer", form.manufacturer.trim());
      if (form.strength.trim()) fd.append("strength", form.strength.trim());
      if (form.form) fd.append("form", form.form);
      fd.append("quantity_available", form.quantity_available || "0");
      fd.append("requires_prescription", form.requires_prescription ? "1" : "0");
      // Conditions as indexed array
      form.conditions.split(",").map(c => c.trim()).filter(Boolean)
        .forEach((c, i) => fd.append(`conditions[${i}]`, c));
      if (imageFile) fd.append("image", imageFile);

      await api.post("/medicines", fd, { headers: { "Content-Type": "multipart/form-data" } });
      toast.success("Medicine added!");
      router.push("/admin/pharmacy/medicines");
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const errors = e?.response?.data?.errors;
      if (errors) Object.values(errors).flat().forEach(m => toast.error(m));
      else toast.error(e?.response?.data?.message ?? "Failed to save medicine");
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-2xl mx-auto px-4 pt-24 pb-16">

        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy" className="hover:text-brand-500">Pharmacy</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy/medicines" className="hover:text-brand-500">Medicines</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">New</span>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-6">Add Medicine</h1>

        <form onSubmit={handleSubmit} className="space-y-6">

          {/* Image */}
          <div className="flex justify-center">
            <div
              onClick={() => imageRef.current?.click()}
              className="relative w-28 h-28 rounded-2xl border-2 border-dashed border-brand-200 hover:border-brand-400 bg-brand-50 flex items-center justify-center cursor-pointer overflow-hidden transition-colors"
            >
              {imagePreview
                ? <img src={imagePreview} alt="" className="w-full h-full object-cover" />
                : <div className="text-center"><Upload className="w-6 h-6 text-brand-400 mx-auto" /><p className="text-xs text-brand-400 mt-1">Add Photo</p></div>}
              {imagePreview && (
                <div className="absolute inset-0 bg-black/30 opacity-0 hover:opacity-100 flex items-center justify-center transition-opacity">
                  <Upload className="w-6 h-6 text-white" />
                </div>
              )}
            </div>
          </div>
          <input ref={imageRef} type="file" accept="image/*" className="hidden" onChange={handleImageChange} />

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-5">

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Medicine Name" required>
                <input type="text" value={form.name} onChange={e => set("name", e.target.value)}
                  placeholder="e.g. Paracetamol" className={inputCls} />
              </Field>
              <Field label="Medicine Number" required>
                <input type="text" value={form.medicine_number} onChange={e => set("medicine_number", e.target.value)}
                  placeholder="e.g. PARA-001" className={inputCls} />
              </Field>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Price (KSh)" required>
                <input type="number" min="0" step="0.01" value={form.cost} onChange={e => set("cost", e.target.value)}
                  placeholder="0.00" className={inputCls} />
              </Field>
              <Field label="Qty Available">
                <input type="number" min="0" value={form.quantity_available} onChange={e => set("quantity_available", e.target.value)}
                  className={inputCls} />
              </Field>
            </div>

            <FacilityPicker
              value={form.facility_id}
              onChange={id => set("facility_id", id)}
              hint="Admins can pick any facility; providers can only pick their own."
            />

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Category" required>
                <div className="relative">
                  <select value={form.category_id} onChange={e => handleCategoryChange(e.target.value)}
                    disabled={loadingCats} className={selectCls}>
                    <option value="">{loadingCats ? "Loading…" : "Select category"}</option>
                    {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
              <Field label="Subcategory">
                <div className="relative">
                  <select value={form.subcategory_id} onChange={e => set("subcategory_id", e.target.value)}
                    disabled={!form.category_id || loadingSubs} className={selectCls}>
                    <option value="">{loadingSubs ? "Loading…" : "Select subcategory"}</option>
                    {subcategories.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <Field label="Manufacturer">
                <input type="text" value={form.manufacturer} onChange={e => set("manufacturer", e.target.value)}
                  placeholder="e.g. Bayer" className={inputCls} />
              </Field>
              <Field label="Strength">
                <input type="text" value={form.strength} onChange={e => set("strength", e.target.value)}
                  placeholder="e.g. 500mg" className={inputCls} />
              </Field>
              <Field label="Dosage Form">
                <div className="relative">
                  <select value={form.form} onChange={e => set("form", e.target.value)} className={selectCls}>
                    <option value="">Select form</option>
                    {DOSAGE_FORMS.map(f => <option key={f} value={f.toLowerCase()}>{f}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
            </div>

            <Field label="Conditions Treated" hint="Comma-separated">
              <input type="text" value={form.conditions} onChange={e => set("conditions", e.target.value)}
                placeholder="e.g. headache, fever, pain" className={inputCls} />
            </Field>

            <Field label="Description">
              <textarea rows={3} value={form.description} onChange={e => set("description", e.target.value)}
                placeholder="Brief description of this medicine…" className={`${inputCls} resize-none`} />
            </Field>

            <label className="flex items-center gap-3 p-3 rounded-xl border border-gray-200 cursor-pointer hover:bg-gray-50">
              <input type="checkbox" checked={form.requires_prescription}
                onChange={e => set("requires_prescription", e.target.checked)}
                className="w-4 h-4 accent-amber-500" />
              <ShieldAlert className="w-4 h-4 text-amber-500" />
              <div>
                <p className="text-sm font-semibold text-gray-800">Requires Prescription</p>
                <p className="text-xs text-gray-500">Customers must present a valid prescription</p>
              </div>
            </label>
          </div>

          <div className="flex gap-3">
            <Link href="/admin/pharmacy/medicines"
              className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 text-center hover:bg-gray-50">
              Cancel
            </Link>
            <button type="submit" disabled={saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white font-semibold text-sm shadow-sm">
              {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving…</> : <><Pill className="w-4 h-4" /> Add Medicine</>}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}

function Field({ label, required, hint, children }: { label: string; required?: boolean; hint?: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">
        {label} {required && <span className="text-red-500">*</span>}
        {hint && <span className="text-xs text-gray-400 font-normal ml-1">({hint})</span>}
      </label>
      {children}
    </div>
  );
}

const inputCls = "w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 bg-white";
const selectCls = "w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 appearance-none bg-white pr-10 disabled:bg-gray-50";
