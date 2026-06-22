"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  ArrowLeft, Pill, ShoppingCart, Minus, Plus,
  ShieldCheck, Tag, Package, CheckCircle2, AlertCircle, Loader2,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { useCart } from "@/lib/context/CartContext";
import toast from "react-hot-toast";

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
  manufacturer?: string;
  dosage_instructions?: string;
}

export default function MedicineDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { addToCart } = useCart();

  const [medicine, setMedicine] = useState<Medicine | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [qty, setQty] = useState(1);

  useEffect(() => {
    api.get(`/medicines/${id}`)
      .then(res => {
        const d = res.data;
        setMedicine(d?.data ?? d?.medicine ?? d ?? null);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [id]);

  const handleAddToCart = () => {
    if (!medicine) return;
    const price = parseFloat(medicine.cost) || 0;
    for (let i = 0; i < qty; i++) {
      addToCart({
        id: `med-${medicine.id}`,
        type: "medicine",
        name: medicine.name,
        price,
        image: getImageUrl(medicine.image) ?? "",
        strength: medicine.strength,
        form: medicine.form,
        category: medicine.category?.name,
      });
    }
    toast.success(`${medicine.name} × ${qty} added to cart`);
    router.push("/cart");
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center min-h-screen">
          <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
        </div>
      </main>
    );
  }

  if (error || !medicine) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex flex-col items-center justify-center min-h-screen gap-4">
          <AlertCircle className="w-12 h-12 text-gray-300" />
          <p className="text-gray-500">Medicine not found.</p>
          <Link href="/pharmacy" className="text-orange-500 font-semibold hover:underline">
            Back to Pharmacy
          </Link>
        </div>
      </main>
    );
  }

  const img = getImageUrl(medicine.image);
  const price = parseFloat(medicine.cost) || 0;
  const inStock = (medicine.quantity_available ?? 1) > 0;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-orange-500 pt-20 pb-6 px-4">
        <div className="max-w-5xl mx-auto">
          <Link href="/pharmacy" className="inline-flex items-center gap-2 text-orange-200 hover:text-white text-sm mb-3 transition-colors">
            <ArrowLeft className="w-4 h-4" /> Back to Pharmacy
          </Link>
          <p className="text-orange-200 text-xs uppercase tracking-wide font-medium">
            {medicine.category?.name ?? "Medicine"}
          </p>
          <h1 className="text-xl font-bold text-white mt-0.5">{medicine.name}</h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-8 pb-16">
        <div className="flex flex-col lg:flex-row gap-8">

          {/* Image */}
          <div className="w-full lg:w-80 flex-shrink-0">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 aspect-square flex items-center justify-center overflow-hidden p-4">
              {img
                ? <img src={img} alt={medicine.name} className="w-full h-full object-contain" />
                : <Pill className="w-24 h-24 text-orange-200" />}
            </div>

            {/* Tags */}
            <div className="flex flex-wrap gap-2 mt-4">
              {medicine.requires_prescription && (
                <span className="flex items-center gap-1 text-xs font-bold bg-amber-100 text-amber-700 px-3 py-1 rounded-full">
                  <ShieldCheck className="w-3.5 h-3.5" /> Prescription Required
                </span>
              )}
              {medicine.form && (
                <span className="text-xs bg-blue-50 text-blue-600 font-medium px-3 py-1 rounded-full">
                  {medicine.form}
                </span>
              )}
              {medicine.strength && (
                <span className="text-xs bg-purple-50 text-purple-600 font-medium px-3 py-1 rounded-full">
                  {medicine.strength}
                </span>
              )}
            </div>
          </div>

          {/* Details */}
          <div className="flex-1 space-y-5">

            {/* Price + stock */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-center justify-between mb-4">
                <p className="text-3xl font-bold text-gray-900">
                  KSh {price.toLocaleString()}
                </p>
                {inStock
                  ? <span className="flex items-center gap-1.5 text-xs font-bold text-green-600 bg-green-50 px-3 py-1.5 rounded-full">
                      <CheckCircle2 className="w-3.5 h-3.5" /> In Stock
                    </span>
                  : <span className="text-xs font-bold text-red-500 bg-red-50 px-3 py-1.5 rounded-full">
                      Out of Stock
                    </span>}
              </div>

              {inStock && (
                <>
                  {/* Quantity */}
                  <div className="flex items-center gap-4 mb-4">
                    <p className="text-sm text-gray-600 font-medium">Quantity:</p>
                    <div className="flex items-center gap-3 bg-gray-100 rounded-xl p-1">
                      <button onClick={() => setQty(q => Math.max(1, q - 1))}
                        className="w-8 h-8 rounded-lg bg-white shadow-sm flex items-center justify-center text-gray-600 hover:text-orange-500 transition-colors">
                        <Minus className="w-3.5 h-3.5" />
                      </button>
                      <span className="text-sm font-bold text-gray-900 w-6 text-center">{qty}</span>
                      <button onClick={() => setQty(q => q + 1)}
                        className="w-8 h-8 rounded-lg bg-white shadow-sm flex items-center justify-center text-gray-600 hover:text-orange-500 transition-colors">
                        <Plus className="w-3.5 h-3.5" />
                      </button>
                    </div>
                    <p className="text-sm font-bold text-orange-500">
                      = KSh {(price * qty).toLocaleString()}
                    </p>
                  </div>

                  <button onClick={handleAddToCart}
                    className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 active:scale-[0.98] text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm">
                    <ShoppingCart className="w-4 h-4" />
                    Add to Cart
                  </button>
                </>
              )}
            </div>

            {/* Description */}
            {medicine.description && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <h3 className="font-bold text-gray-900 text-sm mb-3 flex items-center gap-2">
                  <Package className="w-4 h-4 text-orange-500" /> Description
                </h3>
                <p className="text-sm text-gray-600 leading-relaxed">{medicine.description}</p>
              </div>
            )}

            {/* Conditions / Dosage */}
            {(medicine.conditions?.length || medicine.dosage_instructions) && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 space-y-3">
                {medicine.conditions && medicine.conditions.length > 0 && (
                  <div>
                    <h3 className="font-bold text-gray-900 text-sm mb-2 flex items-center gap-2">
                      <Tag className="w-4 h-4 text-orange-500" /> Treats
                    </h3>
                    <div className="flex flex-wrap gap-2">
                      {medicine.conditions.map((c, i) => (
                        <span key={i} className="text-xs bg-orange-50 text-orange-700 font-medium px-2.5 py-1 rounded-full">
                          {c}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
                {medicine.dosage_instructions && (
                  <div>
                    <h3 className="font-bold text-gray-900 text-sm mb-2">Dosage Instructions</h3>
                    <p className="text-sm text-gray-600 leading-relaxed">{medicine.dosage_instructions}</p>
                  </div>
                )}
              </div>
            )}

            {/* Manufacturer */}
            {medicine.manufacturer && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <p className="text-xs text-gray-500 font-medium">Manufacturer</p>
                <p className="text-sm font-semibold text-gray-800 mt-0.5">{medicine.manufacturer}</p>
              </div>
            )}

            {/* Prescription notice */}
            {medicine.requires_prescription && (
              <div className="flex items-start gap-3 p-4 bg-amber-50 border border-amber-200 rounded-2xl">
                <ShieldCheck className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-bold text-amber-800">Prescription Required</p>
                  <p className="text-xs text-amber-700 mt-0.5">
                    Please have your prescription ready. You may be asked to provide it upon delivery.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
