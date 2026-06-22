"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Calendar, Clock, User, Stethoscope, RefreshCw,
  Video, Building2, CheckCircle2, XCircle, AlertCircle,
  ChevronRight, Plus, Pill, FlaskConical,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { getInitials } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";

function isDoctor(u: { account_type?: number | string | null } | null): boolean {
  if (!u) return false;
  return u.account_type === 2 || u.account_type === "2" || u.account_type === "serviceProvider";
}

interface Doctor {
  id: number;
  name: string;
  profile_image?: string;
  specialties?: string[];
}

interface Appointment {
  id: number;
  doctor_id: number;
  patient_name: string;
  patient_email?: string;
  patient_telephone?: string;
  appointment_date: string;
  appointment_time: string;
  consultation_type: "in_person" | "online";
  status: "pending" | "confirmed" | "cancelled" | "completed";
  notes?: string;
  doctor?: Doctor;
}

type FilterStatus = "all" | "pending" | "confirmed" | "completed" | "cancelled";

const statusConfig: Record<string, { label: string; icon: React.ElementType; cls: string; dot: string }> = {
  pending:   { label: "Pending",   icon: AlertCircle,   cls: "bg-amber-100 text-amber-700",  dot: "bg-amber-400" },
  confirmed: { label: "Confirmed", icon: CheckCircle2,  cls: "bg-green-100 text-green-700",  dot: "bg-green-400" },
  completed: { label: "Completed", icon: CheckCircle2,  cls: "bg-blue-100 text-blue-700",    dot: "bg-blue-400" },
  cancelled: { label: "Cancelled", icon: XCircle,       cls: "bg-red-100 text-red-600",      dot: "bg-red-400" },
};

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 animate-pulse space-y-3">
      <div className="flex gap-3">
        <div className="w-12 h-12 rounded-full bg-gray-200 flex-shrink-0" />
        <div className="flex-1 space-y-2 py-1">
          <div className="h-4 bg-gray-200 rounded w-1/2" />
          <div className="h-3 bg-gray-100 rounded w-1/3" />
        </div>
      </div>
      <div className="h-3 bg-gray-100 rounded w-2/3" />
    </div>
  );
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-KE", { weekday: "short", day: "numeric", month: "short", year: "numeric" });
}

function formatTime(timeStr: string) {
  const [h, m] = timeStr.split(":").map(Number);
  const ampm = h >= 12 ? "PM" : "AM";
  const hour = h % 12 || 12;
  return `${hour}:${String(m).padStart(2,"0")} ${ampm}`;
}

export default function AppointmentsPage() {
  const router = useRouter();
  const { user } = useAuth();
  const doctor = isDoctor(user as { account_type?: number | string | null });
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [filter, setFilter] = useState<FilterStatus>("all");

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    api.get("/appointments")
      .then(res => {
        const raw = res.data?.data;
        const list: Appointment[] = Array.isArray(raw?.data) ? raw.data : Array.isArray(raw) ? raw : [];
        setAppointments(list);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [router]);

  const filtered = filter === "all"
    ? appointments
    : appointments.filter(a => a.status === filter);

  const counts: Record<FilterStatus, number> = {
    all: appointments.length,
    pending:   appointments.filter(a => a.status === "pending").length,
    confirmed: appointments.filter(a => a.status === "confirmed").length,
    completed: appointments.filter(a => a.status === "completed").length,
    cancelled: appointments.filter(a => a.status === "cancelled").length,
  };

  const filters: FilterStatus[] = ["all", "pending", "confirmed", "completed", "cancelled"];

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-gradient-to-r from-pink-500 to-rose-500 pt-28 pb-8 px-4">
        <div className="max-w-3xl mx-auto">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-3">
              <Calendar className="w-7 h-7 text-white" />
              <h1 className="text-2xl font-bold text-white">My Appointments</h1>
            </div>
            <Link href="/doctors"
              className="flex items-center gap-1.5 bg-white/20 hover:bg-white/30 text-white text-sm font-semibold px-3 py-2 rounded-xl transition-colors">
              <Plus className="w-4 h-4" /> Book New
            </Link>
          </div>
          <p className="text-pink-100 text-sm mb-5">Track and manage your upcoming visits</p>

          {/* Status filter pills */}
          <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
            {filters.map(f => (
              <button key={f} onClick={() => setFilter(f)}
                className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold capitalize transition-colors ${
                  filter === f
                    ? "bg-white text-pink-600 shadow-sm"
                    : "bg-pink-600/40 text-pink-100 hover:bg-pink-600/60"
                }`}>
                {f === "all" ? `All (${counts.all})` : `${f} (${counts[f]})`}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* List */}
      <div className="max-w-3xl mx-auto px-4 py-6 pb-12 space-y-3">
        {loading && Array.from({length:4}).map((_,i)=><CardSkeleton key={i}/>)}

        {error && (
          <div className="text-center py-16">
            <Calendar className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-2">Failed to load appointments</p>
            <button onClick={() => window.location.reload()}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-pink-500 hover:bg-pink-600 text-white font-semibold text-sm rounded-xl transition-colors">
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <div className="text-center py-16">
            <Calendar className="w-14 h-14 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-2">
              {filter === "all" ? "No appointments yet" : `No ${filter} appointments`}
            </p>
            <p className="text-sm text-gray-400 mb-5">Book an appointment with a doctor to get started.</p>
            <Link href="/doctors"
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-pink-500 hover:bg-pink-600 text-white font-semibold text-sm rounded-xl transition-colors">
              <Stethoscope className="w-4 h-4" /> Find a Doctor
            </Link>
          </div>
        )}

        {!loading && !error && filtered.map(appt => {
          const sc = statusConfig[appt.status] ?? statusConfig.pending;
          const StatusIcon = sc.icon;
          const imgUrl = getImageUrl(appt.doctor?.profile_image);
          const doctorName = appt.doctor?.name ?? "Doctor";
          const specialty = appt.doctor?.specialties?.join(" · ") ?? "";
          const isOnline = appt.consultation_type === "online";

          return (
            <div key={appt.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-start gap-4">
                {/* Doctor avatar */}
                <div className="flex-shrink-0">
                  {imgUrl
                    ? <img src={imgUrl} alt={doctorName} className="w-12 h-12 rounded-full object-cover" />
                    : <div className="w-12 h-12 rounded-full bg-pink-100 flex items-center justify-center text-pink-600 font-bold text-base">
                        {getInitials(doctorName)}
                      </div>}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h3 className="font-bold text-gray-900 text-sm">{doctorName}</h3>
                      {specialty && <p className="text-xs text-pink-500 font-medium mt-0.5">{specialty}</p>}
                    </div>
                    <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${sc.cls}`}>
                      <StatusIcon className="w-3 h-3" />
                      {sc.label}
                    </span>
                  </div>

                  <div className="flex flex-wrap gap-x-4 gap-y-1 mt-2">
                    <div className="flex items-center gap-1 text-xs text-gray-600">
                      <Calendar className="w-3.5 h-3.5 text-gray-400" />
                      {formatDate(appt.appointment_date)}
                    </div>
                    <div className="flex items-center gap-1 text-xs text-gray-600">
                      <Clock className="w-3.5 h-3.5 text-gray-400" />
                      {formatTime(appt.appointment_time)}
                    </div>
                    <div className="flex items-center gap-1 text-xs text-gray-600">
                      {isOnline
                        ? <><Video className="w-3.5 h-3.5 text-blue-400" /> Online</>
                        : <><Building2 className="w-3.5 h-3.5 text-green-500" /> In-Person</>}
                    </div>
                  </div>

                  {appt.notes && (
                    <p className="text-xs text-gray-500 mt-2 bg-gray-50 rounded-xl px-3 py-2 leading-relaxed">{appt.notes}</p>
                  )}

                  <div className="flex items-center gap-2 mt-3 pt-3 border-t border-gray-50 flex-wrap">
                    <div className="flex items-center gap-1 text-xs text-gray-500">
                      <User className="w-3.5 h-3.5" /> {appt.patient_name}
                    </div>
                    {doctor && (
                      <div className="flex items-center gap-2 ml-auto">
                        <Link
                          href={{
                            pathname: "/prescriptions/medication/new",
                            query: {
                              appointment_id: appt.id,
                              patient_name: appt.patient_name,
                              patient_email: appt.patient_email ?? "",
                              patient_phone: appt.patient_telephone ?? "",
                            },
                          }}
                          className="inline-flex items-center gap-1 text-xs font-semibold text-brand-500 hover:text-brand-600 bg-brand-50 hover:bg-brand-100 px-2.5 py-1 rounded-lg transition-colors"
                        >
                          <Pill className="w-3.5 h-3.5" /> Medication Rx
                        </Link>
                        <Link
                          href={{
                            pathname: "/prescriptions/lab/new",
                            query: {
                              appointment_id: appt.id,
                              patient_name: appt.patient_name,
                              patient_email: appt.patient_email ?? "",
                              patient_phone: appt.patient_telephone ?? "",
                            },
                          }}
                          className="inline-flex items-center gap-1 text-xs font-semibold text-purple-500 hover:text-purple-600 bg-purple-50 hover:bg-purple-100 px-2.5 py-1 rounded-lg transition-colors"
                        >
                          <FlaskConical className="w-3.5 h-3.5" /> Lab Order
                        </Link>
                      </div>
                    )}
                    {!doctor && appt.doctor && (
                      <Link href={`/doctors/${appt.doctor.id}`}
                        className="ml-auto flex items-center gap-1 text-xs font-semibold text-pink-500 hover:text-pink-600 transition-colors">
                        View Doctor <ChevronRight className="w-3.5 h-3.5" />
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}
