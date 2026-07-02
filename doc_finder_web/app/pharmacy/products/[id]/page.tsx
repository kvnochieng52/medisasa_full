"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  ArrowLeft, Package, ShoppingCart, Minus, Plus,
  CheckCircle2, AlertCircle, Loader2, Calendar, Tag,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { useCart } from "@/lib/context/CartContext";
import toast from "react-hot-toast";
import SoldByFacility, { SoldByFacilityData } from "@/components/SoldByFacility";

interface Category { id: number; name: string }

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
  manufacturer?: string;
  usage_instructions?: string;
  facility?: SoldByFacilityData | null;
}

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { addToCart } = useCart();

  const [product, setProduct] = useState<MedicalProduct | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [qty, setQty] = useState(1);

  useEffect(() => {
    api.get(`/public-medical-products/${id}`)
      .then(res => {
        const d = res.data;
        setProduct(d?.data ?? d?.product ?? d ?? null);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [id]);

  const handleAddToCart = () => {
    if (!product) return;
    const price = product.price ? parseFloat(product.price) : 0;
    for (let i = 0; i < qty; i++) {
      addToCart({
        id: `prod-${product.id}`,
        type: "product",
        name: product.name,
        price,
        image: getImageUrl(product.image_url ?? product.photo) ?? "",
        category: product.category?.name,
      });
    }
    toast.success(`${product.name} × ${qty} added to cart`);
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

  if (error || !product) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex flex-col items-center justify-center min-h-screen gap-4">
          <AlertCircle className="w-12 h-12 text-gray-300" />
          <p className="text-gray-500">Product not found.</p>
          <Link href="/pharmacy" className="text-orange-500 font-semibold hover:underline">
            Back to Pharmacy
          </Link>
        </div>
      </main>
    );
  }

  const img = getImageUrl(product.image_url ?? product.photo);
  const price = product.price ? parseFloat(product.price) : null;
  const inStock = (product.stock_quantity ?? 1) > 0;
  const expired = product.expiry_date ? new Date(product.expiry_date).getTime() < Date.now() : false;
  const daysToExpiry = product.expiry_date
    ? Math.ceil((new Date(product.expiry_date).getTime() - Date.now()) / 86400000)
    : null;
  const expiringSoon = !expired && daysToExpiry !== null && daysToExpiry <= 30;

  const canBuy = inStock && !expired;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-orange-500 pt-20 pb-6 px-4">
        <div className="max-w-5xl mx-auto">
          <Link href="/pharmacy?tab=products" className="inline-flex items-center gap-2 text-orange-200 hover:text-white text-sm mb-3 transition-colors">
            <ArrowLeft className="w-4 h-4" /> Back to Pharmacy
          </Link>
          <p className="text-orange-200 text-xs uppercase tracking-wide font-medium">
            {product.category?.name ?? "Medical Product"}
          </p>
          <h1 className="text-xl font-bold text-white mt-0.5">{product.name}</h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-8 pb-16">
        <div className="flex flex-col lg:flex-row gap-8">

          {/* Image */}
          <div className="w-full lg:w-80 flex-shrink-0">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 aspect-square flex items-center justify-center overflow-hidden p-4 relative">
              {img
                ? <img src={img} alt={product.name} className="w-full h-full object-contain" />
                : <Package className="w-24 h-24 text-orange-200" />}
              {expired && (
                <span className="absolute top-3 left-3 bg-red-500 text-white text-xs font-bold px-2.5 py-1 rounded-lg">Expired</span>
              )}
              {expiringSoon && (
                <span className="absolute top-3 left-3 bg-amber-500 text-white text-xs font-bold px-2.5 py-1 rounded-lg">Expiring Soon</span>
              )}
            </div>

            {product.product_code && (
              <p className="text-xs text-gray-400 text-center mt-3">
                Product Code: <span className="font-mono font-semibold text-gray-600">{product.product_code}</span>
              </p>
            )}
          </div>

          {/* Details */}
          <div className="flex-1 space-y-5">

            {/* Price + stock */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-center justify-between mb-4">
                {price !== null
                  ? <p className="text-3xl font-bold text-gray-900">KSh {price.toLocaleString()}</p>
                  : <p className="text-base text-gray-400 italic">Price on request</p>}

                {canBuy
                  ? <span className="flex items-center gap-1.5 text-xs font-bold text-green-600 bg-green-50 px-3 py-1.5 rounded-full">
                      <CheckCircle2 className="w-3.5 h-3.5" /> In Stock
                    </span>
                  : <span className="text-xs font-bold text-red-500 bg-red-50 px-3 py-1.5 rounded-full">
                      {expired ? "Expired" : "Out of Stock"}
                    </span>}
              </div>

              {/* Expiry info */}
              {product.expiry_date && (
                <div className={`flex items-center gap-2 p-3 rounded-xl mb-4 text-sm ${
                  expired ? "bg-red-50 text-red-600" : expiringSoon ? "bg-amber-50 text-amber-700" : "bg-green-50 text-green-700"
                }`}>
                  <Calendar className="w-4 h-4 flex-shrink-0" />
                  <span>
                    {expired
                      ? `Expired on ${new Date(product.expiry_date).toLocaleDateString()}`
                      : expiringSoon
                        ? `Expires in ${daysToExpiry} day${daysToExpiry !== 1 ? "s" : ""}`
                        : `Expires ${new Date(product.expiry_date).toLocaleDateString()}`}
                  </span>
                </div>
              )}

              {canBuy && price !== null && (
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
            {product.description && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <h3 className="font-bold text-gray-900 text-sm mb-3 flex items-center gap-2">
                  <Package className="w-4 h-4 text-orange-500" /> Description
                </h3>
                <p className="text-sm text-gray-600 leading-relaxed">{product.description}</p>
              </div>
            )}

            {/* Usage instructions */}
            {product.usage_instructions && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <h3 className="font-bold text-gray-900 text-sm mb-2 flex items-center gap-2">
                  <Tag className="w-4 h-4 text-orange-500" /> Usage Instructions
                </h3>
                <p className="text-sm text-gray-600 leading-relaxed">{product.usage_instructions}</p>
              </div>
            )}

            {/* Sold by (facility) */}
            <SoldByFacility facility={product.facility} accent="orange" />

            {/* Manufacturer */}
            {product.manufacturer && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <p className="text-xs text-gray-500 font-medium">Manufacturer</p>
                <p className="text-sm font-semibold text-gray-800 mt-0.5">{product.manufacturer}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
