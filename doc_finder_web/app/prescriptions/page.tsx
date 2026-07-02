"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import {
  FileText, Pill, FlaskConical, Scan, Calendar, User as UserIcon,
  RefreshCw, ChevronRight, Plus,
} from "lucide-react";
import api from "@/lib/api";
import { useAuth } from "@/lib/hooks/useAuth";

type Tab = "medication" | "lab" | "radiology";

interface BaseRx {
  id: number;
  prescription_number: string;
  patient_name: string;
  patient_email?: string | null;
  prescriber_name: string;
  issued_date: string;
}

interface MedicationRx extends BaseRx {
  items?: { drug_name: string }[];
}

interface LabRx extends BaseRx {
  items?: { test_name: string }[];
}

interface RadiologyRx extends BaseRx {
  items?: { study_name: string }[];
}

interface TabTheme {
  icon: React.ElementType;
  iconBg: string;
  chipBg: string;
  textAccent: string;
  arrowColor: string;
  label: string;
  singular: string;
}

const TAB_THEME: Record<Tab, TabTheme> = {
  medication: {
    icon: Pill,
    iconBg: "bg-brand-50 text-brand-600",
    chipBg: "bg-brand-50 text-brand-700",
    textAccent: "text-brand-500",
    arrowColor: "text-brand-400",
    label: "medication prescriptions",
    singular: "medication Rx",
  },
  lab: {
    icon: FlaskConical,
    iconBg: "bg-purple-50 text-purple-600",
    chipBg: "bg-purple-50 text-purple-700",
    textAccent: "text-purple-500",
    arrowColor: "text-purple-400",
    label: "lab orders",
    singular: "lab order",
  },
  radiology: {
    icon: Scan,
    iconBg: "bg-rose-50 text-rose-600",
    chipBg: "bg-rose-50 text-rose-700",
    textAccent: "text-rose-500",
    arrowColor: "text-rose-400",
    label: "radiology orders",
    singular: "radiology order",
  },
};

function isDoctor(u: { account_type?: number | string | null } | null): boolean {
  if (!u) return false;
  return u.account_type === 2 || u.account_type === "2" || u.account_type === "serviceProvider";
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString("en-KE", { day: "numeric", month: "short", year: "numeric" });
}

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5 animate-pulse">
      <div className="h-4 bg-gray-200 rounded w-1/3 mb-3" />
      <div className="h-3 bg-gray-100 rounded w-2/3 mb-2" />
      <div className="h-3 bg-gray-100 rounded w-1/2" />
    </div>
  );
}

function itemPreview(rx: MedicationRx | LabRx | RadiologyRx, tab: Tab): string[] {
  const three = (arr: string[] | undefined) => (arr ?? []).slice(0, 3);
  if (tab === "medication") return three((rx as MedicationRx).items?.map((i) => i.drug_name));
  if (tab === "lab") return three((rx as LabRx).items?.map((i) => i.test_name));
  return three((rx as RadiologyRx).items?.map((i) => i.study_name));
}

export default function PrescriptionsHistoryPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [tab, setTab] = useState<Tab>("medication");
  const [medRx, setMedRx] = useState<MedicationRx[]>([]);
  const [labRx, setLabRx] = useState<LabRx[]>([]);
  const [radRx, setRadRx] = useState<RadiologyRx[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const doctor = isDoctor(user);

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) {
      router.replace("/login");
      return;
    }

    setLoading(true);
    setError(false);
    Promise.all([
      api.get("/prescriptions/medication", { params: { per_page: 50 } }),
      api.get("/prescriptions/lab", { params: { per_page: 50 } }),
      api.get("/prescriptions/radiology", { params: { per_page: 50 } }),
    ])
      .then(([medRes, labRes, radRes]) => {
        const unwrap = <T,>(r: { data?: { data?: { data?: T[] } | T[] } }): T[] => {
          const raw = r?.data?.data;
          const list = (raw as { data?: T[] })?.data ?? raw;
          return Array.isArray(list) ? (list as T[]) : [];
        };
        setMedRx(unwrap<MedicationRx>(medRes));
        setLabRx(unwrap<LabRx>(labRes));
        setRadRx(unwrap<RadiologyRx>(radRes));
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [router]);

  const list: (MedicationRx | LabRx | RadiologyRx)[] =
    tab === "medication" ? medRx : tab === "lab" ? labRx : radRx;
  const theme = TAB_THEME[tab];
  const Icon = theme.icon;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="bg-gradient-to-r from-brand-500 to-cyan-500 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-between mb-2 flex-wrap gap-3">
            <div className="flex items-center gap-3">
              <FileText className="w-7 h-7 text-white" />
              <h1 className="text-2xl font-bold text-white">Prescriptions</h1>
            </div>
            {doctor && (
              <div className="flex gap-2 flex-wrap">
                <Link
                  href="/prescriptions/medication/new"
                  className="flex items-center gap-1.5 bg-white/20 hover:bg-white/30 text-white text-xs font-semibold px-3 py-2 rounded-xl transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" /> Medication
                </Link>
                <Link
                  href="/prescriptions/lab/new"
                  className="flex items-center gap-1.5 bg-white/20 hover:bg-white/30 text-white text-xs font-semibold px-3 py-2 rounded-xl transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" /> Lab
                </Link>
                <Link
                  href="/prescriptions/radiology/new"
                  className="flex items-center gap-1.5 bg-white/20 hover:bg-white/30 text-white text-xs font-semibold px-3 py-2 rounded-xl transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" /> Radiology
                </Link>
              </div>
            )}
          </div>
          <p className="text-cyan-50 text-sm mb-5">
            {doctor ? "Prescriptions you've issued" : "Prescriptions you've received"}
          </p>

          <div className="flex gap-2 flex-wrap">
            <TabButton active={tab === "medication"} onClick={() => setTab("medication")} icon={Pill} label="Medication" count={medRx.length} />
            <TabButton active={tab === "lab"} onClick={() => setTab("lab")} icon={FlaskConical} label="Lab orders" count={labRx.length} />
            <TabButton active={tab === "radiology"} onClick={() => setTab("radiology")} icon={Scan} label="Radiology" count={radRx.length} />
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6 pb-12 space-y-3">
        {loading && Array.from({ length: 3 }).map((_, i) => <CardSkeleton key={i} />)}

        {error && !loading && (
          <div className="text-center py-16">
            <FileText className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-2">Failed to load prescriptions</p>
            <button
              onClick={() => window.location.reload()}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm rounded-xl transition-colors"
            >
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        )}

        {!loading && !error && list.length === 0 && (
          <div className="text-center py-16">
            <Icon className={`w-14 h-14 mx-auto mb-4 text-gray-200`} />
            <p className="font-semibold text-gray-600 mb-1">
              No {theme.label} yet
            </p>
            <p className="text-sm text-gray-400">
              {doctor
                ? `Issue a ${theme.singular} from an appointment.`
                : "Your provider will share prescriptions here when issued."}
            </p>
          </div>
        )}

        {!loading && !error && list.map((rx) => {
          const items = itemPreview(rx, tab);
          return (
            <Link
              key={rx.id}
              href={`/prescriptions/${tab}/${rx.id}`}
              className="block bg-white rounded-2xl shadow-sm border border-gray-100 p-5 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-4">
                <div className={`w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ${theme.iconBg}`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h3 className="font-bold text-gray-900 text-sm">
                        {doctor ? rx.patient_name : rx.prescriber_name}
                      </h3>
                      <p className={`text-xs font-medium mt-0.5 ${theme.textAccent}`}>
                        {rx.prescription_number}
                      </p>
                    </div>
                    <span className="text-xs text-gray-500 flex items-center gap-1 flex-shrink-0">
                      <Calendar className="w-3 h-3" /> {formatDate(rx.issued_date)}
                    </span>
                  </div>

                  <div className="mt-2 flex flex-wrap gap-2">
                    {items.map((name, idx) => (
                      <span key={idx} className={`text-xs px-2 py-0.5 rounded-full ${theme.chipBg}`}>
                        {name}
                      </span>
                    ))}
                  </div>

                  <div className="mt-3 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
                    <div className="flex items-center gap-1">
                      <UserIcon className="w-3.5 h-3.5" />
                      {doctor ? rx.patient_email ?? "no email" : rx.patient_name}
                    </div>
                    <ChevronRight className={`w-4 h-4 ${theme.arrowColor}`} />
                  </div>
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </main>
  );
}

function TabButton({
  active, onClick, icon: Icon, label, count,
}: {
  active: boolean; onClick: () => void; icon: React.ElementType; label: string; count: number;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex-shrink-0 inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-colors ${
        active ? "bg-white text-brand-600 shadow-sm" : "bg-white/20 text-white hover:bg-white/30"
      }`}
    >
      <Icon className="w-3.5 h-3.5" />
      {label} ({count})
    </button>
  );
}
