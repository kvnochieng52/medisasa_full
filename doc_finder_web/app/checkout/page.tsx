"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  ArrowLeft, Pill, Package, Truck, Zap, Store,
  User, MapPin, FileText, ChevronRight, ShieldCheck,
} from "lucide-react";
import {
  useCart, DeliveryOption,
  FREE_DELIVERY_THRESHOLD, STANDARD_DELIVERY_FEE, EXPRESS_DELIVERY_FEE,
} from "@/lib/context/CartContext";
import toast from "react-hot-toast";

const DELIVERY_OPTIONS: { key: DeliveryOption; label: string; detail: string; icon: React.ElementType }[] = [
  { key: "standard", label: "Standard Delivery", detail: `KSh ${STANDARD_DELIVERY_FEE} · 1–3 business days`, icon: Truck },
  { key: "express",  label: "Express Delivery",  detail: `KSh ${EXPRESS_DELIVERY_FEE} · 2–4 hours`, icon: Zap },
  { key: "pickup",   label: "Pickup",             detail: "Free · Same day", icon: Store },
];

export default function CheckoutPage() {
  const router = useRouter();
  const {
    items, cartCount, cartTotal,
    deliveryOption, deliveryFee, grandTotal,
    setDeliveryOption, setOrderDetails,
  } = useCart();

  const [form, setForm] = useState({
    full_name: "", phone: "", address: "", city: "", notes: "",
  });

  useEffect(() => {
    if (items.length === 0) router.replace("/pharmacy");
  }, [items, router]);

  useEffect(() => {
    try {
      const raw = localStorage.getItem("user_data");
      if (raw) {
        const u = JSON.parse(raw);
        setForm(f => ({
          ...f,
          full_name: u.name ?? f.full_name,
          phone: u.telephone ?? u.phone ?? f.phone,
        }));
      }
    } catch { /* ignore */ }
  }, []);

  const set = (k: keyof typeof form, v: string) => setForm(f => ({ ...f, [k]: v }));

  const handleContinue = () => {
    if (!form.full_name.trim()) { toast.error("Full name is required"); return; }
    if (!form.phone.trim())     { toast.error("Phone number is required"); return; }
    if (deliveryOption !== "pickup" && !form.address.trim()) {
      toast.error("Delivery address is required"); return;
    }
    setOrderDetails(form);
    router.push("/checkout/payment");
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-orange-500 pt-20 pb-6 px-4">
        <div className="max-w-5xl mx-auto">
          <div className="flex items-center gap-2 text-orange-200 text-sm mb-2">
            <Link href="/cart" className="hover:text-white transition-colors flex items-center gap-1">
              <ArrowLeft className="w-4 h-4" /> Cart
            </Link>
            <ChevronRight className="w-3.5 h-3.5" />
            <span className="text-white font-semibold">Delivery</span>
            <ChevronRight className="w-3.5 h-3.5" />
            <span className="text-orange-300">Payment</span>
          </div>
          <h1 className="text-xl font-bold text-white">Delivery Details</h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-6 pb-16">
        <div className="flex flex-col lg:flex-row gap-6">

          {/* ── Left: Form ── */}
          <div className="flex-1 space-y-5">

            {/* Contact */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-900 text-sm mb-4 flex items-center gap-2">
                <User className="w-4 h-4 text-orange-500" /> Contact Details
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                    Full Name <span className="text-red-500">*</span>
                  </label>
                  <input type="text" value={form.full_name} onChange={e => set("full_name", e.target.value)}
                    placeholder="e.g. John Mwangi"
                    className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-orange-200 focus:border-orange-400" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                    Phone Number <span className="text-red-500">*</span>
                  </label>
                  <input type="tel" value={form.phone} onChange={e => set("phone", e.target.value)}
                    placeholder="+254 7XX XXX XXX"
                    className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-orange-200 focus:border-orange-400" />
                </div>
              </div>
            </div>

            {/* Delivery options */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-900 text-sm mb-4 flex items-center gap-2">
                <Truck className="w-4 h-4 text-orange-500" /> Delivery Method
              </h3>
              <div className="space-y-2">
                {DELIVERY_OPTIONS.map(opt => {
                  const Icon = opt.icon;
                  const sel  = deliveryOption === opt.key;
                  const fee  = opt.key === "pickup"  ? 0
                             : opt.key === "express" ? EXPRESS_DELIVERY_FEE
                             : cartTotal >= FREE_DELIVERY_THRESHOLD ? 0
                             : STANDARD_DELIVERY_FEE;
                  return (
                    <label key={opt.key}
                      className={`flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition-all ${
                        sel ? "border-orange-400 bg-orange-50" : "border-gray-200 hover:border-orange-200"
                      }`}>
                      <input type="radio" name="delivery" value={opt.key}
                        checked={sel} onChange={() => setDeliveryOption(opt.key)}
                        className="accent-orange-500" />
                      <div className={`p-2 rounded-lg ${sel ? "bg-orange-100" : "bg-gray-100"}`}>
                        <Icon className={`w-4 h-4 ${sel ? "text-orange-500" : "text-gray-500"}`} />
                      </div>
                      <div className="flex-1">
                        <p className={`text-sm font-semibold ${sel ? "text-orange-700" : "text-gray-800"}`}>{opt.label}</p>
                        <p className="text-xs text-gray-500">{opt.detail}</p>
                      </div>
                      <span className={`text-sm font-bold flex-shrink-0 ${fee === 0 ? "text-green-600" : "text-gray-700"}`}>
                        {fee === 0 ? "Free" : `KSh ${fee.toLocaleString()}`}
                      </span>
                    </label>
                  );
                })}
              </div>
            </div>

            {/* Address (hidden for pickup) */}
            {deliveryOption !== "pickup" && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <h3 className="font-bold text-gray-900 text-sm mb-4 flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-orange-500" /> Delivery Address
                </h3>
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                      Street / Estate <span className="text-red-500">*</span>
                    </label>
                    <input type="text" value={form.address} onChange={e => set("address", e.target.value)}
                      placeholder="e.g. Westlands, Tom Mboya Street"
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-orange-200 focus:border-orange-400" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">City / Town</label>
                    <input type="text" value={form.city} onChange={e => set("city", e.target.value)}
                      placeholder="e.g. Nairobi"
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-orange-200 focus:border-orange-400" />
                  </div>
                </div>
              </div>
            )}

            {/* Notes */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-900 text-sm mb-3 flex items-center gap-2">
                <FileText className="w-4 h-4 text-orange-500" /> Order Notes{" "}
                <span className="text-gray-400 font-normal text-xs">(optional)</span>
              </h3>
              <textarea rows={3} value={form.notes} onChange={e => set("notes", e.target.value)}
                placeholder="Special instructions, gate code, landmark, prescription details…"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-orange-200 focus:border-orange-400 resize-none" />
            </div>
          </div>

          {/* ── Right: Summary ── */}
          <div className="w-full lg:w-80 flex-shrink-0">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sticky top-24 space-y-4">
              <h3 className="font-bold text-gray-900">Order Summary</h3>

              <div className="space-y-3 max-h-48 overflow-y-auto pr-1">
                {items.map(item => {
                  const TypeIcon = item.type === "medicine" ? Pill : Package;
                  return (
                    <div key={item.id} className="flex gap-3 items-center">
                      <div className="w-10 h-10 rounded-lg bg-orange-50 flex-shrink-0 overflow-hidden flex items-center justify-center">
                        {item.image ? <img src={item.image} alt={item.name} className="w-full h-full object-cover" />
                          : <TypeIcon className="w-5 h-5 text-orange-300" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-gray-800 line-clamp-1">{item.name}</p>
                        <p className="text-xs text-gray-400">Qty: {item.quantity}</p>
                      </div>
                      <p className="text-xs font-bold text-gray-900 flex-shrink-0">
                        KSh {(item.price * item.quantity).toLocaleString()}
                      </p>
                    </div>
                  );
                })}
              </div>

              <div className="border-t border-gray-100 pt-3 space-y-2 text-sm">
                <div className="flex justify-between text-gray-600">
                  <span>Subtotal ({cartCount} item{cartCount !== 1 ? "s" : ""})</span>
                  <span className="font-semibold">KSh {cartTotal.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Delivery</span>
                  {deliveryFee === 0
                    ? <span className="font-semibold text-green-600">Free</span>
                    : <span className="font-semibold">KSh {deliveryFee.toLocaleString()}</span>}
                </div>
              </div>

              <div className="flex justify-between text-base font-bold text-gray-900 border-t border-gray-100 pt-3">
                <span>Total</span>
                <span className="text-orange-500">KSh {grandTotal.toLocaleString()}</span>
              </div>

              <button onClick={handleContinue}
                className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 active:scale-[0.98] text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm">
                Continue to Payment <ChevronRight className="w-4 h-4" />
              </button>

              <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
                <ShieldCheck className="w-4 h-4 text-green-500 flex-shrink-0" />
                <p className="text-xs text-gray-500">Secured checkout — your details are protected.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
