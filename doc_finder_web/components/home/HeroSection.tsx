"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Search, Stethoscope, Building2, Pill, Users, ChevronRight, Sparkles } from "lucide-react";
import { getGreeting } from "@/lib/utils";

const quickLinks = [
  { icon: Stethoscope, label: "Find Doctor", href: "/doctors", color: "bg-blue-50 text-blue-600" },
  { icon: Building2,   label: "Hospital",    href: "/hospitals", color: "bg-green-50 text-green-600" },
  { icon: Pill,        label: "Pharmacy",    href: "/pharmacy",  color: "bg-brand-50 text-brand-600" },
  { icon: Users,       label: "Support",     href: "/support-groups", color: "bg-orange-50 text-orange-600" },
];

export default function HeroSection() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState("");
  const [greeting, setGreeting] = useState("Good Morning");
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setGreeting(getGreeting());
    setMounted(true);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    router.push(`/doctors?q=${encodeURIComponent(searchQuery.trim())}`);
  };

  return (
    <section className="relative overflow-hidden pt-24 pb-10 bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white">
      {/* Decorative blobs */}
      <div className="absolute -top-24 -right-24 w-96 h-96 rounded-full blur-3xl opacity-30 bg-brand-200" />
      <div className="absolute -bottom-16 -left-16 w-72 h-72 rounded-full blur-3xl opacity-20 bg-brand-100" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-10 items-center">
          {/* Left content */}
          <div>
            {/* Greeting badge */}
            {mounted && (
              <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-sm font-medium mb-5 bg-brand-50 text-brand-600 border border-brand-200">
                <Sparkles className="w-3.5 h-3.5" />
                {greeting}!
              </div>
            )}

            <h1 className="text-4xl sm:text-5xl font-bold leading-tight mb-4 text-gray-900">
              Your Health,{" "}
              <span className="text-brand-500">Our Priority</span>
            </h1>
            <p className="text-lg mb-8 leading-relaxed max-w-lg text-gray-600">
              Find qualified doctors, top hospitals, pharmacies, and mental
              health support groups — all in one place. Book appointments
              instantly.
            </p>

            {/* Search bar */}
            <form onSubmit={handleSearch} className="mb-8">
              <div className="flex items-center gap-3 p-2 rounded-2xl shadow-lg bg-white border border-brand-200">
                <div className="flex-1 flex items-center gap-3 pl-2">
                  <Search className="w-5 h-5 flex-shrink-0 text-brand-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search doctors, specialties, hospitals..."
                    className="flex-1 outline-none text-sm bg-transparent text-gray-800 placeholder-gray-400"
                  />
                </div>
                <button type="submit" className="btn-primary text-sm px-5 py-2.5 flex-shrink-0">
                  Search
                </button>
              </div>
            </form>

            {/* Quick access icons */}
            <div className="flex flex-wrap gap-3">
              {quickLinks.map(({ icon: Icon, label, href, color }) => (
                <Link
                  key={href}
                  href={href}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-xl border transition-all duration-200 hover:scale-105 hover:shadow-md bg-white border-gray-100 text-gray-700 hover:border-brand-300"
                >
                  <span className={`p-1.5 rounded-lg ${color}`}>
                    <Icon className="w-4 h-4" />
                  </span>
                  <span className="text-sm font-medium">{label}</span>
                  <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
                </Link>
              ))}
            </div>
          </div>

          {/* Right — stats + illustration */}
          <div className="hidden lg:flex flex-col gap-4 items-end">
            {/* Stats cards */}
            <div className="grid grid-cols-2 gap-4 w-full max-w-sm">
              {[
                { value: "2,500+", label: "Verified Doctors", icon: Stethoscope, color: "text-brand-500" },
                { value: "300+",   label: "Hospitals",         icon: Building2,   color: "text-green-500" },
                { value: "150+",   label: "Pharmacies",        icon: Pill,        color: "text-brand-500" },
                { value: "50+",    label: "Support Groups",    icon: Users,       color: "text-orange-500" },
              ].map(({ value, label, icon: Icon, color }) => (
                <div key={label} className="rounded-2xl p-5 shadow-card bg-white">
                  <Icon className={`w-6 h-6 mb-2 ${color}`} />
                  <div className="text-2xl font-bold text-gray-900">{value}</div>
                  <div className="text-xs mt-0.5 text-gray-500">{label}</div>
                </div>
              ))}
            </div>

            {/* CTA card */}
            <div className="w-full max-w-sm rounded-2xl p-5 border bg-white border-gray-100 shadow-card">
              <p className="text-sm font-medium mb-3 text-gray-700">
                Are you a healthcare provider?
              </p>
              <Link
                href="/register?type=provider"
                className="btn-primary text-sm w-full flex items-center justify-center gap-2"
              >
                Join as Provider
                <ChevronRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
