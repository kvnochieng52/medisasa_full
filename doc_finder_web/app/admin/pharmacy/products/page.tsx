"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ShoppingBag, Plus, Search, ChevronRight, Loader2,
  Pencil, Trash2, AlertTriangle, ShieldAlert, Package,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface MedicalProduct {
  id: number;
  name: string;
  batch_no: string;
  cost: string;
  stock_quantity: number;
  photo?: string;
  image_url?: string;
  manufacturer?: string;
  strength?: string;
  dosage_form?: string;
  expiry_date?: string;
  is_available: boolean;
  needs_prescription: boolean;
  status: "active" | "discontinued" | "out_of_stock";
  is_expired?: boolean;
  days_until_expiry?: number;
}

const STATUS_COLOR = {
  active:         "bg-green-100 text-green-700",
  discontinued:   "bg-gray-100 text-gray-600",
  out_of_stock:   "bg-red-100 text-red-600",
};

export default function MedicalProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState<MedicalProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const fetchProducts = (q = "") => {
    setLoading(true);
    api.get<{ success: boolean; data: { products: MedicalProduct[] } }>("/medical-products", { params: q ? { search: q } : {} })
      .then(res => setProducts(res.data.data?.products ?? []))
      .catch(() => toast.error("Failed to load products"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchProducts(); }, []);

  const handleSearch = (e: React.FormEvent) => { e.preventDefault(); fetchProducts(search); };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    setDeletingId(id);
    try {
      await api.delete(`/medical-products/${id}`);
      toast.success("Product deleted");
      setProducts(p => p.filter(x => x.id !== id));
    } catch {
      toast.error("Failed to delete product");
    } finally {
      setDeletingId(null);
    }
  };

  const isExpiringSoon = (p: MedicalProduct) =>
    p.days_until_expiry !== undefined && p.days_until_expiry >= 0 && p.days_until_expiry <= 30;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-6xl mx-auto px-4 sm:px-6 pt-24 pb-16">

        <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/dashboard" className="hover:text-brand-500">Dashboard</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <Link href="/admin/pharmacy" className="hover:text-brand-500">Pharmacy</Link>
          <ChevronRight className="w-3.5 h-3.5" />
          <span className="text-gray-700 font-medium">Medical Products</span>
        </div>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Medical Products</h1>
            <p className="text-sm text-gray-500 mt-0.5">Manage stock, pricing, and expiry dates</p>
          </div>
          <Link href="/admin/pharmacy/products/new"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors shadow-sm">
            <Plus className="w-4 h-4" /> Add Product
          </Link>
        </div>

        <form onSubmit={handleSearch} className="relative mb-6">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input type="text" placeholder="Search by name, batch number…" value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-24 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-brand-300" />
          <button type="submit" className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1.5 rounded-lg bg-brand-500 text-white text-xs font-semibold hover:bg-brand-600">
            Search
          </button>
        </form>

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : products.length === 0 ? (
          <div className="text-center py-24">
            <div className="w-16 h-16 rounded-2xl bg-purple-50 flex items-center justify-center mx-auto mb-4">
              <ShoppingBag className="w-8 h-8 text-purple-400" />
            </div>
            <h3 className="font-semibold text-gray-700 mb-1">{search ? "No products match your search" : "No products yet"}</h3>
            <p className="text-sm text-gray-400 mb-6">{search ? "Try a different keyword" : "Add your first medical product to get started"}</p>
            {!search && (
              <Link href="/admin/pharmacy/products/new"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 text-white font-semibold text-sm hover:bg-brand-600">
                <Plus className="w-4 h-4" /> Add Product
              </Link>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {products.map(p => {
              const imgSrc = getImageUrl(p.image_url || p.photo);
              const expiring = isExpiringSoon(p);
              const statusColor = STATUS_COLOR[p.status] ?? STATUS_COLOR.active;
              return (
                <div key={p.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow">
                  <div className="relative h-36 bg-gradient-to-br from-purple-50 to-brand-50 flex items-center justify-center">
                    {imgSrc
                      ? <img src={imgSrc} alt={p.name} className="w-full h-full object-cover" />
                      : <Package className="w-12 h-12 text-gray-200" />}
                    <span className={`absolute top-2 right-2 text-xs font-semibold px-2 py-0.5 rounded-full ${statusColor}`}>
                      {p.status.replace("_", " ")}
                    </span>
                    {expiring && (
                      <span className="absolute top-2 left-2 flex items-center gap-1 text-xs font-semibold bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full">
                        <AlertTriangle className="w-3 h-3" /> Expiring
                      </span>
                    )}
                    {p.is_expired && (
                      <span className="absolute top-2 left-2 text-xs font-semibold bg-red-100 text-red-700 px-2 py-0.5 rounded-full">Expired</span>
                    )}
                  </div>
                  <div className="p-4">
                    <h3 className="font-bold text-gray-900 text-sm mb-0.5 line-clamp-1">{p.name}</h3>
                    <p className="text-xs text-gray-400 font-mono mb-3">Batch: {p.batch_no}</p>
                    <div className="grid grid-cols-2 gap-2 mb-3">
                      <div className="bg-gray-50 rounded-lg px-3 py-1.5">
                        <p className="text-xs text-gray-400">Price</p>
                        <p className="text-sm font-bold text-gray-800">KSh {Number(p.cost).toLocaleString()}</p>
                      </div>
                      <div className="bg-gray-50 rounded-lg px-3 py-1.5">
                        <p className="text-xs text-gray-400">Stock</p>
                        <p className={`text-sm font-bold ${p.stock_quantity > 0 ? "text-green-600" : "text-red-500"}`}>
                          {p.stock_quantity} units
                        </p>
                      </div>
                    </div>
                    {p.expiry_date && (
                      <p className="text-xs text-gray-400 mb-3">
                        Expires: {new Date(p.expiry_date).toLocaleDateString("en-KE", { day: "numeric", month: "short", year: "numeric" })}
                        {p.days_until_expiry !== undefined && p.days_until_expiry >= 0 && (
                          <span className={`ml-1 ${expiring ? "text-amber-600 font-semibold" : ""}`}>
                            ({p.days_until_expiry}d)
                          </span>
                        )}
                      </p>
                    )}
                    <div className="flex gap-2 items-center">
                      {p.needs_prescription && <ShieldAlert className="w-3.5 h-3.5 text-amber-500 flex-shrink-0" />}
                      <div className="flex gap-1.5 ml-auto">
                        <button onClick={() => router.push(`/admin/pharmacy/products/${p.id}/edit`)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
                          <Pencil className="w-3.5 h-3.5" /> Edit
                        </button>
                        <button onClick={() => handleDelete(p.id, p.name)}
                          disabled={deletingId === p.id}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-xs font-semibold text-red-600 hover:bg-red-100 transition-colors disabled:opacity-50">
                          {deletingId === p.id ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
