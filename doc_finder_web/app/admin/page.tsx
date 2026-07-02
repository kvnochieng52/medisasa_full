"use client";

import { useEffect, useState, ComponentType } from "react";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  Shield, Stethoscope, Building2, Layers, ShieldCheck, Users,
  Activity, Thermometer, BookOpen, Heart, Brain, Pill, Settings, FileText,
} from "lucide-react";

interface UserData {
  account_type?: number | string | null;
  sp_approved?: number | null;
}

function isAdmin(u: UserData) {
  return Number(u.account_type) === 3;
}

interface AdminCard {
  title: string;
  desc: string;
  href: string;
  icon: ComponentType<{ className?: string }>;
  iconBg: string;
  iconColor: string;
  /** Visible to admins only (false = also to approved SPs) */
  adminOnly?: boolean;
}

const SECTIONS: { heading: string; subtitle: string; items: AdminCard[] }[] = [
  {
    heading: "People",
    subtitle: "Users, service providers, and patient communication",
    items: [
      {
        title: "Users", desc: "All accounts — standard users, admins, service providers",
        href: "/admin/users", icon: Shield, iconBg: "bg-purple-50", iconColor: "text-purple-600",
      },
      {
        title: "Service Providers", desc: "Approve, decline, and manage doctor accounts",
        href: "/admin/service-providers", icon: Stethoscope, iconBg: "bg-blue-50", iconColor: "text-blue-600",
      },
    ],
  },
  {
    heading: "Content",
    subtitle: "Articles, mental health resources, and surveys",
    items: [
      {
        title: "Articles & Blogs", desc: "Write and publish health articles",
        href: "/admin/blogs", icon: BookOpen, iconBg: "bg-indigo-50", iconColor: "text-indigo-600",
      },
      {
        title: "Mental Health Materials", desc: "Upload and manage awareness resources",
        href: "/admin/mental-health", icon: Brain, iconBg: "bg-violet-50", iconColor: "text-violet-600",
      },
      {
        title: "Surveys & Screenings", desc: "Create and manage mental health screening tools",
        href: "/admin/surveys", icon: Heart, iconBg: "bg-pink-50", iconColor: "text-pink-600",
      },
    ],
  },
  {
    heading: "Operations",
    subtitle: "Facilities, support groups, pharmacy, and prescriptions",
    items: [
      {
        title: "Facilities", desc: "Manage clinics, hospitals and labs",
        href: "/admin/facilities", icon: Building2, iconBg: "bg-blue-50", iconColor: "text-blue-600",
      },
      {
        title: "Support Groups", desc: "Create and manage support groups",
        href: "/admin/support-groups", icon: Users, iconBg: "bg-orange-50", iconColor: "text-orange-600",
      },
      {
        title: "Pharmacy", desc: "Medicines, products, and inventory",
        href: "/admin/pharmacy", icon: Pill, iconBg: "bg-purple-50", iconColor: "text-purple-600",
      },
      {
        title: "Prescriptions", desc: "All medication and lab prescriptions you've issued",
        href: "/prescriptions", icon: FileText, iconBg: "bg-cyan-50", iconColor: "text-cyan-600",
      },
    ],
  },
  {
    heading: "Reference Data",
    subtitle: "Configure lookup tables used across the platform",
    items: [
      {
        title: "Specializations", desc: "Doctor specialties (Cardiologist, Dentist, …)",
        href: "/admin/specializations", icon: Stethoscope, iconBg: "bg-blue-50", iconColor: "text-blue-600",
      },
      {
        title: "Facility Types", desc: "Hospital, Clinic, Lab, Imaging Centre, …",
        href: "/admin/facility-types", icon: Building2, iconBg: "bg-green-50", iconColor: "text-green-600",
      },
      {
        title: "Facility Services", desc: "Catalogue of services facilities offer (Consultation, X-Ray, …)",
        href: "/admin/facility-services", icon: Building2, iconBg: "bg-cyan-50", iconColor: "text-cyan-600",
      },
      {
        title: "Facility Levels", desc: "Health facility tier classifications",
        href: "/admin/facility-levels", icon: Layers, iconBg: "bg-teal-50", iconColor: "text-teal-600",
      },
      {
        title: "Insurances", desc: "Insurance providers accepted by facilities",
        href: "/admin/insurances", icon: ShieldCheck, iconBg: "bg-amber-50", iconColor: "text-amber-600",
      },
      {
        title: "Group Categories", desc: "Categories for support groups",
        href: "/admin/group-categories", icon: Users, iconBg: "bg-orange-50", iconColor: "text-orange-600",
      },
      {
        title: "Conditions", desc: "Medical conditions used in finders & screenings",
        href: "/admin/conditions", icon: Activity, iconBg: "bg-rose-50", iconColor: "text-rose-600",
      },
      {
        title: "Symptoms", desc: "Symptoms used in the doctor finder",
        href: "/admin/symptoms", icon: Thermometer, iconBg: "bg-purple-50", iconColor: "text-purple-600",
      },
    ],
  },
];

export default function AdminIndexPage() {
  const [user, setUser] = useState<UserData | null>(null);

  useEffect(() => {
    const raw = localStorage.getItem("user_data");
    if (raw) {
      try { setUser(JSON.parse(raw)); } catch { /* ignore */ }
    }
  }, []);

  const userIsAdmin = !!user && isAdmin(user);
  const canSee = userIsAdmin;

  const visibleSections = SECTIONS
    .map(s => ({ ...s, items: s.items.filter(i => userIsAdmin || !i.adminOnly) }))
    .filter(s => s.items.length > 0);

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="max-w-6xl mx-auto px-4 pt-28 pb-16">
        {/* Header */}
        <div className="flex items-center gap-3 mb-2">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-purple-500 to-fuchsia-600 flex items-center justify-center shadow-sm">
            <Settings className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Admin Console</h1>
            <p className="text-sm text-gray-400">
              {userIsAdmin
                ? "Manage everything across MediSasa"
                : "Admin access required"}
            </p>
          </div>
        </div>

        {!canSee ? (
          <div className="mt-10 text-center py-16 bg-white rounded-2xl border border-gray-100">
            <Shield className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-1">You don&apos;t have admin access</p>
            <p className="text-sm text-gray-400 mb-5">Only admins can use this console.</p>
            <Link href="/dashboard" className="inline-flex items-center gap-2 px-5 py-2.5 bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm rounded-xl transition-colors">
              Back to dashboard
            </Link>
          </div>
        ) : (
          <div className="mt-8 space-y-10">
            {visibleSections.map(section => (
              <section key={section.heading}>
                <div className="mb-4">
                  <h2 className="text-lg font-bold text-gray-800">{section.heading}</h2>
                  <p className="text-xs text-gray-400">{section.subtitle}</p>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {section.items.map(item => (
                    <Link
                      key={item.href}
                      href={item.href}
                      className="bg-white rounded-2xl shadow-card p-5 hover:shadow-card-hover transition-all hover:-translate-y-0.5 group"
                    >
                      <div className="flex items-start gap-3">
                        <div className={`p-2.5 ${item.iconBg} rounded-xl flex-shrink-0`}>
                          <item.icon className={`w-5 h-5 ${item.iconColor}`} />
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-bold text-gray-800 group-hover:text-brand-600 transition-colors">
                            {item.title}
                          </p>
                          <p className="text-xs text-gray-400 mt-0.5 line-clamp-2">{item.desc}</p>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
