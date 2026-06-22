"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  FlaskConical, Plus, Trash2, Save, Loader2, ArrowLeft,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

type Urgency = "routine" | "urgent" | "stat";

interface LabItem {
  test_name: string;
  specimen_type: string;
  urgency: Urgency;
  notes: string;
}

const emptyItem = (): LabItem => ({
  test_name: "",
  specimen_type: "",
  urgency: "routine",
  notes: "",
});

function NewLabPrescriptionContent() {
  const router = useRouter();
  const params = useSearchParams();

  const [clinicName, setClinicName] = useState("");
  const [clinicAddress, setClinicAddress] = useState("");
  const [patientName, setPatientName] = useState(params.get("patient_name") ?? "");
  const [patientEmail, setPatientEmail] = useState(params.get("patient_email") ?? "");
  const [patientPhone, setPatientPhone] = useState(params.get("patient_phone") ?? "");
  const [patientDob, setPatientDob] = useState("");
  const [patientAge, setPatientAge] = useState("");
  const [clinicalInfo, setClinicalInfo] = useState("");
  const [notes, setNotes] = useState("");
  const [items, setItems] = useState<LabItem[]>([emptyItem()]);
  const [submitting, setSubmitting] = useState(false);

  const appointmentId = params.get("appointment_id");

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) router.replace("/login");
  }, [router]);

  const updateItem = (i: number, field: keyof LabItem, value: string) => {
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
    if (items.some((i) => !i.test_name.trim())) {
      toast.error("Each row needs a test name.");
      return;
    }

    setSubmitting(true);
    try {
      const res = await api.post("/prescriptions/lab", {
        appointment_id: appointmentId ? Number(appointmentId) : null,
        clinic_name: clinicName.trim() || null,
        clinic_address: clinicAddress.trim() || null,
        patient_name: patientName.trim(),
        patient_email: patientEmail.trim() || null,
        patient_phone: patientPhone.trim() || null,
        patient_dob: patientDob || null,
        patient_age: patientAge ? Number(patientAge) : null,
        clinical_information: clinicalInfo.trim() || null,
        notes: notes.trim() || null,
        items: items.map((i) => ({
          test_name: i.test_name.trim(),
          specimen_type: i.specimen_type.trim() || null,
          urgency: i.urgency,
          notes: i.notes.trim() || null,
        })),
      });
      const id = res.data?.data?.id;
      toast.success("Lab order saved.");
      router.push(`/prescriptions/lab/${id}`);
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = ax?.response?.data;
      const msg = data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? "Failed to save lab order.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="bg-gradient-to-r from-purple-500 to-fuchsia-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <Link
            href="/prescriptions"
            className="inline-flex items-center gap-1 text-white/90 hover:text-white text-sm mb-3"
          >
            <ArrowLeft className="w-4 h-4" /> Back to prescriptions
          </Link>
          <div className="flex items-center gap-3">
            <FlaskConical className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">New Lab Order</h1>
          </div>
          <p className="text-fuchsia-50 text-sm mt-2">Order lab tests for your patient. A PDF copy can be emailed once saved.</p>
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
          </Grid2>
        </Section>

        <Section title="Clinical information">
          <TextArea label="Reason / clinical info" value={clinicalInfo} onChange={setClinicalInfo} placeholder="e.g. Suspected anemia, fatigue 3 weeks…" />
        </Section>

        <Section
          title="Tests"
          right={
            <button type="button" onClick={addItem} className="inline-flex items-center gap-1 text-sm font-semibold text-purple-500 hover:text-purple-600">
              <Plus className="w-4 h-4" /> Add test
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
                    aria-label="Remove test"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <div className="text-xs font-semibold text-gray-500 mb-2">#{i + 1}</div>
                <Grid2>
                  <Field required label="Test name" value={it.test_name} onChange={(v) => updateItem(i, "test_name", v)} placeholder="e.g. Complete Blood Count" />
                  <Field label="Specimen" value={it.specimen_type} onChange={(v) => updateItem(i, "specimen_type", v)} placeholder="Blood, urine, swab…" />
                  <label className="block">
                    <span className="text-xs font-semibold text-gray-600 mb-1.5 block">Urgency</span>
                    <select
                      value={it.urgency}
                      onChange={(e) => updateItem(i, "urgency", e.target.value as Urgency)}
                      className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-purple-400 focus:ring-2 focus:ring-purple-100 transition-all"
                    >
                      <option value="routine">Routine</option>
                      <option value="urgent">Urgent</option>
                      <option value="stat">STAT</option>
                    </select>
                  </label>
                </Grid2>
                <div className="mt-3">
                  <TextArea label="Notes" value={it.notes} onChange={(v) => updateItem(i, "notes", v)} placeholder="Fasting, send to specific lab, etc." rows={2} />
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section title="Additional notes">
          <TextArea label="Notes" value={notes} onChange={setNotes} placeholder="Anything else the lab or patient should know" />
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
            className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-purple-500 hover:bg-purple-600 disabled:bg-gray-300 text-white text-sm font-semibold transition-colors shadow-sm"
          >
            {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            {submitting ? "Saving…" : "Save lab order"}
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
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-purple-400 focus:ring-2 focus:ring-purple-100 transition-all"
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
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-purple-400 focus:ring-2 focus:ring-purple-100 transition-all resize-none"
      />
    </label>
  );
}

export default function NewLabPrescriptionPage() {
  return (
    <Suspense>
      <NewLabPrescriptionContent />
    </Suspense>
  );
}
