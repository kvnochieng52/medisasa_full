"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  Search, X, Pill, Package, ShieldAlert, AlertTriangle,
  Heart, ShoppingCart, SlidersHorizontal, ChevronDown,
  Upload, Tag, RefreshCw, Star,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { useCart } from "@/lib/context/CartContext";
import toast from "react-hot-toast";

/* ─── Types ─────────────────────────────────────────────── */
interface Category { id: number; name: string }

interface Medicine {
  id: number;
  name: string;
  medicine_number?: string;
  cost: string;
  description?: string;
  strength?: string;
  form?: string;
  quantity_available?: number;
  requires_prescription?: boolean;
  image?: string;
  category?: Category;
  conditions?: string[];
}

interface MedicalProduct {
  id: number;
  name: string;
  product_code?: string;
  price?: string;
  description?: string;
  status?: string;
  expiry_date?: string;
  stock_quantity?: number;
  image_url?: string;
  photo?: string;
  category?: Category;
}

type Tab = "medicines" | "products";
type SortKey = "default" | "price_asc" | "price_desc" | "name";

const DOSAGE_FORMS = ["Tablet","Capsule","Syrup","Injection","Cream","Drops","Powder","Patch","Other"];

/* ─── Skeleton card ──────────────────────────────────────── */
function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden animate-pulse">
      <div className="aspect-square bg-gray-100" />
      <div className="p-3 space-y-2">
        <div className="h-3 bg-gray-100 rounded w-3/4" />
        <div className="h-4 bg-gray-200 rounded w-1/2" />
        <div className="h-8 bg-gray-100 rounded" />
      </div>
    </div>
  );
}

/* ─── Medicine card ──────────────────────────────────────── */
function MedicineCard({ m, wishlisted, onWishlist, onAddToCart }: { m: Medicine; wishlisted: boolean; onWishlist: () => void; onAddToCart: () => void }) {
  const img = getImageUrl(m.image);
  const price = parseFloat(m.cost);
  const inStock = (m.quantity_available ?? 0) > 0;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden group hover:shadow-md transition-shadow flex flex-col">
      {/* Image area — links to detail */}
      <Link href={`/pharmacy/medicines/${m.id}`} className="relative aspect-square bg-gray-50 flex items-center justify-center overflow-hidden">
        {img
          ? <img src={img} alt={m.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
          : <Pill className="w-12 h-12 text-orange-200" />}

        {/* Rx badge */}
        {m.requires_prescription && (
          <span className="absolute top-2 left-2 bg-amber-500 text-white text-[10px] font-bold px-2 py-0.5 rounded">Rx</span>
        )}

        {/* Out of stock overlay */}
        {!inStock && (
          <div className="absolute inset-0 bg-white/60 flex items-center justify-center">
            <span className="text-xs font-bold text-gray-500 bg-white px-2 py-1 rounded shadow-sm">Out of Stock</span>
          </div>
        )}

        {/* Wishlist */}
        <button
          onClick={e => { e.preventDefault(); e.stopPropagation(); onWishlist(); }}
          className="absolute top-2 right-2 w-7 h-7 rounded-full bg-white shadow-sm flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:scale-110">
          <Heart className={`w-3.5 h-3.5 ${wishlisted ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
        </button>
      </Link>

      {/* Info */}
      <Link href={`/pharmacy/medicines/${m.id}`} className="p-3 flex flex-col flex-1">
        <p className="text-[10px] text-gray-400 font-medium uppercase tracking-wide mb-0.5">
          {m.category?.name ?? "Medicine"}
        </p>
        <h3 className="text-sm font-semibold text-gray-900 leading-snug line-clamp-2 flex-1 group-hover:text-orange-600 transition-colors">{m.name}</h3>
        {m.strength && <p className="text-xs text-gray-500 mt-0.5">{m.strength}{m.form ? ` · ${m.form}` : ""}</p>}

        <div className="mt-2">
          <p className="text-base font-bold text-gray-900">KSh {price.toLocaleString()}</p>
        </div>
      </Link>

      <div className="px-3 pb-3">
        <button
          disabled={!inStock}
          onClick={onAddToCart}
          className={`w-full flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-bold transition-colors ${
            inStock
              ? "bg-orange-500 hover:bg-orange-600 active:scale-95 text-white"
              : "bg-gray-100 text-gray-400 cursor-not-allowed"
          }`}>
          <ShoppingCart className="w-3.5 h-3.5" />
          {inStock ? "Add to Cart" : "Notify Me"}
        </button>
      </div>
    </div>
  );
}

/* ─── Product card ───────────────────────────────────────── */
function ProductCard({ p, wishlisted, onWishlist, onAddToCart }: { p: MedicalProduct; wishlisted: boolean; onWishlist: () => void; onAddToCart: () => void }) {
  const img = getImageUrl(p.image_url || p.photo);
  const price = p.price ? parseFloat(p.price) : null;
  const inStock = (p.stock_quantity ?? 1) > 0;
  const expired = p.expiry_date ? new Date(p.expiry_date).getTime() < Date.now() : false;
  const expiring = !expired && p.expiry_date
    ? Math.ceil((new Date(p.expiry_date).getTime() - Date.now()) / 86400000) <= 30
    : false;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden group hover:shadow-md transition-shadow flex flex-col">
      <Link href={`/pharmacy/products/${p.id}`} className="relative aspect-square bg-gray-50 flex items-center justify-center overflow-hidden">
        {img
          ? <img src={img} alt={p.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
          : <Package className="w-12 h-12 text-orange-200" />}

        {expired && (
          <span className="absolute top-2 left-2 bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded">Expired</span>
        )}
        {expiring && !expired && (
          <span className="absolute top-2 left-2 bg-amber-500 text-white text-[10px] font-bold px-2 py-0.5 rounded flex items-center gap-0.5">
            <AlertTriangle className="w-2.5 h-2.5" /> Expiring
          </span>
        )}

        {!inStock && (
          <div className="absolute inset-0 bg-white/60 flex items-center justify-center">
            <span className="text-xs font-bold text-gray-500 bg-white px-2 py-1 rounded shadow-sm">Out of Stock</span>
          </div>
        )}

        <button
          onClick={e => { e.preventDefault(); e.stopPropagation(); onWishlist(); }}
          className="absolute top-2 right-2 w-7 h-7 rounded-full bg-white shadow-sm flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:scale-110">
          <Heart className={`w-3.5 h-3.5 ${wishlisted ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
        </button>
      </Link>

      <Link href={`/pharmacy/products/${p.id}`} className="p-3 flex flex-col flex-1">
        <p className="text-[10px] text-gray-400 font-medium uppercase tracking-wide mb-0.5">
          {p.category?.name ?? "Medical Product"}
        </p>
        <h3 className="text-sm font-semibold text-gray-900 leading-snug line-clamp-2 flex-1 group-hover:text-orange-600 transition-colors">{p.name}</h3>
        {p.product_code && <p className="text-xs text-gray-400 mt-0.5">{p.product_code}</p>}

        <div className="mt-2">
          {price !== null
            ? <p className="text-base font-bold text-gray-900">KSh {price.toLocaleString()}</p>
            : <p className="text-xs text-gray-400 italic">Price on request</p>}
        </div>
      </Link>

      <div className="px-3 pb-3">
        <button
          disabled={!inStock || expired}
          onClick={onAddToCart}
          className={`w-full flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-bold transition-colors ${
            inStock && !expired
              ? "bg-orange-500 hover:bg-orange-600 active:scale-95 text-white"
              : "bg-gray-100 text-gray-400 cursor-not-allowed"
          }`}>
          <ShoppingCart className="w-3.5 h-3.5" />
          {inStock && !expired ? "Add to Cart" : "Notify Me"}
        </button>
      </div>
    </div>
  );
}

/* ─── Main Page ──────────────────────────────────────────── */
export default function PharmacyPage() {
  const { addToCart } = useCart();
  const [tab, setTab] = useState<Tab>("medicines");

  // Data
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [products, setProducts] = useState<MedicalProduct[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [medsLoading, setMedsLoading] = useState(true);
  const [prodsLoading, setProdsLoading] = useState(true);
  const [medsError, setMedsError] = useState(false);
  const [prodsError, setProdsError] = useState(false);

  // Filters
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("");
  const [selectedForm, setSelectedForm] = useState("");
  const [sortBy, setSortBy] = useState<SortKey>("default");
  const [showFilters, setShowFilters] = useState(false);
  const [wishlist, setWishlist] = useState<Set<string>>(new Set());

  // Trending searches
  const trendingSearches = ["Paracetamol", "Vitamin C", "Ibuprofen", "Amoxicillin", "Metformin"];

  useEffect(() => {
    api.get("/medicines", { params: { per_page: 100 } })
      .then(res => setMedicines(Array.isArray(res.data?.medicines) ? res.data.medicines : []))
      .catch(() => setMedsError(true))
      .finally(() => setMedsLoading(false));

    api.get("/public-medical-products", { params: { per_page: 100 } })
      .then(res => {
        const list = Array.isArray(res.data?.data?.products)
          ? res.data.data.products
          : Array.isArray(res.data?.data) ? res.data.data : [];
        setProducts(list);
      })
      .catch(() => setProdsError(true))
      .finally(() => setProdsLoading(false));

    api.get("/medicine-categories")
      .then(res => setCategories(Array.isArray(res.data?.categories) ? res.data.categories : []))
      .catch(() => {});
  }, []);

  const applyMedFilters = useCallback((
    list: Medicine[], q: string, cat: string, form: string, sort: SortKey
  ) => {
    let r = list;
    if (q.trim()) {
      const lq = q.toLowerCase();
      r = r.filter(m =>
        m.name.toLowerCase().includes(lq) ||
        m.category?.name.toLowerCase().includes(lq) ||
        m.conditions?.some(c => c.toLowerCase().includes(lq)) ||
        m.form?.toLowerCase().includes(lq)
      );
    }
    if (cat) r = r.filter(m => String(m.category?.id) === cat);
    if (form) r = r.filter(m => m.form?.toLowerCase() === form.toLowerCase());
    if (sort === "price_asc") r = [...r].sort((a, b) => parseFloat(a.cost) - parseFloat(b.cost));
    if (sort === "price_desc") r = [...r].sort((a, b) => parseFloat(b.cost) - parseFloat(a.cost));
    if (sort === "name") r = [...r].sort((a, b) => a.name.localeCompare(b.name));
    return r;
  }, []);

  const applyProdFilters = useCallback((
    list: MedicalProduct[], q: string, cat: string, sort: SortKey
  ) => {
    let r = list;
    if (q.trim()) {
      const lq = q.toLowerCase();
      r = r.filter(p =>
        p.name.toLowerCase().includes(lq) ||
        p.category?.name?.toLowerCase().includes(lq) ||
        p.product_code?.toLowerCase().includes(lq)
      );
    }
    if (cat) r = r.filter(p => String(p.category?.id) === cat);
    if (sort === "price_asc") r = [...r].sort((a, b) => parseFloat(a.price ?? "0") - parseFloat(b.price ?? "0"));
    if (sort === "price_desc") r = [...r].sort((a, b) => parseFloat(b.price ?? "0") - parseFloat(a.price ?? "0"));
    if (sort === "name") r = [...r].sort((a, b) => a.name.localeCompare(b.name));
    return r;
  }, []);

  const filteredMeds = applyMedFilters(medicines, search, selectedCategory, selectedForm, sortBy);
  const filteredProds = applyProdFilters(products, search, selectedCategory, sortBy);

  const toggleWishlist = (key: string) => {
    setWishlist(prev => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
  };

  const loading = tab === "medicines" ? medsLoading : prodsLoading;
  const error = tab === "medicines" ? medsError : prodsError;
  const items = tab === "medicines" ? filteredMeds : filteredProds;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* ── Top header banner ── */}
      <div className="bg-orange-500 pt-20 pb-6 px-4">
        <div className="max-w-6xl mx-auto">
          {/* Branding row */}
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center">
                <Pill className="w-5 h-5 text-orange-500" />
              </div>
              <div>
                <h1 className="text-xl font-extrabold text-white leading-tight">Pharmacy</h1>
                <p className="text-orange-100 text-xs">Medicines & Healthcare Products</p>
              </div>
            </div>
            <button className="hidden sm:flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white text-xs font-semibold px-3 py-2 rounded-xl transition-colors">
              <Upload className="w-3.5 h-3.5" /> Upload Prescription
            </button>
          </div>

          {/* Search bar */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="What Are You Looking For?"
              className="w-full pl-11 pr-10 py-4 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm text-gray-800 placeholder:text-gray-400"
            />
            {search && (
              <button onClick={() => setSearch("")} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Trending quick searches */}
          {!search && (
            <div className="flex items-center gap-2 mt-3 flex-wrap">
              <span className="text-orange-200 text-xs font-medium">Trending:</span>
              {trendingSearches.map(t => (
                <button key={t} onClick={() => setSearch(t)}
                  className="text-xs font-semibold text-white bg-white/20 hover:bg-white/30 px-3 py-1 rounded-full transition-colors">
                  {t}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Tab bar ── */}
      <div className="bg-white border-b border-gray-200 sticky top-16 z-30 shadow-sm">
        <div className="max-w-6xl mx-auto px-4">
          <div className="flex items-center gap-0 overflow-x-auto scrollbar-hide">
            {[
              { key: "medicines" as Tab, icon: Pill, label: "Medicines", count: medicines.length },
              { key: "products" as Tab, icon: Package, label: "Medical Products", count: products.length },
            ].map(t => (
              <button key={t.key} onClick={() => { setTab(t.key); setSelectedCategory(""); setSelectedForm(""); }}
                className={`flex items-center gap-2 px-5 py-4 text-sm font-semibold border-b-2 transition-colors whitespace-nowrap ${
                  tab === t.key
                    ? "border-orange-500 text-orange-500"
                    : "border-transparent text-gray-500 hover:text-gray-700"
                }`}>
                <t.icon className="w-4 h-4" />
                {t.label}
                {t.count > 0 && (
                  <span className={`text-xs px-1.5 py-0.5 rounded-full ${tab === t.key ? "bg-orange-100 text-orange-600" : "bg-gray-100 text-gray-500"}`}>
                    {t.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Main content ── */}
      <div className="max-w-6xl mx-auto px-4 py-6 pb-16">
        <div className="flex gap-6">

          {/* ── Sidebar filters ── */}
          <aside className={`
            w-56 flex-shrink-0 space-y-4
            ${showFilters ? "block" : "hidden lg:block"}
          `}>

            {/* Category filter */}
            {categories.length > 0 && (
              <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-4">
                <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Category</h4>
                <div className="space-y-1">
                  <button onClick={() => setSelectedCategory("")}
                    className={`w-full text-left text-sm px-2 py-1.5 rounded-lg transition-colors ${!selectedCategory ? "bg-orange-50 text-orange-600 font-semibold" : "text-gray-600 hover:bg-gray-50"}`}>
                    All Categories
                  </button>
                  {categories.map(c => (
                    <button key={c.id} onClick={() => setSelectedCategory(String(c.id))}
                      className={`w-full text-left text-sm px-2 py-1.5 rounded-lg transition-colors ${selectedCategory === String(c.id) ? "bg-orange-50 text-orange-600 font-semibold" : "text-gray-600 hover:bg-gray-50"}`}>
                      {c.name}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Dosage form (medicines only) */}
            {tab === "medicines" && (
              <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-4">
                <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Dosage Form</h4>
                <div className="space-y-1">
                  <button onClick={() => setSelectedForm("")}
                    className={`w-full text-left text-sm px-2 py-1.5 rounded-lg transition-colors ${!selectedForm ? "bg-orange-50 text-orange-600 font-semibold" : "text-gray-600 hover:bg-gray-50"}`}>
                    All Forms
                  </button>
                  {DOSAGE_FORMS.map(f => (
                    <button key={f} onClick={() => setSelectedForm(f.toLowerCase())}
                      className={`w-full text-left text-sm px-2 py-1.5 rounded-lg capitalize transition-colors ${selectedForm === f.toLowerCase() ? "bg-orange-50 text-orange-600 font-semibold" : "text-gray-600 hover:bg-gray-50"}`}>
                      {f}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Sort */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-4">
              <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Sort By</h4>
              <div className="space-y-1">
                {[
                  { key: "default" as SortKey, label: "Recommended" },
                  { key: "name" as SortKey, label: "Name A–Z" },
                  { key: "price_asc" as SortKey, label: "Price: Low to High" },
                  { key: "price_desc" as SortKey, label: "Price: High to Low" },
                ].map(s => (
                  <button key={s.key} onClick={() => setSortBy(s.key)}
                    className={`w-full text-left text-sm px-2 py-1.5 rounded-lg transition-colors ${sortBy === s.key ? "bg-orange-50 text-orange-600 font-semibold" : "text-gray-600 hover:bg-gray-50"}`}>
                    {s.label}
                  </button>
                ))}
              </div>
            </div>
          </aside>

          {/* ── Product area ── */}
          <div className="flex-1 min-w-0">

            {/* Toolbar */}
            <div className="flex items-center justify-between mb-5">
              <div className="flex items-center gap-3">
                <button onClick={() => setShowFilters(!showFilters)}
                  className="lg:hidden flex items-center gap-2 bg-white border border-gray-200 text-sm font-semibold text-gray-600 px-3 py-2 rounded-xl hover:border-orange-300 transition-colors">
                  <SlidersHorizontal className="w-4 h-4" /> Filters
                </button>
                <p className="text-sm text-gray-500">
                  {loading ? "Loading…" : `${items.length} ${tab === "medicines" ? "medicine" : "product"}${items.length !== 1 ? "s" : ""}`}
                </p>
              </div>

              {/* Active filters chips */}
              <div className="flex items-center gap-2 flex-wrap justify-end">
                {selectedCategory && categories.find(c => String(c.id) === selectedCategory) && (
                  <span className="flex items-center gap-1 text-xs font-semibold bg-orange-100 text-orange-700 px-2.5 py-1 rounded-full">
                    {categories.find(c => String(c.id) === selectedCategory)?.name}
                    <button onClick={() => setSelectedCategory("")} className="hover:text-orange-900"><X className="w-3 h-3" /></button>
                  </span>
                )}
                {selectedForm && (
                  <span className="flex items-center gap-1 text-xs font-semibold bg-orange-100 text-orange-700 px-2.5 py-1 rounded-full capitalize">
                    {selectedForm}
                    <button onClick={() => setSelectedForm("")} className="hover:text-orange-900"><X className="w-3 h-3" /></button>
                  </span>
                )}
              </div>
            </div>

            {/* States */}
            {loading && (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                {Array.from({length: 8}).map((_,i) => <CardSkeleton key={i} />)}
              </div>
            )}

            {!loading && error && (
              <div className="text-center py-20">
                <Package className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                <p className="font-semibold text-gray-600 mb-2">Failed to load</p>
                <button onClick={() => window.location.reload()}
                  className="inline-flex items-center gap-2 px-5 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-semibold text-sm rounded-xl">
                  <RefreshCw className="w-4 h-4" /> Retry
                </button>
              </div>
            )}

            {!loading && !error && items.length === 0 && (
              <div className="text-center py-20">
                <Search className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                <p className="font-semibold text-gray-700 mb-1">No {tab === "medicines" ? "medicines" : "products"} found</p>
                <p className="text-sm text-gray-400 mb-4">Try adjusting your search or filters</p>
                <button onClick={() => { setSearch(""); setSelectedCategory(""); setSelectedForm(""); }}
                  className="text-sm font-semibold text-orange-500 hover:text-orange-600">
                  Clear all filters
                </button>
              </div>
            )}

            {!loading && !error && items.length > 0 && (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                {tab === "medicines"
                  ? (items as Medicine[]).map(m => (
                      <MedicineCard
                        key={m.id}
                        m={m}
                        wishlisted={wishlist.has(`med-${m.id}`)}
                        onWishlist={() => toggleWishlist(`med-${m.id}`)}
                        onAddToCart={() => {
                          addToCart({
                            id: `med-${m.id}`,
                            type: "medicine",
                            name: m.name,
                            price: parseFloat(m.cost),
                            image: getImageUrl(m.image),
                            strength: m.strength,
                            form: m.form,
                            category: m.category?.name,
                          });
                          toast.success(`${m.name} added to cart`);
                        }}
                      />
                    ))
                  : (items as MedicalProduct[]).map(p => (
                      <ProductCard
                        key={p.id}
                        p={p}
                        wishlisted={wishlist.has(`prod-${p.id}`)}
                        onWishlist={() => toggleWishlist(`prod-${p.id}`)}
                        onAddToCart={() => {
                          addToCart({
                            id: `prod-${p.id}`,
                            type: "product",
                            name: p.name,
                            price: p.price ? parseFloat(p.price) : 0,
                            image: getImageUrl(p.image_url || p.photo),
                            category: p.category?.name,
                          });
                          toast.success(`${p.name} added to cart`);
                        }}
                      />
                    ))
                }
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
