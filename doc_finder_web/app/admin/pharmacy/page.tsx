"use client";

import Link from "next/link";
import { ChevronRight, Pill, ShoppingBag, Plus, ArrowRight } from "lucide-react";
import Navbar from "@/components/Navbar";

export default function PharmacyHubPage() {
  const modules = [
    {
      icon: <Pill className="w-8 h-8 text-brand-500" />,
      bg: "bg-brand-50",
      title: "Medicines",
      desc: "Manage your medicine catalogue — add, edit, and track prescription and OTC medicines.",
      viewHref: "/admin/pharmacy/medicines",
      newHref: "/admin/pharmacy/medicines/new",
      newLabel: "Add Medicine",
    },
    {
      icon: <ShoppingBag className="w-8 h-8 text-purple-500" />,
      bg: "bg-purple-50",
      title: "Medical Products",
      desc: "Manage medical supplies and products — stock levels, expiry dates, and pricing.",
      viewHref: "/admin/pharmacy/products",
      newHref: "/admin/pharmacy/products/new",
      newLabel: "Add Product",
    },
  ];

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 pt-24 pb-16">

        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500 transition-colors">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Pharmacy</span>
        </div>

        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Pharmacy Management</h1>
          <p className="text-gray-500 text-sm mt-1">Manage your medicines and medical products inventory</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {modules.map(m => (
            <div key={m.title} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
              <div className={`w-14 h-14 rounded-xl ${m.bg} flex items-center justify-center mb-4`}>
                {m.icon}
              </div>
              <h2 className="text-lg font-bold text-gray-900 mb-1">{m.title}</h2>
              <p className="text-sm text-gray-500 mb-6 flex-1">{m.desc}</p>
              <div className="flex gap-3">
                <Link href={m.viewHref}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
                  View All <ArrowRight className="w-4 h-4" />
                </Link>
                <Link href={m.newHref}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-sm font-semibold transition-colors shadow-sm">
                  <Plus className="w-4 h-4" /> {m.newLabel}
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
