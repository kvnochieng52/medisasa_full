"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  Scan, Plus, Trash2, Save, Loader2, ArrowLeft,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

type Urgency = "routine" | "urgent" | "stat";
type Contrast = "none" | "with" | "without" | "oral";

interface RadiologyItem {
  study_name: string;
  modality: string;
  body_part: string;
  side: string;
  contrast: Contrast;
  urgency: Urgency;
  clinical_indication: string;
  notes: string;
}

const emptyItem = (): RadiologyItem => ({
  study_name: "",
  modality: "",
  body_part: "",
  side: "",
  contrast: "none",
  urgency: "routine",
  clinical_indication: "",
  notes: "",
});

const MODALITIES = ["X-Ray", "CT", "MRI", "Ultrasound", "Mammogram", "PET", "DEXA", "Fluoroscopy"];

function NewRadiologyPrescriptionContent() {
  const router = useRouter();
  const params = useSearchParams();

  const [clinicName, setClinicName] = useState("");
  const [clinicAddress, setClinicAddress] = useState("");
  const [patientName, setPatientName] = useState(params.get("patient_name") ?? "");
  const [patientEmail, setPatientEmail] = useState(params.get("patient_email") ?? "");
  const [patientPhone, setPatientPhone] = useState(params.get("patient_phone") ?? "");
  const [patientDob, setPatientDob] = useState("");
  const [patientAge, setPatientAge] = useState("");
  const [patientSex, setPatientSex] = useState<"male" | "female" | "other" | "">("");
  const [clinicalInfo, setClinicalInfo] = useState("");
  const [notes, setNotes] = useState("");
  const [items, setItems] = useState<RadiologyItem[]>([emptyItem()]);
  const [submitting, setSubmitting] = useState(false);

  const appointmentId = params.get("appointment_id");

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) router.replace("/login");
  }, [router]);

  const updateItem = (i: number, field: keyof RadiologyItem, value: string) => {
    setItems((arr) => arr.map((it, idx) => (idx === i ? { ...it, [field]: value as never } : it)));
  };

  const removeItem = (i: number) => {
    if (items.length === 1) return;
    setItems((arr) => arr.filter((_, idx) => idx !== i));
  };

  const addItem = () => setItems((arr) => [...arr, emptyItem()]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!patientName.trim()) {
      toast.error("Patient name is required.");
      return;
    }
    if (items.some((i) => !i.study_name.trim())) {
      toast.error("Each study needs a name.");
      return;
    }

    setSubmitting(true);
    try {
      const res = await api.post("/prescriptions/radiology", {
        appointment_id: appointmentId ? Number(appointmentId) : null,
        clinic_name: clinicName.trim() || null,
        clinic_address: clinicAddress.trim() || null,
        patient_name: patientName.trim(),
        patient_email: patientEmail.trim() || null,
        patient_phone: patientPhone.trim() || null,
        patient_dob: patientDob || null,
        patient_age: patientAge ? Number(patientAge) : null,
        patient_sex: patientSex || null,
        clinical_information: clinicalInfo.trim() || null,
        notes: notes.trim() || null,
        items: items.map((i) => ({
          study_name: i.study_name.trim(),
          modality: i.modality.trim() || null,
          body_part: i.body_part.trim() || null,
          side: i.side.trim() || null,
          contrast: i.contrast,
          urgency: i.urgency,
          clinical_indication: i.clinical_indication.trim() || null,
          notes: i.notes.trim() || null,
        })),
      });
      const id = res.data?.data?.id;
      toast.success("Radiology order saved.");
      router.push(`/prescriptions/radiology/${id}`);
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = ax?.response?.data;
      const msg = data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? "Failed to save radiology order.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="bg-gradient-to-r from-pink-500 to-rose-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <Link
            href="/prescriptions"
            className="inline-flex items-center gap-1 text-white/90 hover:text-white text-sm mb-3"
          >
            <ArrowLeft className="w-4 h-4" /> Back to prescriptions
          </Link>
          <div className="flex items-center gap-3">
            <Scan className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">New Radiology Order</h1>
          </div>
          <p className="text-rose-50 text-sm mt-2">Order imaging studies for your patient. A PDF copy can be emailed once saved.</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="max-w-4xl mx-auto px-4 py-6 pb-16 space-y-5">
        <Section title="Clinic">
          <Grid2>
            <Field label="Clinic name" value={clinicName} onChange={setClinicName} placeholder="e.g. Karen Family Clinic" />
            <Field label="Clinic address" value={clinicAddress} onChange={setClinicAddress} placeholder="Street, town" />
          </Grid2>
        </Section>

        <Section title="Patient">
          <Grid2>
            <Field required label="Full name" value={patientName} onChange={setPatientName} placeholder="Jane Doe" />
            <Field label="Email" type="email" value={patientEmail} onChange={setPatientEmail} placeholder="jane@example.com" />
            <Field label="Phone" value={patientPhone} onChange={setPatientPhone} placeholder="+254…" />
            <Grid2 inner>
              <Field label="Date of birth" type="date" value={patientDob} onChange={setPatientDob} />
              <Field label="Age" type="number" value={patientAge} onChange={setPatientAge} placeholder="32" />
            </Grid2>
            <label className="block">
              <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Sex</span>
              <select
                value={patientSex}
                onChange={(e) => setPatientSex(e.target.value as typeof patientSex)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
              >
                <option value="">Not specified</option>
                <option value="female">Female</option>
                <option value="male">Male</option>
                <option value="other">Other</option>
              </select>
            </label>
          </Grid2>
        </Section>

        <Section title="Clinical information">
          <TextArea label="Reason / clinical info" value={clinicalInfo} onChange={setClinicalInfo} placeholder="e.g. R/O pneumonia, post-op follow-up…" />
        </Section>

        <Section
          title="Studies"
          right={
            <button type="button" onClick={addItem} className="inline-flex items-center gap-1 text-sm font-semibold text-rose-500 hover:text-rose-600">
              <Plus className="w-4 h-4" /> Add study
            </button>
          }
        >
          <div className="space-y-3">
            {items.map((it, i) => (
              <div key={i} className="border border-gray-100 rounded-2xl p-4 bg-gray-50/40 relative">
                <div className="absolute top-3 right-3">
                  <button
                    type="button"
                    onClick={() => removeItem(i)}
                    disabled={items.length === 1}
                    className="text-gray-400 hover:text-red-500 disabled:opacity-30 disabled:cursor-not-allowed"
                    aria-label="Remove study"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <div className="text-xs font-semibold text-gray-500 mb-2">#{i + 1}</div>
                <Grid2>
                  <Field
                    required
                    label="Study name"
                    value={it.study_name}
                    onChange={(v) => updateItem(i, "study_name", v)}
                    placeholder="e.g. Chest X-Ray PA/Lateral"
                  />
                  <label className="block">
                    <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Modality</span>
                    <select
                      value={it.modality}
                      onChange={(e) => updateItem(i, "modality", e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
                    >
                      <option value="">Select modality…</option>
                      {MODALITIES.map((m) => (
                        <option key={m} value={m}>{m}</option>
                      ))}
                    </select>
                  </label>
                  <Field label="Body part / region" value={it.body_part} onChange={(v) => updateItem(i, "body_part", v)} placeholder="Chest, abdomen, lumbar spine…" />
                  <label className="block">
                    <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Side</span>
                    <select
                      value={it.side}
                      onChange={(e) => updateItem(i, "side", e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
                    >
                      <option value="">Not specified</option>
                      <option value="left">Left</option>
                      <option value="right">Right</option>
                      <option value="bilateral">Bilateral</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Contrast</span>
                    <select
                      value={it.contrast}
                      onChange={(e) => updateItem(i, "contrast", e.target.value as Contrast)}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
                    >
                      <option value="none">No contrast</option>
                      <option value="with">With contrast</option>
                      <option value="without">Without contrast</option>
                      <option value="oral">Oral contrast</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Urgency</span>
                    <select
                      value={it.urgency}
                      onChange={(e) => updateItem(i, "urgency", e.target.value as Urgency)}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
                    >
                      <option value="routine">Routine</option>
                      <option value="urgent">Urgent</option>
                      <option value="stat">STAT</option>
                    </select>
                  </label>
                </Grid2>
                <div className="mt-3">
                  <TextArea label="Clinical indication" value={it.clinical_indication} onChange={(v) => updateItem(i, "clinical_indication", v)} placeholder="R/O pneumonia, back pain w/ neuro deficit, etc." rows={2} />
                </div>
                <div className="mt-3">
                  <TextArea label="Notes" value={it.notes} onChange={(v) => updateItem(i, "notes", v)} placeholder="Fasting, allergies, specific views…" rows={2} />
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section title="Additional notes">
          <TextArea label="Notes" value={notes} onChange={setNotes} placeholder="Anything else the radiologist or patient should know" />
        </Section>

        <div className="flex items-center justify-end gap-3 pt-2">
          <Link
            href="/prescriptions"
            className="px-5 py-3 rounded-xl border border-gray-200 hover:border-gray-300 text-sm font-semibold text-gray-700 bg-white transition-colors"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-rose-500 hover:bg-rose-600 disabled:bg-gray-300 text-white text-sm font-semibold transition-colors shadow-sm"
          >
            {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            {submitting ? "Saving…" : "Save radiology order"}
          </button>
        </div>
      </form>
    </main>
  );
}

function Section({ title, right, children }: { title: string; right?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="bg-white border border-gray-100 rounded-2xl shadow-sm p-5">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-sm font-bold text-gray-900 uppercase tracking-wide">{title}</h2>
        {right}
      </div>
      {children}
    </section>
  );
}

function Grid2({ children, inner = false }: { children: React.ReactNode; inner?: boolean }) {
  return <div className={`grid grid-cols-1 ${inner ? "sm:grid-cols-2 gap-3" : "sm:grid-cols-2 gap-4"}`}>{children}</div>;
}

function Field({
  label, value, onChange, type = "text", placeholder, required = false,
}: {
  label: string; value: string; onChange: (v: string) => void; type?: string; placeholder?: string; required?: boolean;
}) {
  return (
    <label className="block">
      <span className="text-xs font-semibold text-gray-600 mb-1.5 block">
        {label} {required && <span className="text-red-500">*</span>}
      </span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all"
      />
    </label>
  );
}

function TextArea({
  label, value, onChange, placeholder, rows = 3,
}: { label: string; value: string; onChange: (v: string) => void; placeholder?: string; rows?: number }) {
  return (
    <label className="block">
      <span className="text-xs font-semibold text-gray-600 mb-1.5 block">{label}</span>
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-rose-400 focus:ring-2 focus:ring-rose-100 transition-all resize-none"
      />
    </label>
  );
}

export default function NewRadiologyPrescriptionPage() {
  return (
    <Suspense>
      <NewRadiologyPrescriptionContent />
    </Suspense>
  );
}
