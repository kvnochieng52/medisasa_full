"use client";

import { useCart, FREE_DELIVERY_THRESHOLD, STANDARD_DELIVERY_FEE, EXPRESS_DELIVERY_FEE, DeliveryOption } from "@/lib/context/CartContext";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Minus, Plus, Trash2, ShoppingCart, Pill, Package,
  ArrowLeft, Tag, Truck, Zap, Store, ChevronRight, Info,
} from "lucide-react";

const DELIVERY_OPTIONS: { key: DeliveryOption; label: string; desc: string; icon: React.ElementType }[] = [
  { key: "standard", label: "Standard Delivery", desc: `KSh ${STANDARD_DELIVERY_FEE} · Free above KSh ${FREE_DELIVERY_THRESHOLD.toLocaleString()}`, icon: Truck },
  { key: "express",  label: "Express Delivery",  desc: `KSh ${EXPRESS_DELIVERY_FEE} · Delivered within 2–4 hours`, icon: Zap },
  { key: "pickup",   label: "Pickup",             desc: "Free · Collect at our pharmacy", icon: Store },
];

export default function CartPage() {
  const router = useRouter();
  const {
    items, cartCount, cartTotal,
    deliveryOption, deliveryFee, grandTotal,
    setDeliveryOption,
    removeFromCart, updateQty, clearCart,
  } = useCart();

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-orange-500 pt-20 pb-6 px-4">
        <div className="max-w-4xl mx-auto flex items-center gap-3">
          <ShoppingCart className="w-6 h-6 text-white" />
          <h1 className="text-xl font-bold text-white">
            Your Cart{" "}
            {cartCount > 0 && (
              <span className="text-orange-200 font-normal text-base">
                ({cartCount} item{cartCount !== 1 ? "s" : ""})
              </span>
            )}
          </h1>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6 pb-16">
        {items.length === 0 ? (
          <div className="text-center py-20">
            <ShoppingCart className="w-16 h-16 text-gray-200 mx-auto mb-4" />
            <h2 className="text-lg font-bold text-gray-700 mb-2">Your cart is empty</h2>
            <p className="text-sm text-gray-400 mb-6">
              Add medicines or healthcare products to get started.
            </p>
            <Link
              href="/pharmacy"
              className="inline-flex items-center gap-2 px-6 py-3 bg-orange-500 hover:bg-orange-600 text-white font-semibold text-sm rounded-xl transition-colors"
            >
              <Pill className="w-4 h-4" /> Browse Pharmacy
            </Link>
          </div>
        ) : (
          <div className="flex flex-col lg:flex-row gap-6">
            {/* ── Items list ── */}
            <div className="flex-1 space-y-3">
              <div className="flex items-center justify-between mb-2">
                <Link
                  href="/pharmacy"
                  className="flex items-center gap-1.5 text-sm font-semibold text-orange-500 hover:text-orange-600 transition-colors"
                >
                  <ArrowLeft className="w-4 h-4" /> Continue Shopping
                </Link>
                <button
                  onClick={clearCart}
                  className="text-xs font-semibold text-red-400 hover:text-red-600 transition-colors"
                >
                  Clear all
                </button>
              </div>

              {items.map(item => {
                const TypeIcon = item.type === "medicine" ? Pill : Package;
                return (
                  <div
                    key={item.id}
                    className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex gap-4"
                  >
                    <div className="w-20 h-20 rounded-xl bg-orange-50 flex-shrink-0 overflow-hidden flex items-center justify-center">
                      {item.image ? (
                        <img src={item.image} alt={item.name} className="w-full h-full object-cover" />
                      ) : (
                        <TypeIcon className="w-8 h-8 text-orange-300" />
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0">
                          {item.category && (
                            <p className="text-[10px] text-gray-400 uppercase tracking-wide font-medium mb-0.5">
                              {item.category}
                            </p>
                          )}
                          <h3 className="font-semibold text-gray-900 text-sm leading-snug line-clamp-2">
                            {item.name}
                          </h3>
                          {(item.strength || item.form) && (
                            <p className="text-xs text-gray-500 mt-0.5">
                              {[item.strength, item.form].filter(Boolean).join(" · ")}
                            </p>
                          )}
                        </div>
                        <button
                          onClick={() => removeFromCart(item.id)}
                          className="text-gray-300 hover:text-red-400 transition-colors flex-shrink-0 p-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="flex items-center justify-between mt-3">
                        <div className="flex items-center gap-2 bg-gray-100 rounded-xl p-1">
                          <button
                            onClick={() => updateQty(item.id, item.quantity - 1)}
                            className="w-7 h-7 rounded-lg bg-white shadow-sm flex items-center justify-center text-gray-600 hover:text-orange-500 transition-colors"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="text-sm font-bold text-gray-900 w-6 text-center">
                            {item.quantity}
                          </span>
                          <button
                            onClick={() => updateQty(item.id, item.quantity + 1)}
                            className="w-7 h-7 rounded-lg bg-white shadow-sm flex items-center justify-center text-gray-600 hover:text-orange-500 transition-colors"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                        </div>

                        <div className="text-right">
                          <p className="text-sm font-bold text-gray-900">
                            KSh {(item.price * item.quantity).toLocaleString()}
                          </p>
                          {item.quantity > 1 && (
                            <p className="text-xs text-gray-400">
                              KSh {item.price.toLocaleString()} each
                            </p>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}

              {/* ── Delivery options ── */}
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 mt-2">
                <h4 className="font-bold text-gray-900 text-sm mb-3 flex items-center gap-2">
                  <Truck className="w-4 h-4 text-orange-500" /> Delivery Options
                </h4>
                <div className="space-y-2">
                  {DELIVERY_OPTIONS.map(opt => {
                    const Icon = opt.icon;
                    const selected = deliveryOption === opt.key;
                    return (
                      <label
                        key={opt.key}
                        className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                          selected
                            ? "border-orange-400 bg-orange-50"
                            : "border-gray-200 hover:border-orange-200"
                        }`}
                      >
                        <input
                          type="radio"
                          name="delivery"
                          value={opt.key}
                          checked={selected}
                          onChange={() => setDeliveryOption(opt.key)}
                          className="accent-orange-500"
                        />
                        <div className={`p-1.5 rounded-lg ${selected ? "bg-orange-100" : "bg-gray-100"}`}>
                          <Icon className={`w-4 h-4 ${selected ? "text-orange-500" : "text-gray-500"}`} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className={`text-sm font-semibold ${selected ? "text-orange-700" : "text-gray-800"}`}>
                            {opt.label}
                          </p>
                          <p className="text-xs text-gray-500">{opt.desc}</p>
                        </div>
                        {opt.key === "standard" && cartTotal >= FREE_DELIVERY_THRESHOLD && (
                          <span className="text-xs font-bold text-green-600 bg-green-100 px-2 py-0.5 rounded-full">
                            Free!
                          </span>
                        )}
                      </label>
                    );
                  })}
                </div>

                {deliveryOption === "standard" && cartTotal < FREE_DELIVERY_THRESHOLD && (
                  <div className="flex items-start gap-2 mt-3 p-3 bg-blue-50 rounded-xl">
                    <Info className="w-3.5 h-3.5 text-blue-500 flex-shrink-0 mt-0.5" />
                    <p className="text-xs text-blue-700">
                      Add{" "}
                      <span className="font-bold">
                        KSh {(FREE_DELIVERY_THRESHOLD - cartTotal).toLocaleString()}
                      </span>{" "}
                      more to get free delivery.
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* ── Order summary ── */}
            <div className="w-full lg:w-72 flex-shrink-0">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sticky top-24">
                <h3 className="font-bold text-gray-900 mb-4">Order Summary</h3>

                <div className="space-y-2.5 text-sm mb-4">
                  <div className="flex justify-between text-gray-600">
                    <span>Subtotal ({cartCount} item{cartCount !== 1 ? "s" : ""})</span>
                    <span className="font-semibold">KSh {cartTotal.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between text-gray-600">
                    <span>Delivery</span>
                    {deliveryFee === 0 ? (
                      <span className="font-semibold text-green-600">Free</span>
                    ) : (
                      <span className="font-semibold">KSh {deliveryFee.toLocaleString()}</span>
                    )}
                  </div>
                </div>

                <div className="flex justify-between text-base font-bold text-gray-900 border-t border-gray-100 pt-3 mb-5">
                  <span>Total</span>
                  <span className="text-orange-500">KSh {grandTotal.toLocaleString()}</span>
                </div>

                <button
                  onClick={() => router.push("/checkout")}
                  className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 active:scale-[0.98] text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm"
                >
                  Proceed to Checkout <ChevronRight className="w-4 h-4" />
                </button>

                <div className="flex items-center gap-2 mt-3 p-3 bg-orange-50 rounded-xl">
                  <Tag className="w-4 h-4 text-orange-500 flex-shrink-0" />
                  <p className="text-xs text-orange-700 font-medium">
                    Have a prescription? Present it at checkout.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
