"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ShoppingCart, Package, ChevronRight } from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { useCart } from "@/lib/context/CartContext";
import toast from "react-hot-toast";

interface Medicine {
  id: number;
  name: string;
  description?: string;
  cost?: number | string;
  price?: number | string;
  image_url?: string;
  image?: string;
  category?: { name: string } | string;
  subcategory?: { name: string } | string;
  unit?: string;
  slug?: string;
}

function MedicineCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-card animate-pulse flex-shrink-0 w-44">
      <div className="h-28 bg-gray-200" />
      <div className="p-3 space-y-2">
        <div className="h-3 bg-gray-200 rounded w-3/4" />
        <div className="h-3 bg-gray-100 rounded w-1/2" />
        <div className="h-7 bg-gray-100 rounded-lg mt-2" />
      </div>
    </div>
  );
}

export default function LatestMedicines() {
  const { addToCart } = useCart();
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get("/medicines?page=1&per_page=8&sort_by=created_at&sort_order=desc")
      .then((res) => {
        const data = res.data;
        const list: Medicine[] = Array.isArray(data?.data)
          ? data.data
          : data?.data?.medicines ?? data?.medicines ?? [];
        setMedicines(list.slice(0, 8));
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleAddToCart = (e: React.MouseEvent, medicine: Medicine) => {
    e.preventDefault();
    e.stopPropagation();
    const raw = medicine.cost ?? medicine.price;
    const price = raw ? Number(raw) : 0;
    addToCart({
      id: `med-${medicine.id}`,
      type: "medicine",
      name: medicine.name,
      price,
      image: getImageUrl(medicine.image_url ?? medicine.image) ?? "",
      category: typeof medicine.category === "string"
        ? medicine.category
        : medicine.category?.name,
    });
    toast.success(`${medicine.name} added to cart`);
  };

  const formatPrice = (medicine: Medicine) => {
    const raw = medicine.cost ?? medicine.price;
    if (!raw) return null;
    return `KES ${Number(raw).toLocaleString()}`;
  };

  const getCategoryName = (medicine: Medicine): string | null => {
    if (!medicine.category) return null;
    if (typeof medicine.category === "string") return medicine.category;
    return medicine.category.name ?? null;
  };

  return (
    <section className="py-12 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 rounded-lg bg-purple-50">
                <Package className="w-4 h-4 text-purple-500" />
              </div>
              <span className="text-sm font-medium text-purple-500 uppercase tracking-wide">
                Online Pharmacy
              </span>
            </div>
            <h2 className="section-title text-2xl">Recent Medicines</h2>
          </div>
          <Link
            href="/pharmacy"
            className="hidden sm:flex items-center gap-1 text-sm font-medium text-brand-500 hover:text-brand-600 transition-colors"
          >
            View All
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Horizontal scroll */}
        <div className="flex gap-4 overflow-x-auto scrollbar-hide pb-2">
          {loading
            ? Array.from({ length: 6 }).map((_, i) => <MedicineCardSkeleton key={i} />)
            : medicines.length === 0
            ? (
              <div className="w-full text-center py-12 text-gray-400">
                <Package className="w-10 h-10 mx-auto mb-2 text-gray-200" />
                <p>No medicines available right now.</p>
              </div>
            )
            : medicines.map((med) => {
                const imageUrl = getImageUrl(med.image_url ?? med.image);
                const price = formatPrice(med);
                return (
                  <Link
                    key={med.id}
                    href={`/pharmacy/medicines/${med.id}`}
                    className="bg-white rounded-2xl overflow-hidden shadow-card hover:shadow-card-hover transition-all duration-300 hover:-translate-y-0.5 flex-shrink-0 w-44 border border-gray-50 group block"
                  >
                    {/* Image */}
                    <div className="h-28 bg-brand-50 flex items-center justify-center overflow-hidden">
                      {imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={imageUrl}
                          alt={med.name}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      ) : (
                        <Package className="w-10 h-10 text-brand-300" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="p-3">
                      <p className="text-sm font-semibold text-gray-800 truncate group-hover:text-brand-500 transition-colors">
                        {med.name}
                      </p>
                      {getCategoryName(med) && (
                        <p className="text-xs text-gray-400 truncate mt-0.5">
                          {getCategoryName(med)}
                        </p>
                      )}
                      {price && (
                        <p className="text-sm font-bold text-brand-500 mt-1">
                          {price}
                        </p>
                      )}
                      <button
                        onClick={(e) => handleAddToCart(e, med)}
                        className="w-full mt-2 flex items-center justify-center gap-1.5 py-1.5 rounded-lg bg-brand-500 hover:bg-brand-600 text-white text-xs font-medium transition-colors"
                      >
                        <ShoppingCart className="w-3.5 h-3.5" />
                        Add to Cart
                      </button>
                    </div>
                  </Link>
                );
              })}
        </div>

        {/* View all button */}
        <div className="mt-6 text-center">
          <Link
            href="/pharmacy"
            className="btn-outline text-sm inline-flex items-center gap-1"
          >
            View All Products & Medicines
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}
