"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Pill, Plus, Search, ChevronRight, Loader2,
  Pencil, Trash2, ShieldAlert, Package, Tag,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Medicine {
  id: number;
  name: string;
  medicine_number: string;
  cost: string;
  image?: string;
  quantity_available: number;
  requires_prescription: boolean;
  is_active: boolean;
  strength?: string;
  form?: string;
  manufacturer?: string;
  category?: { id: number; name: string };
}

export default function MedicinesPage() {
  const router = useRouter();
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const fetchMedicines = (q = "") => {
    setLoading(true);
    api.get<{ success: boolean; medicines: Medicine[] }>("/medicines", { params: q ? { search: q } : {} })
      .then(res => setMedicines(res.data.medicines ?? []))
      .catch(() => toast.error("Failed to load medicines"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchMedicines(); }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchMedicines(search);
  };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    setDeletingId(id);
    try {
      await api.delete(`/medicines/${id}`);
      toast.success("Medicine deleted");
      setMedicines(m => m.filter(x => x.id !== id));
    } catch {
      toast.error("Failed to delete medicine");
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-6xl mx-auto px-4 sm:px-6 pt-24 pb-16">

        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy" className="hover:text-brand-500">Pharmacy</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Medicines</span>
        </div>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Medicines</h1>
            <p className="text-sm text-gray-500 mt-0.5">Manage your medicine catalogue</p>
          </div>
          <Link href="/admin/pharmacy/medicines/new"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors shadow-sm">
            <Plus className="w-4 h-4" /> Add Medicine
          </Link>
        </div>

        {/* Search */}
        <form onSubmit={handleSearch} className="relative mb-6">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search by name, medicine number, manufacturer…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-24 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-brand-300"
          />
          <button type="submit" className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1.5 rounded-lg bg-brand-500 text-white text-xs font-semibold hover:bg-brand-600">
            Search
          </button>
        </form>

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : medicines.length === 0 ? (
          <div className="text-center py-24">
            <div className="w-16 h-16 rounded-2xl bg-brand-50 flex items-center justify-center mx-auto mb-4">
              <Pill className="w-8 h-8 text-brand-400" />
            </div>
            <h3 className="font-semibold text-gray-700 mb-1">
              {search ? "No medicines match your search" : "No medicines yet"}
            </h3>
            <p className="text-sm text-gray-400 mb-6">
              {search ? "Try a different keyword" : "Add your first medicine to get started"}
            </p>
            {!search && (
              <Link href="/admin/pharmacy/medicines/new"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 text-white font-semibold text-sm hover:bg-brand-600 transition-colors">
                <Plus className="w-4 h-4" /> Add Medicine
              </Link>
            )}
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-left px-5 py-3 font-semibold text-gray-600">Medicine</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600 hidden sm:table-cell">Med. No.</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600 hidden md:table-cell">Category</th>
                  <th className="text-right px-4 py-3 font-semibold text-gray-600">Price</th>
                  <th className="text-right px-4 py-3 font-semibold text-gray-600 hidden sm:table-cell">Stock</th>
                  <th className="text-center px-4 py-3 font-semibold text-gray-600 hidden lg:table-cell">Rx</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {medicines.map(m => {
                  const imgSrc = getImageUrl(m.image);
                  return (
                    <tr key={m.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-gray-100 flex-shrink-0 overflow-hidden flex items-center justify-center">
                            {imgSrc
                              ? <img src={imgSrc} alt={m.name} className="w-full h-full object-cover" />
                              : <Pill className="w-5 h-5 text-gray-300" />}
                          </div>
                          <div>
                            <p className="font-semibold text-gray-800 leading-tight">{m.name}</p>
                            {(m.strength || m.form) && (
                              <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                                <Tag className="w-3 h-3" />
                                {[m.strength, m.form].filter(Boolean).join(" · ")}
                              </p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-gray-500 hidden sm:table-cell font-mono text-xs">{m.medicine_number}</td>
                      <td className="px-4 py-3 hidden md:table-cell">
                        {m.category && (
                          <span className="text-xs bg-brand-50 text-brand-600 font-semibold px-2 py-0.5 rounded-full">{m.category.name}</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right font-semibold text-gray-800">
                        KSh {Number(m.cost).toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-right hidden sm:table-cell">
                        <span className={`font-semibold ${m.quantity_available > 0 ? "text-green-600" : "text-red-500"}`}>
                          {m.quantity_available}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-center hidden lg:table-cell">
                        {m.requires_prescription && (
                          <ShieldAlert className="w-4 h-4 text-amber-500 mx-auto" />
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1.5 justify-end">
                          <button onClick={() => router.push(`/admin/pharmacy/medicines/${m.id}/edit`)}
                            className="p-1.5 rounded-lg hover:bg-brand-50 text-gray-500 hover:text-brand-600 transition-colors">
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button onClick={() => handleDelete(m.id, m.name)}
                            disabled={deletingId === m.id}
                            className="p-1.5 rounded-lg hover:bg-red-50 text-gray-500 hover:text-red-500 transition-colors disabled:opacity-50">
                            {deletingId === m.id ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <div className="px-5 py-3 border-t border-gray-100 text-sm text-gray-400">
              {medicines.length} medicine{medicines.length !== 1 ? "s" : ""}
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
