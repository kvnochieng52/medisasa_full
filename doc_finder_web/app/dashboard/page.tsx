"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Stethoscope, Pill, Users, Building2, Calendar, Heart,
  ChevronRight, UserCircle, Clock, ShieldCheck, Plus,
  Sparkles, AlertTriangle, Loader2, CheckCircle2,
  Brain, BookOpen, Shield, Layers, Activity, Thermometer,
  Settings,
} from "lucide-react";
import { getGreeting } from "@/lib/utils";
import api from "@/lib/api";

interface UserData {
  name?: string;
  email?: string;
  account_type?: number | string | null;
  sp_approved?: number | null;
}

interface SubscriptionInfo {
  id: number;
  plan: string;
  plan_name: string;
  amount: string;
  currency: string;
  status: string;
  subscription_starts_at: string;
  subscription_ends_at: string;
  days_remaining: number;
  limits: {
    max_appointments_per_month: number | null;
    max_facilities: number | null;
    max_hospitals: number | null;
  };
}

interface SubscriptionStatus {
  has_active_subscription: boolean;
  subscription: SubscriptionInfo | null;
}

interface ScreeningHistory {
  id: number;
  total_score: number;
  created_at: string;
}

function isAdmin(u: UserData) {
  return Number(u.account_type) === 3;
}
function isServiceProvider(u: UserData) {
  return u.account_type === 2 || u.account_type === "serviceProvider";
}
function isPendingVerification(u: UserData) {
  return isServiceProvider(u) && !u.sp_approved;
}
function isApprovedSP(u: UserData) {
  return isServiceProvider(u) && !!u.sp_approved;
}

const quickLinks = [
  { icon: Stethoscope, label: "Find Doctor",   href: "/doctors",       color: "bg-blue-50 text-blue-600" },
  { icon: Building2,   label: "Hospitals",     href: "/hospitals",     color: "bg-green-50 text-green-600" },
  { icon: Pill,        label: "Pharmacy",      href: "/pharmacy",      color: "bg-purple-50 text-purple-600" },
  { icon: Users,       label: "Support",       href: "/support-groups",color: "bg-orange-50 text-orange-600" },
  { icon: Calendar,    label: "Appointments",  href: "/appointments",  color: "bg-pink-50 text-pink-600" },
  { icon: Heart,       label: "My Health",     href: "/profile/setup", color: "bg-red-50 text-red-600" },
];

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<UserData | null>(null);
  const [greeting, setGreeting] = useState("Hello");
  const [subStatus, setSubStatus] = useState<SubscriptionStatus | null>(null);
  const [subLoading, setSubLoading] = useState(false);
  const [screeningHistory, setScreeningHistory] = useState<ScreeningHistory[]>([]);

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    const raw = localStorage.getItem("user_data");
    let parsed: UserData | null = null;
    if (raw) {
      try { parsed = JSON.parse(raw); setUser(parsed); } catch { /* ignore */ }
    }
    setGreeting(getGreeting());

    if (parsed && isApprovedSP(parsed)) {
      setSubLoading(true);
      api.get<{ success: boolean; data: SubscriptionStatus }>("/subscription/status")
        .then(res => setSubStatus(res.data.data ?? null))
        .catch(() => setSubStatus(null))
        .finally(() => setSubLoading(false));
    }

    api.get<{ success: boolean; data: ScreeningHistory[] }>("/depression-screenings/history")
      .then(res => setScreeningHistory(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setScreeningHistory([]));
  }, [router]);

  const firstName = user?.name?.split(" ")[0] ?? "there";
  const sub = subStatus?.subscription;
  const hasActiveSub = subStatus?.has_active_subscription ?? false;
  const isExpiringSoon = hasActiveSub && sub && sub.days_remaining <= 7;
  const lastScreening = screeningHistory[0] ?? null;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-28 pb-12">

        {/* Greeting */}
        <div className="bg-gradient-to-r from-brand-500 to-brand-600 rounded-2xl p-6 sm:p-8 text-white mb-8 shadow-card">
          <p className="text-brand-100 text-sm font-medium mb-1">{greeting}!</p>
          <h1 className="text-2xl sm:text-3xl font-bold mb-2">Welcome back, {firstName} 👋</h1>
          <p className="text-brand-100 text-sm">What would you like to do today?</p>
        </div>

        {/* Profile completion banner */}
        {user && !user.account_type && (
          <Link href="/profile/setup"
            className="flex items-center justify-between bg-amber-50 border border-amber-200 rounded-2xl p-4 sm:p-5 mb-8 hover:bg-amber-100 transition-colors group">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-amber-100 rounded-xl">
                <UserCircle className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-sm font-bold text-amber-800">Complete your profile</p>
                <p className="text-xs text-amber-600 mt-0.5">Tell us who you are to get personalised recommendations</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-amber-500 group-hover:translate-x-0.5 transition-transform flex-shrink-0" />
          </Link>
        )}

        {/* Pending verification banner */}
        {user && isPendingVerification(user) && (
          <div className="flex items-start gap-4 bg-orange-50 border border-orange-200 rounded-2xl p-4 sm:p-5 mb-8">
            <div className="p-2.5 bg-orange-100 rounded-xl flex-shrink-0">
              <Clock className="w-5 h-5 text-orange-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-orange-800">Profile Pending Verification</p>
              <p className="text-xs text-orange-600 mt-0.5">
                Our team is reviewing your credentials. You&apos;ll be notified once approved — usually 2–3 business days.
              </p>
            </div>
            <Link href="/profile/setup" className="text-xs font-semibold text-orange-700 hover:text-orange-900 whitespace-nowrap flex-shrink-0">
              View Profile
            </Link>
          </div>
        )}

        {/* Quick access grid */}
        <h2 className="text-lg font-bold text-gray-800 mb-4">Quick Access</h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 mb-10">
          {quickLinks.map(({ icon: Icon, label, href, color }) => (
            <Link key={href} href={href}
              className="bg-white rounded-2xl p-5 shadow-card hover:shadow-card-hover transition-all duration-200 hover:-translate-y-0.5 flex flex-col items-center gap-3 text-center group">
              <div className={`p-3 rounded-xl ${color} group-hover:scale-110 transition-transform`}>
                <Icon className="w-5 h-5" />
              </div>
              <span className="text-xs font-semibold text-gray-700">{label}</span>
            </Link>
          ))}
        </div>

        {/* ── ADMINISTRATION SECTION (approved SPs only) ── */}
        {user && isApprovedSP(user) && (
          <div className="mb-10">
            <div className="flex items-center gap-2 mb-4">
              <ShieldCheck className="w-5 h-5 text-brand-500" />
              <h2 className="text-lg font-bold text-gray-800">Administration</h2>
            </div>

            {/* Loading subscription */}
            {subLoading && (
              <div className="flex items-center gap-3 bg-white rounded-2xl shadow-card p-5 mb-4">
                <Loader2 className="w-4 h-4 animate-spin text-brand-400" />
                <span className="text-sm text-gray-500">Checking subscription…</span>
              </div>
            )}

            {/* Active subscription info bar */}
            {!subLoading && hasActiveSub && sub && (
              <div className={`flex flex-col sm:flex-row sm:items-center justify-between gap-3 rounded-2xl p-4 mb-4 ${
                isExpiringSoon
                  ? "bg-amber-50 border border-amber-200"
                  : "bg-green-50 border border-green-200"
              }`}>
                <div className="flex items-center gap-3">
                  {isExpiringSoon
                    ? <AlertTriangle className="w-5 h-5 text-amber-500 flex-shrink-0" />
                    : <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />}
                  <div>
                    <p className={`text-sm font-bold ${isExpiringSoon ? "text-amber-800" : "text-green-800"}`}>
                      {sub.plan_name} Plan — Active
                      {isExpiringSoon && <span className="ml-2 text-xs font-semibold bg-amber-200 text-amber-700 px-2 py-0.5 rounded-full">Expiring soon</span>}
                    </p>
                    <p className={`text-xs mt-0.5 ${isExpiringSoon ? "text-amber-600" : "text-green-600"}`}>
                      {sub.days_remaining} day{sub.days_remaining !== 1 ? "s" : ""} remaining
                      &nbsp;·&nbsp;Expires {new Date(sub.subscription_ends_at).toLocaleDateString("en-KE", { day: "numeric", month: "short", year: "numeric" })}
                    </p>
                  </div>
                </div>
                <Link href="/subscription"
                  className={`text-xs font-semibold whitespace-nowrap px-3 py-1.5 rounded-lg transition-colors ${
                    isExpiringSoon
                      ? "bg-amber-100 text-amber-700 hover:bg-amber-200"
                      : "bg-green-100 text-green-700 hover:bg-green-200"
                  }`}>
                  {isExpiringSoon ? "Renew Plan" : "Manage Plan"}
                </Link>
              </div>
            )}

            {/* No subscription — unlock banner */}
            {!subLoading && !hasActiveSub && (
              <div className="bg-gradient-to-r from-purple-600 to-brand-600 rounded-2xl p-6 mb-4 text-white">
                <div className="flex items-start gap-4">
                  <div className="p-3 bg-white/20 rounded-xl flex-shrink-0">
                    <Sparkles className="w-6 h-6 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className="font-bold text-lg mb-1">Unlock Premium Features</p>
                    <p className="text-sm text-white/80 mb-4">
                      Subscribe to a plan to manage facilities, receive appointments, and grow your practice.
                    </p>
                    <ul className="space-y-1.5 mb-5">
                      {[
                        "Manage clinics & hospitals",
                        "Receive patient appointments",
                        "Support group management",
                        "Pharmacy listing",
                      ].map(f => (
                        <li key={f} className="flex items-center gap-2 text-sm text-white/90">
                          <CheckCircle2 className="w-4 h-4 text-white/70 flex-shrink-0" />
                          {f}
                        </li>
                      ))}
                    </ul>
                    <Link href="/subscription"
                      className="inline-flex items-center gap-2 px-5 py-2.5 bg-white text-purple-700 font-semibold text-sm rounded-xl hover:bg-purple-50 transition-colors shadow-sm">
                      <Sparkles className="w-4 h-4" /> View Plans & Subscribe
                    </Link>
                  </div>
                </div>
              </div>
            )}

            {/* Admin module cards — only when subscribed */}
            {!subLoading && hasActiveSub && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <AdminModuleCard
                  icon={<Building2 className="w-5 h-5 text-blue-600" />}
                  iconBg="bg-blue-50"
                  title="Facilities"
                  desc="Manage your clinics & hospitals"
                  viewHref="/admin/facilities"
                  newHref="/admin/facilities/new"
                />
                <AdminModuleCard
                  icon={<Users className="w-5 h-5 text-orange-500" />}
                  iconBg="bg-orange-50"
                  title="Support Groups"
                  desc="Create and manage community support groups"
                  viewHref="/admin/support-groups"
                  newHref="/admin/support-groups/new"
                />
                <AdminModuleCard
                  icon={<Pill className="w-5 h-5 text-purple-500" />}
                  iconBg="bg-purple-50"
                  title="Pharmacy"
                  desc="Manage medicines, medical products and inventory"
                  viewHref="/admin/pharmacy"
                  newHref="/admin/pharmacy/medicines/new"
                />
              </div>
            )}
          </div>
        )}

        {/* ── MENTAL HEALTH SECTION ── */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Brain className="w-5 h-5 text-violet-500" />
              <h2 className="text-lg font-bold text-gray-800">Mental Health</h2>
            </div>
            <Link href="/mental-health"
              className="flex items-center gap-1 text-xs font-semibold text-violet-600 hover:text-violet-800 transition-colors">
              Browse Resources <ChevronRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {/* Main CTA Card */}
            <div className="lg:col-span-2 bg-gradient-to-br from-violet-600 to-purple-700 rounded-2xl p-6 text-white relative overflow-hidden">
              <div className="absolute -right-10 -top-10 w-48 h-48 rounded-full bg-white/10 pointer-events-none" />
              <div className="absolute right-6 bottom-6 w-20 h-20 rounded-full bg-white/5 pointer-events-none" />
              <div className="relative z-10">
                <div className="flex items-center gap-3 mb-3">
                  <div className="p-2.5 bg-white/20 rounded-xl">
                    <Brain className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <p className="font-bold text-base">Mental Health Check-In</p>
                    <p className="text-violet-200 text-xs">Depression · Anxiety · Stress Screenings</p>
                  </div>
                </div>
                <p className="text-sm text-white/80 mb-5 leading-relaxed max-w-md">
                  Take an evidence-based screening — PHQ-2, GAD-7, or PSS-10 — to understand how you&apos;ve been feeling and get personalised resources.
                </p>
                <div className="flex flex-wrap gap-2 mb-5">
                  {["Under 5 minutes", "Confidential", "Personalised results"].map(f => (
                    <span key={f} className="text-xs font-semibold bg-white/20 text-white px-3 py-1 rounded-full">{f}</span>
                  ))}
                </div>
                <div className="flex flex-wrap gap-3">
                  <Link href="/surveys"
                    className="inline-flex items-center gap-2 px-5 py-2.5 bg-white text-violet-700 font-bold text-sm rounded-xl hover:bg-violet-50 transition-colors shadow-sm">
                    <Heart className="w-4 h-4" /> Start Check-In
                  </Link>
                  <Link href="/mental-health"
                    className="inline-flex items-center gap-2 px-5 py-2.5 bg-white/20 hover:bg-white/30 text-white font-semibold text-sm rounded-xl transition-colors">
                    <BookOpen className="w-4 h-4" /> View Resources
                  </Link>
                </div>
              </div>
            </div>

            {/* Last Check-In Card */}
            <div className="bg-white rounded-2xl shadow-card p-5 flex flex-col">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Last Check-In Result</p>
              {lastScreening ? (
                <div className="flex-1">
                  <div className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full mb-3 ${
                    lastScreening.total_score <= 2
                      ? "bg-green-100 text-green-700"
                      : "bg-orange-100 text-orange-700"
                  }`}>
                    {lastScreening.total_score <= 2
                      ? <CheckCircle2 className="w-3.5 h-3.5" />
                      : <AlertTriangle className="w-3.5 h-3.5" />}
                    {lastScreening.total_score <= 2 ? "Low Risk" : "Needs Attention"}
                  </div>
                  <p className="text-4xl font-bold text-gray-900 mb-1">
                    {lastScreening.total_score}
                    <span className="text-base text-gray-400 font-normal"> / 6</span>
                  </p>
                  <p className="text-xs text-gray-400">
                    {new Date(lastScreening.created_at).toLocaleDateString("en-KE", {
                      day: "numeric", month: "short", year: "numeric",
                    })}
                  </p>
                  <div className="mt-4 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${lastScreening.total_score <= 2 ? "bg-green-400" : "bg-orange-400"}`}
                      style={{ width: `${(lastScreening.total_score / 6) * 100}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400 mt-1.5">Score: {lastScreening.total_score} out of 6</p>
                </div>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-center py-2">
                  <div className="w-12 h-12 rounded-2xl bg-violet-50 flex items-center justify-center mb-3">
                    <Brain className="w-6 h-6 text-violet-300" />
                  </div>
                  <p className="text-sm font-semibold text-gray-600 mb-1">No check-ins yet</p>
                  <p className="text-xs text-gray-400">Complete your first check-in to track your wellbeing</p>
                </div>
              )}
              <Link href="/surveys"
                className="mt-4 w-full flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 border-violet-200 text-violet-600 hover:bg-violet-50 text-sm font-bold transition-colors">
                <Heart className="w-4 h-4" />
                {lastScreening ? "Check In Again" : "Take First Check-In"}
              </Link>
            </div>
          </div>
        </div>

        {/* Admin module cards (admins always, approved SPs with subscription) */}
        {user && (isAdmin(user) || (isApprovedSP(user) && !subLoading && hasActiveSub)) && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
            <AdminModuleCard
              icon={<Brain className="w-5 h-5 text-violet-600" />}
              iconBg="bg-violet-50"
              title="Mental Health Materials"
              desc="Upload and manage awareness resources"
              viewHref="/admin/mental-health"
              newHref="/admin/mental-health"
            />
            <AdminModuleCard
              icon={<BookOpen className="w-5 h-5 text-indigo-600" />}
              iconBg="bg-indigo-50"
              title="Articles & Blogs"
              desc="Write and publish health articles"
              viewHref="/admin/blogs"
              newHref="/admin/blogs"
            />
            <AdminModuleCard
              icon={<Heart className="w-5 h-5 text-pink-600" />}
              iconBg="bg-pink-50"
              title="Surveys & Screenings"
              desc="Create and manage mental health screening tools"
              viewHref="/admin/surveys"
              newHref="/admin/surveys"
            />
            {isAdmin(user) && (
              <AdminModuleCard
                icon={<Shield className="w-5 h-5 text-purple-600" />}
                iconBg="bg-purple-50"
                title="User Management"
                desc="Manage admins, service providers, and standard users"
                viewHref="/admin/users"
                newHref="/admin/users/new"
              />
            )}
          </div>
        )}

        {/* Reference data — admin only */}
        {user && isAdmin(user) && (
          <>
            <div className="flex items-center gap-2 mb-3">
              <Settings className="w-5 h-5 text-gray-500" />
              <h2 className="text-lg font-bold text-gray-800">Reference Data</h2>
              <span className="text-xs text-gray-400">Configure lookup tables used across the platform</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
              <AdminModuleCard
                icon={<Stethoscope className="w-5 h-5 text-blue-600" />}
                iconBg="bg-blue-50"
                title="Specializations"
                desc="Doctor specialties (Cardiologist, Dentist, …)"
                viewHref="/admin/specializations"
                newHref="/admin/specializations"
              />
              <AdminModuleCard
                icon={<Building2 className="w-5 h-5 text-green-600" />}
                iconBg="bg-green-50"
                title="Facility Types"
                desc="Hospital, Clinic, Lab, Imaging Centre, …"
                viewHref="/admin/facility-types"
                newHref="/admin/facility-types"
              />
              <AdminModuleCard
                icon={<Layers className="w-5 h-5 text-teal-600" />}
                iconBg="bg-teal-50"
                title="Facility Levels"
                desc="Health facility tier classifications"
                viewHref="/admin/facility-levels"
                newHref="/admin/facility-levels"
              />
              <AdminModuleCard
                icon={<ShieldCheck className="w-5 h-5 text-amber-600" />}
                iconBg="bg-amber-50"
                title="Insurances"
                desc="Insurance providers accepted by facilities"
                viewHref="/admin/insurances"
                newHref="/admin/insurances"
              />
              <AdminModuleCard
                icon={<Users className="w-5 h-5 text-orange-600" />}
                iconBg="bg-orange-50"
                title="Group Categories"
                desc="Categories for support groups"
                viewHref="/admin/group-categories"
                newHref="/admin/group-categories"
              />
              <AdminModuleCard
                icon={<Activity className="w-5 h-5 text-rose-600" />}
                iconBg="bg-rose-50"
                title="Conditions"
                desc="Medical conditions used in finders & screenings"
                viewHref="/admin/conditions"
                newHref="/admin/conditions"
              />
              <AdminModuleCard
                icon={<Thermometer className="w-5 h-5 text-purple-600" />}
                iconBg="bg-purple-50"
                title="Symptoms"
                desc="Symptoms used in the doctor finder"
                viewHref="/admin/symptoms"
                newHref="/admin/symptoms"
              />
            </div>
          </>
        )}
      </div>
    </main>
  );
}

function AdminModuleCard({
  icon, iconBg, title, desc, viewHref, newHref, comingSoon,
}: {
  icon: React.ReactNode;
  iconBg: string;
  title: string;
  desc: string;
  viewHref?: string;
  newHref?: string;
  comingSoon?: boolean;
}) {
  return (
    <div className={`bg-white rounded-2xl shadow-card p-5 flex flex-col gap-4 ${comingSoon ? "opacity-60" : ""}`}>
      <div className="flex items-center gap-3">
        <div className={`p-2.5 ${iconBg} rounded-xl`}>{icon}</div>
        <div>
          <p className="text-sm font-bold text-gray-800">{title}</p>
          <p className="text-xs text-gray-400">{desc}</p>
        </div>
      </div>
      {comingSoon ? (
        <div className="py-2 rounded-xl border border-dashed border-gray-200 text-center text-xs text-gray-400">
          Not available yet
        </div>
      ) : (
        <div className="flex gap-2">
          <Link href={viewHref!}
            className="flex-1 text-center py-2 rounded-xl border border-gray-200 text-xs font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
            View All
          </Link>
          <Link href={newHref!}
            className="flex-1 flex items-center justify-center gap-1 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-xs font-semibold text-white transition-colors">
            <Plus className="w-3.5 h-3.5" /> New
          </Link>
        </div>
      )}
    </div>
  );
}
