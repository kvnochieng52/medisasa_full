"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter, useParams } from "next/navigation";
import Link from "next/link";
import { ChevronRight, Loader2, Upload, ShieldAlert, ChevronDown } from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";
import FacilityPicker from "@/components/admin/FacilityPicker";

interface Category { id: number; name: string }
interface SubCategory { id: number; name: string }

const DOSAGE_FORMS = ["Tablet", "Capsule", "Syrup", "Injection", "Cream", "Drops", "Powder", "Patch", "Other"];
const UNITS = ["pieces", "ml", "grams", "kg", "litres", "boxes", "strips", "vials"];
const STATUSES = [
  { value: "active", label: "Active" },
  { value: "discontinued", label: "Discontinued" },
  { value: "out_of_stock", label: "Out of Stock" },
];

export default function EditMedicalProductPage() {
  const router = useRouter();
  const { id } = useParams<{ id: string }>();
  const imageRef = useRef<HTMLInputElement>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [subcategories, setSubcategories] = useState<SubCategory[]>([]);
  const [loadingCats, setLoadingCats] = useState(true);
  const [loadingSubs, setLoadingSubs] = useState(false);
  const [pageLoading, setPageLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [existingImage, setExistingImage] = useState("");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState("");

  const [form, setForm] = useState({
    name: "", batch_no: "", description: "", cost: "", stock_quantity: "0",
    category_id: "", subcategory_id: "", facility_id: "", manufacturer: "",
    strength: "", dosage_form: "", manufacturing_date: "", expiry_date: "",
    storage_conditions: "", usage_instructions: "", barcode: "",
    weight: "", unit_of_measure: "pieces", minimum_stock_level: "10",
    supplier: "", purchase_price: "",
    needs_prescription: false, is_available: true, status: "active",
    side_effects: "", conditions: "", ingredients: "",
  });

  useEffect(() => {
    Promise.all([
      api.get<{ data: Category[] }>("/medical-product-categories"),
      api.get<{ data: Record<string, unknown> }>(`/medical-products/${id}`),
    ]).then(([catsRes, prodRes]) => {
      setCategories(catsRes.data.data ?? []);
      const p = prodRes.data.data as Record<string, unknown>;
      if (!p) return;

      setExistingImage(getImageUrl((p.image_url || p.photo) as string));
      const catId = p.category_id ? String(p.category_id) : "";
      const subId = p.subcategory_id ? String(p.subcategory_id) : "";
      const facId = p.facility_id != null ? String(p.facility_id) : "";

      const toStr = (v: unknown) => v ? String(v) : "";
      const toArr = (v: unknown): string => Array.isArray(v) ? v.join(", ") : toStr(v);

      setForm({
        name: toStr(p.name),
        batch_no: toStr(p.batch_no),
        description: toStr(p.description),
        cost: toStr(p.cost),
        stock_quantity: toStr(p.stock_quantity) || "0",
        category_id: catId,
        subcategory_id: subId,
        facility_id: facId,
        manufacturer: toStr(p.manufacturer),
        strength: toStr(p.strength),
        dosage_form: toStr(p.dosage_form),
        manufacturing_date: toStr(p.manufacturing_date),
        expiry_date: toStr(p.expiry_date),
        storage_conditions: toStr(p.storage_conditions),
        usage_instructions: toStr(p.usage_instructions),
        barcode: toStr(p.barcode),
        weight: toStr(p.weight),
        unit_of_measure: toStr(p.unit_of_measure) || "pieces",
        minimum_stock_level: toStr(p.minimum_stock_level) || "10",
        supplier: toStr(p.supplier),
        purchase_price: toStr(p.purchase_price),
        needs_prescription: !!p.needs_prescription,
        is_available: p.is_available !== false,
        status: toStr(p.status) || "active",
        side_effects: toArr(p.side_effects),
        conditions: toArr(p.conditions),
        ingredients: toArr(p.ingredients),
      });

      if (catId) {
        setLoadingSubs(true);
        api.get<{ data: SubCategory[] }>("/medical-product-subcategories", { params: { category_id: catId } })
          .then(r => setSubcategories(r.data.data ?? []))
          .finally(() => setLoadingSubs(false));
      }
    })
    .catch(() => toast.error("Failed to load product"))
    .finally(() => {
      setLoadingCats(false);
      setPageLoading(false);
    });
  }, [id]);

  const handleCategoryChange = (catId: string) => {
    setForm(f => ({ ...f, category_id: catId, subcategory_id: "" }));
    setSubcategories([]);
    if (!catId) return;
    setLoadingSubs(true);
    api.get<{ data: SubCategory[] }>("/medical-product-subcategories", { params: { category_id: catId } })
      .then(res => setSubcategories(res.data.data ?? []))
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
    if (!form.batch_no.trim()) { toast.error("Batch number is required"); return; }
    if (!form.cost) { toast.error("Cost is required"); return; }
    if (!form.category_id) { toast.error("Category is required"); return; }
    if (!form.facility_id) { toast.error("Facility is required"); return; }

    setSaving(true);
    try {
      const fd = new FormData();
      fd.append("_method", "PUT");
      const append = (k: string, v: string) => { if (v) fd.append(k, v); };

      fd.append("name", form.name.trim());
      fd.append("batch_no", form.batch_no.trim());
      fd.append("cost", form.cost);
      fd.append("category_id", form.category_id);
      fd.append("facility_id", form.facility_id);
      fd.append("stock_quantity", form.stock_quantity);
      fd.append("status", form.status);
      fd.append("unit_of_measure", form.unit_of_measure);
      fd.append("minimum_stock_level", form.minimum_stock_level || "10");
      fd.append("needs_prescription", form.needs_prescription ? "1" : "0");
      fd.append("is_available", form.is_available ? "1" : "0");
      append("subcategory_id", form.subcategory_id);
      append("description", form.description.trim());
      append("manufacturer", form.manufacturer.trim());
      append("strength", form.strength.trim());
      append("dosage_form", form.dosage_form);
      append("manufacturing_date", form.manufacturing_date);
      append("expiry_date", form.expiry_date);
      append("storage_conditions", form.storage_conditions.trim());
      append("usage_instructions", form.usage_instructions.trim());
      append("barcode", form.barcode.trim());
      append("weight", form.weight);
      append("supplier", form.supplier.trim());
      append("purchase_price", form.purchase_price);
      form.side_effects.split(",").map(s => s.trim()).filter(Boolean).forEach((s, i) => fd.append(`side_effects[${i}]`, s));
      form.conditions.split(",").map(s => s.trim()).filter(Boolean).forEach((s, i) => fd.append(`conditions[${i}]`, s));
      form.ingredients.split(",").map(s => s.trim()).filter(Boolean).forEach((s, i) => fd.append(`ingredients[${i}]`, s));
      if (imageFile) fd.append("photo", imageFile);

      await api.post(`/medical-products/${id}`, fd, { headers: { "Content-Type": "multipart/form-data" } });
      toast.success("Product updated!");
      router.push("/admin/pharmacy/products");
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const errors = e?.response?.data?.errors;
      if (errors) Object.values(errors).flat().forEach(m => toast.error(m));
      else toast.error(e?.response?.data?.message ?? "Failed to update product");
    } finally {
      setSaving(false);
    }
  };

  const imgSrc = imagePreview || existingImage;

  if (pageLoading) return (
    <main className="min-h-screen bg-gray-50 flex items-center justify-center">
      <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
    </main>
  );

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-2xl mx-auto px-4 pt-24 pb-16">

        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy" className="hover:text-brand-500">Pharmacy</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy/products" className="hover:text-brand-500">Products</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Edit</span>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-6">Edit Medical Product</h1>

        <form onSubmit={handleSubmit} className="space-y-6">

          <div className="flex justify-center">
            <div onClick={() => imageRef.current?.click()}
              className="relative w-28 h-28 rounded-2xl border-2 border-dashed border-purple-200 hover:border-purple-400 bg-purple-50 flex items-center justify-center cursor-pointer overflow-hidden transition-colors">
              {imgSrc
                ? <img src={imgSrc} alt="" className="w-full h-full object-cover" />
                : <div className="text-center"><Upload className="w-6 h-6 text-purple-400 mx-auto" /><p className="text-xs text-purple-400 mt-1">Photo</p></div>}
              {imgSrc && (
                <div className="absolute inset-0 bg-black/30 opacity-0 hover:opacity-100 flex items-center justify-center transition-opacity">
                  <Upload className="w-6 h-6 text-white" />
                </div>
              )}
            </div>
          </div>
          <input ref={imageRef} type="file" accept="image/*" className="hidden" onChange={handleImageChange} />

          <Section title="Basic Information">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Product Name" required>
                <input type="text" value={form.name} onChange={e => set("name", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Batch Number" required>
                <input type="text" value={form.batch_no} onChange={e => set("batch_no", e.target.value)} className={inputCls} />
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
                  <select value={form.category_id} onChange={e => handleCategoryChange(e.target.value)} disabled={loadingCats} className={selectCls}>
                    <option value="">{loadingCats ? "Loading…" : "Select category"}</option>
                    {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
              <Field label="Subcategory">
                <div className="relative">
                  <select value={form.subcategory_id} onChange={e => set("subcategory_id", e.target.value)} disabled={!form.category_id || loadingSubs} className={selectCls}>
                    <option value="">{loadingSubs ? "Loading…" : "None"}</option>
                    {subcategories.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Selling Price (KSh)" required>
                <input type="number" min="0" step="0.01" value={form.cost} onChange={e => set("cost", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Purchase Price (KSh)">
                <input type="number" min="0" step="0.01" value={form.purchase_price} onChange={e => set("purchase_price", e.target.value)} className={inputCls} />
              </Field>
            </div>
            <Field label="Description">
              <textarea rows={3} value={form.description} onChange={e => set("description", e.target.value)} className={`${inputCls} resize-none`} />
            </Field>
          </Section>

          <Section title="Stock & Inventory">
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <Field label="Stock Qty">
                <input type="number" min="0" value={form.stock_quantity} onChange={e => set("stock_quantity", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Min Stock">
                <input type="number" min="0" value={form.minimum_stock_level} onChange={e => set("minimum_stock_level", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Unit">
                <div className="relative">
                  <select value={form.unit_of_measure} onChange={e => set("unit_of_measure", e.target.value)} className={selectCls}>
                    {UNITS.map(u => <option key={u} value={u}>{u}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
              <Field label="Status">
                <div className="relative">
                  <select value={form.status} onChange={e => set("status", e.target.value)} className={selectCls}>
                    {STATUSES.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Supplier">
                <input type="text" value={form.supplier} onChange={e => set("supplier", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Barcode">
                <input type="text" value={form.barcode} onChange={e => set("barcode", e.target.value)} className={inputCls} />
              </Field>
            </div>
          </Section>

          <Section title="Product Details">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <Field label="Manufacturer">
                <input type="text" value={form.manufacturer} onChange={e => set("manufacturer", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Strength">
                <input type="text" value={form.strength} onChange={e => set("strength", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Dosage Form">
                <div className="relative">
                  <select value={form.dosage_form} onChange={e => set("dosage_form", e.target.value)} className={selectCls}>
                    <option value="">Select form</option>
                    {DOSAGE_FORMS.map(f => <option key={f} value={f.toLowerCase()}>{f}</option>)}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
              </Field>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Manufacturing Date">
                <input type="date" value={form.manufacturing_date} onChange={e => set("manufacturing_date", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Expiry Date">
                <input type="date" value={form.expiry_date} onChange={e => set("expiry_date", e.target.value)} className={inputCls} />
              </Field>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Weight (grams)">
                <input type="number" min="0" step="0.001" value={form.weight} onChange={e => set("weight", e.target.value)} className={inputCls} />
              </Field>
              <Field label="Storage Conditions">
                <input type="text" value={form.storage_conditions} onChange={e => set("storage_conditions", e.target.value)} className={inputCls} />
              </Field>
            </div>
            <Field label="Usage Instructions">
              <textarea rows={2} value={form.usage_instructions} onChange={e => set("usage_instructions", e.target.value)} className={`${inputCls} resize-none`} />
            </Field>
          </Section>

          <Section title="Clinical Information">
            <Field label="Conditions Treated" hint="Comma-separated">
              <input type="text" value={form.conditions} onChange={e => set("conditions", e.target.value)} className={inputCls} />
            </Field>
            <Field label="Side Effects" hint="Comma-separated">
              <input type="text" value={form.side_effects} onChange={e => set("side_effects", e.target.value)} className={inputCls} />
            </Field>
            <Field label="Ingredients" hint="Comma-separated">
              <input type="text" value={form.ingredients} onChange={e => set("ingredients", e.target.value)} className={inputCls} />
            </Field>
            <div className="flex flex-col sm:flex-row gap-3">
              <label className="flex items-center gap-3 flex-1 p-3 rounded-xl border border-gray-200 cursor-pointer hover:bg-gray-50">
                <input type="checkbox" checked={form.needs_prescription} onChange={e => set("needs_prescription", e.target.checked)} className="w-4 h-4 accent-amber-500" />
                <ShieldAlert className="w-4 h-4 text-amber-500" />
                <p className="text-sm font-semibold text-gray-800">Requires Prescription</p>
              </label>
              <label className="flex items-center gap-3 flex-1 p-3 rounded-xl border border-gray-200 cursor-pointer hover:bg-gray-50">
                <input type="checkbox" checked={form.is_available} onChange={e => set("is_available", e.target.checked)} className="w-4 h-4 accent-green-500" />
                <p className="text-sm font-semibold text-gray-800">Available for Purchase</p>
              </label>
            </div>
          </Section>

          <div className="flex gap-3">
            <Link href="/admin/pharmacy/products"
              className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 text-center hover:bg-gray-50">
              Cancel
            </Link>
            <button type="submit" disabled={saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white font-semibold text-sm shadow-sm">
              {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving…</> : "Save Changes"}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
      <h3 className="text-sm font-bold text-gray-700 uppercase tracking-wide">{title}</h3>
      {children}
    </div>
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
