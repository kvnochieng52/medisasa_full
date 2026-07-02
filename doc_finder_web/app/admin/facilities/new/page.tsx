"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  Building2, Mail, Phone, MapPin, Globe, FileText,
  Upload, X, ChevronRight, Loader2, CheckCircle, Plus, Trash2,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Option { id: number; name: string }
interface FacilityServiceRef { id: number; name: string; description?: string | null }

interface ServiceRow {
  facility_service_id: number | null; // null → custom service
  title: string;
  description: string;
  amount: string; // kept as string in the form for input flexibility
}

interface FormState {
  facility_name: string;
  facility_profile: string;
  facility_email: string;
  facility_phone: string;
  facility_location: string;
  facility_website: string;
  facility_type_id: string;
  facility_level_id: string;
  accepts_insurance: boolean;
  insurance_ids: number[];
  services: ServiceRow[];
}

export default function NewFacilityPage() {
  const router = useRouter();
  const logoRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  const [saving, setSaving] = useState(false);
  const [facilityTypes, setFacilityTypes] = useState<Option[]>([]);
  const [facilityLevels, setFacilityLevels] = useState<Option[]>([]);
  const [insurances, setInsurances] = useState<Option[]>([]);
  const [facilityServices, setFacilityServices] = useState<FacilityServiceRef[]>([]);
  const [showInsuranceModal, setShowInsuranceModal] = useState(false);
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState("");
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState("");

  const [form, setForm] = useState<FormState>({
    facility_name: "",
    facility_profile: "",
    facility_email: "",
    facility_phone: "",
    facility_location: "",
    facility_website: "",
    facility_type_id: "",
    facility_level_id: "",
    accepts_insurance: false,
    insurance_ids: [],
    services: [],
  });

  const set = (k: keyof FormState, v: unknown) =>
    setForm(p => ({ ...p, [k]: v }));

  useEffect(() => {
    Promise.all([
      api.get<{ data: Option[] }>("/facility-types"),
      api.get<{ data: Option[] }>("/facility-levels"),
      api.get<{ data: Option[] }>("/insurances"),
      api.get<{ data: FacilityServiceRef[] }>("/facility-services"),
    ]).then(([types, levels, ins, svcs]) => {
      setFacilityTypes(types.data.data ?? []);
      setFacilityLevels(levels.data.data ?? []);
      setInsurances(ins.data.data ?? []);
      setFacilityServices(svcs.data.data ?? []);
    }).catch(() => toast.error("Failed to load form options"));
  }, []);

  const validate = () => {
    if (!form.facility_name.trim()) { toast.error("Facility name is required"); return false; }
    if (!form.facility_profile.trim()) { toast.error("Facility description is required"); return false; }
    if (!form.facility_email.trim()) { toast.error("Email is required"); return false; }
    if (!form.facility_phone.trim()) { toast.error("Phone number is required"); return false; }
    if (!form.facility_location.trim()) { toast.error("Location is required"); return false; }
    if (form.services.some(s => !s.title.trim())) { toast.error("Each service needs a title"); return false; }
    return true;
  };

  // ── Services helpers ─────────────────────────────────────────────────
  const addServiceFromCatalogue = (svcId: number) => {
    if (form.services.some(s => s.facility_service_id === svcId)) return;
    const ref = facilityServices.find(s => s.id === svcId);
    if (!ref) return;
    set("services", [
      ...form.services,
      { facility_service_id: svcId, title: ref.name, description: ref.description ?? "", amount: "" },
    ]);
  };
  const addCustomService = () => {
    set("services", [...form.services, { facility_service_id: null, title: "", description: "", amount: "" }]);
  };
  const updateService = (idx: number, patch: Partial<ServiceRow>) => {
    set("services", form.services.map((s, i) => i === idx ? { ...s, ...patch } : s));
  };
  const removeService = (idx: number) => {
    set("services", form.services.filter((_, i) => i !== idx));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setSaving(true);
    try {
      // 1. Create facility (including services in one call)
      const payload: Record<string, unknown> = {
        facility_name: form.facility_name.trim(),
        facility_profile: form.facility_profile.trim(),
        facility_email: form.facility_email.trim(),
        facility_phone: form.facility_phone.trim(),
        facility_location: form.facility_location.trim(),
        services: form.services.map(s => ({
          facility_service_id: s.facility_service_id,
          title: s.title.trim(),
          description: s.description.trim() || null,
          amount: s.amount.trim() === "" ? null : Number(s.amount),
        })),
      };
      if (form.facility_website.trim()) payload.facility_website = form.facility_website.trim();
      if (form.facility_type_id) payload.facility_type_id = Number(form.facility_type_id);
      if (form.facility_level_id) payload.facility_level_id = Number(form.facility_level_id);
      if (form.accepts_insurance) payload.insurance_ids = form.insurance_ids;

      const res = await api.post<{ facility: { id: number } }>("/save-facility", payload);
      const facilityId = res.data.facility?.id;
      if (!facilityId) throw new Error("No facility ID returned");

      // 2. Upload logo
      if (logoFile) {
        const fd = new FormData();
        fd.append("facility_id", String(facilityId));
        fd.append("logo", logoFile);
        await api.post("/upload-facility-logo", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      // 3. Upload cover image
      if (coverFile) {
        const fd = new FormData();
        fd.append("facility_id", String(facilityId));
        fd.append("cover_image", coverFile);
        await api.post("/upload-facility-cover-image", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      toast.success("Facility created successfully!");
      router.push("/admin/facilities");
    } catch (err: unknown) {
      const e = err as { response?: { status?: number; data?: { message?: string; upgrade_required?: boolean } } };
      if (e?.response?.status === 403 && e?.response?.data?.upgrade_required) {
        toast.error(e.response.data.message ?? "A subscription is required to create facilities.");
        router.push("/subscription");
        return;
      }
      toast.error(e?.response?.data?.message ?? "Failed to create facility");
    } finally {
      setSaving(false);
    }
  };

  const selectedTypeSlug = facilityTypes.find(t => String(t.id) === form.facility_type_id)?.name?.toLowerCase() ?? "";
  const showLevel = selectedTypeSlug.includes("hospital");

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-3xl mx-auto px-4 sm:px-6 pt-28 pb-16">

        {/* Breadcrumb + header */}
        <div className="mb-8">
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-1">
            <Link href="/dashboard" className="hover:text-brand-500 transition-colors">Dashboard</Link>
            <ChevronRight className="w-3.5 h-3.5" />
            <Link href="/admin/facilities" className="hover:text-brand-500 transition-colors">Facilities</Link>
            <ChevronRight className="w-3.5 h-3.5" />
            <span className="text-gray-700 font-medium">New Facility</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Add New Facility</h1>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">

          {/* ─── Cover & Logo Images ─── */}
          <div className="bg-white rounded-2xl shadow-card overflow-hidden">
            {/* Cover */}
            <div
              onClick={() => coverRef.current?.click()}
              className="relative h-40 bg-gradient-to-br from-brand-50 to-brand-100 cursor-pointer group flex items-center justify-center overflow-hidden"
            >
              {coverPreview
                ? <img src={coverPreview} alt="" className="w-full h-full object-cover" /> // eslint-disable-line @next/next/no-img-element
                : (
                  <div className="text-center opacity-60 group-hover:opacity-100 transition-opacity">
                    <Upload className="w-6 h-6 text-brand-500 mx-auto mb-1" />
                    <p className="text-xs font-medium text-brand-600">Upload Cover Image</p>
                    <p className="text-xs text-brand-400">Max 5 MB</p>
                  </div>
                )}
              <input ref={coverRef} type="file" accept="image/*" className="hidden"
                onChange={e => {
                  const f = e.target.files?.[0];
                  if (f) { setCoverFile(f); setCoverPreview(URL.createObjectURL(f)); }
                }}
              />
            </div>

            {/* Logo */}
            <div className="px-5 pb-5 pt-3 flex items-end gap-4">
              <div
                onClick={() => logoRef.current?.click()}
                className="relative -mt-10 w-20 h-20 rounded-xl border-4 border-white shadow bg-gray-100 cursor-pointer overflow-hidden flex items-center justify-center flex-shrink-0 hover:ring-2 hover:ring-brand-300 transition-all"
              >
                {logoPreview
                  ? <img src={logoPreview} alt="" className="w-full h-full object-cover" /> // eslint-disable-line @next/next/no-img-element
                  : <Building2 className="w-8 h-8 text-gray-300" />}
                <input ref={logoRef} type="file" accept="image/*" className="hidden"
                  onChange={e => {
                    const f = e.target.files?.[0];
                    if (f) { setLogoFile(f); setLogoPreview(URL.createObjectURL(f)); }
                  }}
                />
              </div>
              <div>
                <p className="text-xs font-semibold text-gray-700">Logo & Cover</p>
                <p className="text-xs text-gray-400">Click each area to upload (optional)</p>
              </div>
              {(logoPreview || coverPreview) && (
                <button type="button" onClick={() => { setLogoFile(null); setLogoPreview(""); setCoverFile(null); setCoverPreview(""); }}
                  className="ml-auto text-xs text-red-400 hover:text-red-600 flex items-center gap-1">
                  <X className="w-3 h-3" /> Clear
                </button>
              )}
            </div>
          </div>

          {/* ─── Basic Info ─── */}
          <Section title="Basic Information">
            <Field label="Facility Name" required>
              <InputBox icon={<Building2 className="w-4 h-4" />} value={form.facility_name}
                onChange={v => set("facility_name", v)} placeholder="e.g. Nairobi General Hospital" />
            </Field>

            <Field label="Description" required>
              <textarea value={form.facility_profile} onChange={e => set("facility_profile", e.target.value)}
                rows={3} placeholder="Brief description of services offered…"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 resize-none transition-all" />
            </Field>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Facility Type">
                <select value={form.facility_type_id} onChange={e => set("facility_type_id", e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 transition-all">
                  <option value="">Select type…</option>
                  {facilityTypes.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
                </select>
              </Field>

              {showLevel && (
                <Field label="Hospital Level">
                  <select value={form.facility_level_id} onChange={e => set("facility_level_id", e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 transition-all">
                    <option value="">Select level…</option>
                    {facilityLevels.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}
                  </select>
                </Field>
              )}
            </div>
          </Section>

          {/* ─── Contact ─── */}
          <Section title="Contact Details">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Field label="Email" required>
                <InputBox icon={<Mail className="w-4 h-4" />} type="email" value={form.facility_email}
                  onChange={v => set("facility_email", v)} placeholder="clinic@example.com" />
              </Field>
              <Field label="Phone" required>
                <InputBox icon={<Phone className="w-4 h-4" />} type="tel" value={form.facility_phone}
                  onChange={v => set("facility_phone", v)} placeholder="+254 700 000 000" />
              </Field>
            </div>
            <Field label="Location / Address" required>
              <InputBox icon={<MapPin className="w-4 h-4" />} value={form.facility_location}
                onChange={v => set("facility_location", v)} placeholder="123 Hospital Rd, Nairobi" />
            </Field>
            <Field label="Website">
              <InputBox icon={<Globe className="w-4 h-4" />} type="url" value={form.facility_website}
                onChange={v => set("facility_website", v)} placeholder="https://example.com" />
            </Field>
          </Section>

          {/* ─── Services offered ─── */}
          <Section title="Services Offered">
            <p className="text-xs text-gray-500 -mt-2">
              Pick services from the catalogue or add your own. Each service can have a description and a price.
            </p>

            {/* Add from catalogue */}
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Add from catalogue</label>
              <select
                value=""
                onChange={e => { if (e.target.value) addServiceFromCatalogue(Number(e.target.value)); }}
                className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 transition-all"
              >
                <option value="">Choose a service to add…</option>
                {facilityServices
                  .filter(s => !form.services.some(fs => fs.facility_service_id === s.id))
                  .map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
              <button type="button" onClick={addCustomService}
                className="mt-2 inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700">
                <Plus className="w-4 h-4" /> Add custom service
              </button>
            </div>

            {form.services.length === 0 ? (
              <p className="text-xs text-gray-400 italic">No services added yet.</p>
            ) : (
              <div className="space-y-3">
                {form.services.map((svc, idx) => (
                  <div key={idx} className="p-4 rounded-xl border border-gray-100 bg-gray-50/60">
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="flex-1">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          svc.facility_service_id ? "bg-brand-50 text-brand-700" : "bg-amber-50 text-amber-700"
                        }`}>
                          {svc.facility_service_id ? "Catalogue" : "Custom"}
                        </span>
                      </div>
                      <button type="button" onClick={() => removeService(idx)}
                        className="text-gray-400 hover:text-red-500" aria-label="Remove service">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div className="sm:col-span-2">
                        <label className="block text-xs font-semibold text-gray-600 mb-1">
                          Title <span className="text-red-400">*</span>
                        </label>
                        <input type="text" value={svc.title}
                          onChange={e => updateService(idx, { title: e.target.value })}
                          placeholder="e.g. General Consultation"
                          className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-white text-sm outline-none focus:border-brand-400" />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-gray-600 mb-1">Amount (KES)</label>
                        <input type="number" step="0.01" min="0" value={svc.amount}
                          onChange={e => updateService(idx, { amount: e.target.value })}
                          placeholder="e.g. 1500"
                          className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-white text-sm outline-none focus:border-brand-400" />
                      </div>
                    </div>

                    <div className="mt-3">
                      <label className="block text-xs font-semibold text-gray-600 mb-1">Description (optional)</label>
                      <textarea rows={2} value={svc.description}
                        onChange={e => updateService(idx, { description: e.target.value })}
                        placeholder="Optional notes for patients"
                        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-white text-sm outline-none focus:border-brand-400 resize-none" />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Section>

          {/* ─── Insurance ─── */}
          <Section title="Insurance">
            <label className="flex items-center gap-3 cursor-pointer select-none">
              <div
                onClick={() => set("accepts_insurance", !form.accepts_insurance)}
                className={`w-11 h-6 rounded-full transition-colors flex-shrink-0 ${form.accepts_insurance ? "bg-brand-500" : "bg-gray-200"}`}
              >
                <div className={`w-5 h-5 bg-white rounded-full shadow mt-0.5 transition-transform ${form.accepts_insurance ? "translate-x-5.5" : "translate-x-0.5"}`} />
              </div>
              <span className="text-sm font-medium text-gray-700">Accepts Insurance</span>
            </label>

            {form.accepts_insurance && (
              <div className="mt-3">
                <button type="button" onClick={() => setShowInsuranceModal(true)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-left flex items-center justify-between hover:border-brand-400 transition-colors">
                  <span className={form.insurance_ids.length > 0 ? "text-gray-700" : "text-gray-400"}>
                    {form.insurance_ids.length > 0
                      ? `${form.insurance_ids.length} insurer${form.insurance_ids.length > 1 ? "s" : ""} selected`
                      : "Select accepted insurers…"}
                  </span>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </button>
                {form.insurance_ids.length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-2">
                    {form.insurance_ids.map(id => {
                      const ins = insurances.find(x => x.id === id);
                      return ins ? (
                        <span key={id} className="inline-flex items-center gap-1 px-2.5 py-1 bg-green-50 text-green-700 text-xs rounded-full font-medium">
                          {ins.name}
                          <button type="button" onClick={() => set("insurance_ids", form.insurance_ids.filter(i => i !== id))}>
                            <X className="w-3 h-3" />
                          </button>
                        </span>
                      ) : null;
                    })}
                  </div>
                )}
              </div>
            )}
          </Section>

          {/* Submit */}
          <div className="flex gap-3 pt-2">
            <Link href="/admin/facilities"
              className="flex-1 text-center py-3.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
              Cancel
            </Link>
            <button type="submit" disabled={saving}
              className="flex-1 py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm">
              {saving
                ? <><Loader2 className="w-4 h-4 animate-spin" /> Creating…</>
                : <><Plus className="w-4 h-4" /> Create Facility</>}
            </button>
          </div>
        </form>
      </div>

      {/* ─── Insurance Modal ─── */}
      <SelectionModal
        open={showInsuranceModal}
        title="Select Insurers"
        onClose={() => setShowInsuranceModal(false)}
        items={insurances}
        selected={form.insurance_ids}
        onToggle={id => set("insurance_ids",
          form.insurance_ids.includes(id)
            ? form.insurance_ids.filter(i => i !== id)
            : [...form.insurance_ids, id]
        )}
        onClear={() => set("insurance_ids", [])}
      />
    </main>
  );
}

/* ─── Helper components ─── */

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-2xl shadow-card p-6 space-y-4">
      <h2 className="text-sm font-bold text-gray-700 uppercase tracking-wide">{title}</h2>
      {children}
    </div>
  );
}

function Field({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">
        {label}{required && <span className="text-red-400 ml-0.5">*</span>}
      </label>
      {children}
    </div>
  );
}

function InputBox({ icon, value, onChange, placeholder, type = "text" }: {
  icon: React.ReactNode;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
}) {
  return (
    <div className="relative">
      <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400">{icon}</div>
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        className="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 transition-all" />
    </div>
  );
}

function SelectionModal({ open, title, onClose, items, selected, onToggle, onClear }: {
  open: boolean;
  title: string;
  onClose: () => void;
  items: { id: number; name: string }[];
  selected: number[];
  onToggle: (id: number) => void;
  onClear: () => void;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
      <div className="bg-white rounded-3xl w-full max-w-md max-h-[80vh] flex flex-col shadow-2xl">
        <div className="flex items-center justify-between p-5 border-b">
          <h3 className="font-bold text-gray-800">{title}</h3>
          <button type="button" onClick={onClose}><X className="w-5 h-5 text-gray-400" /></button>
        </div>
        <div className="overflow-y-auto flex-1 p-4 space-y-2">
          {items.length === 0 && <p className="text-sm text-gray-400 text-center py-8">No options available</p>}
          {items.map(item => {
            const sel = selected.includes(item.id);
            return (
              <button key={item.id} type="button" onClick={() => onToggle(item.id)}
                className={`w-full flex items-center gap-3 p-3 rounded-xl border text-left transition-all ${sel ? "border-brand-400 bg-brand-50" : "border-gray-200 hover:border-gray-300"}`}>
                <div className={`w-5 h-5 rounded flex items-center justify-center border-2 flex-shrink-0 ${sel ? "border-brand-500 bg-brand-500" : "border-gray-300"}`}>
                  {sel && <CheckCircle className="w-3 h-3 text-white" />}
                </div>
                <span className={`text-sm font-medium ${sel ? "text-brand-700" : "text-gray-700"}`}>{item.name}</span>
              </button>
            );
          })}
        </div>
        <div className="p-4 border-t flex gap-3">
          <button type="button" onClick={onClear}
            className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm text-gray-600 font-semibold hover:bg-gray-50">
            Clear All
          </button>
          <button type="button" onClick={onClose}
            className="flex-1 py-2.5 rounded-xl bg-brand-500 text-white text-sm font-semibold hover:bg-brand-600">
            Done ({selected.length})
          </button>
        </div>
      </div>
    </div>
  );
}
