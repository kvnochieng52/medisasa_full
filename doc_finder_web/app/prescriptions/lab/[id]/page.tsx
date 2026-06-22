"use client";

import { use, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  FlaskConical, Calendar, User as UserIcon, ArrowLeft, Download, Mail, Loader2, Stethoscope,
} from "lucide-react";
import api, { API_BASE_URL } from "@/lib/api";
import toast from "react-hot-toast";

interface LabItem {
  id: number;
  test_name: string;
  specimen_type?: string | null;
  urgency: "routine" | "urgent" | "stat";
  notes?: string | null;
}

interface LabRx {
  id: number;
  prescription_number: string;
  prescriber_name: string;
  prescriber_licence_number?: string | null;
  prescriber_phone?: string | null;
  prescriber_email?: string | null;
  clinic_name?: string | null;
  clinic_address?: string | null;
  patient_name: string;
  patient_email?: string | null;
  patient_phone?: string | null;
  patient_dob?: string | null;
  patient_age?: number | null;
  issued_date: string;
  clinical_information?: string | null;
  notes?: string | null;
  items: LabItem[];
}

const urgencyStyle: Record<LabItem["urgency"], string> = {
  routine: "bg-teal-50 text-teal-700",
  urgent: "bg-amber-50 text-amber-700",
  stat: "bg-red-50 text-red-700",
};

function formatDate(d?: string | null) {
  if (!d) return "—";
  return new Date(d).toLocaleDateString("en-KE", { day: "numeric", month: "short", year: "numeric" });
}

export default function LabDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [rx, setRx] = useState<LabRx | null>(null);
  const [loading, setLoading] = useState(true);
  const [downloading, setDownloading] = useState(false);
  const [emailing, setEmailing] = useState(false);
  const [showEmail, setShowEmail] = useState(false);
  const [emailTo, setEmailTo] = useState("");

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) {
      router.replace("/login");
      return;
    }
    api.get(`/prescriptions/lab/${id}`)
      .then((res) => {
        const data = res.data?.data;
        setRx(data);
        setEmailTo(data?.patient_email ?? "");
      })
      .catch(() => toast.error("Failed to load lab order."))
      .finally(() => setLoading(false));
  }, [id, router]);

  const downloadPdf = async () => {
    setDownloading(true);
    try {
      const token = localStorage.getItem("auth_token");
      const res = await fetch(`${API_BASE_URL}/prescriptions/lab/${id}/pdf`, {
        headers: { Authorization: `Bearer ${token ?? ""}` },
      });
      if (!res.ok) throw new Error("Failed to download");
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${rx?.prescription_number ?? "lab-order"}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch {
      toast.error("Failed to download PDF.");
    } finally {
      setDownloading(false);
    }
  };

  const sendEmail = async () => {
    if (!emailTo.trim()) {
      toast.error("Enter an email address.");
      return;
    }
    setEmailing(true);
    try {
      await api.post(`/prescriptions/lab/${id}/email`, { email: emailTo.trim() });
      toast.success(`Sent to ${emailTo}.`);
      setShowEmail(false);
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string } } };
      toast.error(ax?.response?.data?.message ?? "Failed to send email.");
    } finally {
      setEmailing(false);
    }
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="max-w-4xl mx-auto px-4 pt-32 pb-12">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 animate-pulse">
            <div className="h-6 bg-gray-200 rounded w-1/3 mb-4" />
            <div className="h-4 bg-gray-100 rounded w-2/3 mb-2" />
            <div className="h-4 bg-gray-100 rounded w-1/2" />
          </div>
        </div>
      </main>
    );
  }

  if (!rx) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="max-w-4xl mx-auto px-4 pt-32 pb-12 text-center">
          <p className="text-gray-500">Lab order not found.</p>
          <Link href="/prescriptions" className="text-purple-500 hover:text-purple-600 font-semibold text-sm mt-2 inline-block">
            ← Back to prescriptions
          </Link>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="bg-gradient-to-r from-purple-500 to-fuchsia-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/prescriptions" className="inline-flex items-center gap-1 text-white/90 hover:text-white text-sm mb-3">
            <ArrowLeft className="w-4 h-4" /> Back to prescriptions
          </Link>
          <div className="flex items-start justify-between gap-3 flex-wrap">
            <div>
              <div className="flex items-center gap-3 mb-1">
                <FlaskConical className="w-7 h-7 text-white" />
                <h1 className="text-2xl font-bold text-white">Lab Order</h1>
              </div>
              <p className="text-fuchsia-50 text-sm font-mono">{rx.prescription_number}</p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={downloadPdf}
                disabled={downloading}
                className="inline-flex items-center gap-2 bg-white text-purple-600 hover:bg-purple-50 text-sm font-semibold px-4 py-2.5 rounded-xl transition-colors shadow-sm"
              >
                {downloading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
                Download PDF
              </button>
              <button
                onClick={() => setShowEmail((s) => !s)}
                className="inline-flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white text-sm font-semibold px-4 py-2.5 rounded-xl transition-colors"
              >
                <Mail className="w-4 h-4" /> Email
              </button>
            </div>
          </div>

          {showEmail && (
            <div className="mt-4 bg-white rounded-2xl p-4 shadow-sm flex flex-col sm:flex-row items-stretch gap-2">
              <input
                type="email"
                value={emailTo}
                onChange={(e) => setEmailTo(e.target.value)}
                placeholder="patient@example.com"
                className="flex-1 px-3.5 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none focus:bg-white focus:border-purple-400 focus:ring-2 focus:ring-purple-100"
              />
              <button
                onClick={sendEmail}
                disabled={emailing || !emailTo.trim()}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-purple-500 hover:bg-purple-600 disabled:bg-gray-300 text-white text-sm font-semibold transition-colors"
              >
                {emailing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Mail className="w-4 h-4" />}
                Send PDF
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6 pb-12 space-y-4">
        <Card title="Prescriber" icon={Stethoscope}>
          <KV label="Doctor" value={rx.prescriber_name} />
          <KV label="Licence No." value={rx.prescriber_licence_number} />
          <KV label="Phone" value={rx.prescriber_phone} />
          <KV label="Email" value={rx.prescriber_email} />
          {(rx.clinic_name || rx.clinic_address) && (
            <>
              <KV label="Clinic" value={rx.clinic_name} />
              <KV label="Clinic address" value={rx.clinic_address} />
            </>
          )}
        </Card>

        <Card title="Patient" icon={UserIcon}>
          <KV label="Name" value={rx.patient_name} />
          <KV label="Age" value={rx.patient_age != null ? String(rx.patient_age) : null} />
          <KV label="Date of birth" value={rx.patient_dob ? formatDate(rx.patient_dob) : null} />
          <KV label="Phone" value={rx.patient_phone} />
          <KV label="Email" value={rx.patient_email} />
          <KV label="Issued" value={formatDate(rx.issued_date)} />
        </Card>

        {rx.clinical_information && (
          <Card title="Clinical information" icon={Calendar}>
            <p className="text-sm text-gray-700 leading-relaxed">{rx.clinical_information}</p>
          </Card>
        )}

        <Card title="Tests ordered" icon={FlaskConical}>
          <div className="space-y-3">
            {rx.items.map((it, i) => (
              <div key={it.id} className="border border-gray-100 rounded-xl p-3 bg-gray-50/50">
                <div className="flex items-center justify-between flex-wrap gap-2">
                  <h4 className="text-sm font-bold text-gray-900">
                    {i + 1}. {it.test_name}
                  </h4>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-semibold uppercase tracking-wide ${urgencyStyle[it.urgency]}`}>
                    {it.urgency}
                  </span>
                </div>
                {it.specimen_type && (
                  <p className="text-xs text-gray-600 mt-1">Specimen: <strong className="text-gray-800">{it.specimen_type}</strong></p>
                )}
                {it.notes && (
                  <p className="mt-2 text-xs text-gray-600 bg-white border border-gray-100 rounded-lg px-2.5 py-1.5">{it.notes}</p>
                )}
              </div>
            ))}
          </div>
        </Card>

        {rx.notes && (
          <Card title="Notes" icon={Calendar}>
            <p className="text-sm text-gray-700 leading-relaxed">{rx.notes}</p>
          </Card>
        )}
      </div>
    </main>
  );
}

function Card({ title, icon: Icon, children }: { title: string; icon: React.ElementType; children: React.ReactNode }) {
  return (
    <section className="bg-white border border-gray-100 rounded-2xl shadow-sm p-5">
      <div className="flex items-center gap-2 mb-4">
        <Icon className="w-4 h-4 text-purple-500" />
        <h2 className="text-sm font-bold text-gray-900 uppercase tracking-wide">{title}</h2>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2">{children}</div>
    </section>
  );
}

function KV({ label, value }: { label: string; value?: string | null }) {
  return (
    <div>
      <div className="text-xs text-gray-500 uppercase tracking-wide">{label}</div>
      <div className="text-sm font-medium text-gray-800">{value || "—"}</div>
    </div>
  );
}
