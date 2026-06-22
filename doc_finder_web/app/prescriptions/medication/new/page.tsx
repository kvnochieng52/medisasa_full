"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  Pill, Plus, Trash2, Save, Loader2, ArrowLeft,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

interface MedicationItem {
  drug_name: string;
  dosage_form: string;
  strength: string;
  frequency: string;
  route: string;
  duration: string;
  quantity: string;
  refills: string;
  instructions: string;
}

const emptyItem = (): MedicationItem => ({
  drug_name: "",
  dosage_form: "",
  strength: "",
  frequency: "",
  route: "by mouth",
  duration: "",
  quantity: "",
  refills: "0",
  instructions: "",
});

function NewMedicationPrescriptionContent() {
  const router = useRouter();
  const params = useSearchParams();

  const [clinicName, setClinicName] = useState("");
  const [clinicAddress, setClinicAddress] = useState("");
  const [patientName, setPatientName] = useState(params.get("patient_name") ?? "");
  const [patientEmail, setPatientEmail] = useState(params.get("patient_email") ?? "");
  const [patientPhone, setPatientPhone] = useState(params.get("patient_phone") ?? "");
  const [patientDob, setPatientDob] = useState("");
  const [patientAge, setPatientAge] = useState("");
  const [diagnosis, setDiagnosis] = useState("");
  const [notes, setNotes] = useState("");
  const [items, setItems] = useState<MedicationItem[]>([emptyItem()]);
  const [submitting, setSubmitting] = useState(false);

  const appointmentId = params.get("appointment_id");

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) router.replace("/login");
  }, [router]);

  const updateItem = (i: number, field: keyof MedicationItem, value: string) => {
    setItems((arr) => arr.map((it, idx) => (idx === i ? { ...it, [field]: value } : it)));
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
    if (items.some((i) => !i.drug_name.trim())) {
      toast.error("Each medication needs a drug name.");
      return;
    }

    setSubmitting(true);
    try {
      const res = await api.post("/prescriptions/medication", {
        appointment_id: appointmentId ? Number(appointmentId) : null,
        clinic_name: clinicName.trim() || null,
        clinic_address: clinicAddress.trim() || null,
        patient_name: patientName.trim(),
        patient_email: patientEmail.trim() || null,
        patient_phone: patientPhone.trim() || null,
        patient_dob: patientDob || null,
        patient_age: patientAge ? Number(patientAge) : null,
        diagnosis: diagnosis.trim() || null,
        notes: notes.trim() || null,
        items: items.map((i) => ({
          drug_name: i.drug_name.trim(),
          dosage_form: i.dosage_form.trim() || null,
          strength: i.strength.trim() || null,
          frequency: i.frequency.trim() || null,
          route: i.route.trim() || null,
          duration: i.duration.trim() || null,
          quantity: i.quantity.trim() || null,
          refills: i.refills ? Number(i.refills) : 0,
          instructions: i.instructions.trim() || null,
        })),
      });
      const id = res.data?.data?.id;
      toast.success("Prescription saved.");
      router.push(`/prescriptions/medication/${id}`);
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = ax?.response?.data;
      const msg = data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? "Failed to save prescription.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="bg-gradient-to-r from-brand-500 to-cyan-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <Link
            href="/prescriptions"
            className="inline-flex items-center gap-1 text-white/90 hover:text-white text-sm mb-3"
          >
            <ArrowLeft className="w-4 h-4" /> Back to prescriptions
          </Link>
          <div className="flex items-center gap-3">
            <Pill className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">New Medication Prescription</h1>
          </div>
          <p className="text-cyan-50 text-sm mt-2">Issue a medication Rx for your patient. A PDF copy can be emailed once saved.</p>
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

        <Section title="Clinical">
          <TextArea label="Diagnosis" value={diagnosis} onChange={setDiagnosis} placeholder="e.g. Acute upper respiratory infection" />
        </Section>

        <Section
          title="Medications"
          right={
            <button type="button" onClick={addItem} className="inline-flex items-center gap-1 text-sm font-semibold text-brand-500 hover:text-brand-600">
              <Plus className="w-4 h-4" /> Add row
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
                    aria-label="Remove medication"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <div className="text-xs font-semibold text-gray-500 mb-2">#{i + 1}</div>
                <Grid2>
                  <Field required label="Drug name" value={it.drug_name} onChange={(v) => updateItem(i, "drug_name", v)} placeholder="e.g. Amoxicillin" />
                  <Grid2 inner>
                    <Field label="Form" value={it.dosage_form} onChange={(v) => updateItem(i, "dosage_form", v)} placeholder="capsule, syrup…" />
                    <Field label="Strength" value={it.strength} onChange={(v) => updateItem(i, "strength", v)} placeholder="500mg" />
                  </Grid2>
                  <Field label="Frequency" value={it.frequency} onChange={(v) => updateItem(i, "frequency", v)} placeholder="e.g. 3x daily" />
                  <Field label="Route" value={it.route} onChange={(v) => updateItem(i, "route", v)} placeholder="by mouth" />
                  <Field label="Duration" value={it.duration} onChange={(v) => updateItem(i, "duration", v)} placeholder="7 days" />
                  <Grid2 inner>
                    <Field label="Quantity" value={it.quantity} onChange={(v) => updateItem(i, "quantity", v)} placeholder="21 capsules" />
                    <Field label="Refills" type="number" value={it.refills} onChange={(v) => updateItem(i, "refills", v)} placeholder="0" />
                  </Grid2>
                </Grid2>
                <div className="mt-3">
                  <TextArea label="Instructions" value={it.instructions} onChange={(v) => updateItem(i, "instructions", v)} placeholder="Take after meals" rows={2} />
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section title="Additional notes">
          <TextArea label="Notes" value={notes} onChange={setNotes} placeholder="Anything else the patient should know" />
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
            className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white text-sm font-semibold transition-colors shadow-sm"
          >
            {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            {submitting ? "Saving…" : "Save prescription"}
          </button>
        </div>
      </form>
    </main>
  );
}

// ---------------------------------------------------------------------
// Tiny shared form atoms — kept local to the file to avoid premature shared lib
// ---------------------------------------------------------------------

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
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 transition-all"
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
        className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 transition-all resize-none"
      />
    </label>
  );
}

export default function NewMedicationPrescriptionPage() {
  return (
    <Suspense>
      <NewMedicationPrescriptionContent />
    </Suspense>
  );
}
