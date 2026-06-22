"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  ArrowLeft, Pill, Package, CreditCard, Smartphone,
  ChevronRight, ShieldCheck, CheckCircle2, Loader2,
  AlertCircle, RefreshCw, X, ExternalLink, Receipt,
} from "lucide-react";
import { useCart } from "@/lib/context/CartContext";
import api from "@/lib/api";
import toast from "react-hot-toast";

type PaymentState = "idle" | "initiating" | "polling" | "timeout" | "failed" | "success";
type PaymentMethod = "card" | "mpesa";

const POLL_INTERVAL_MS = 5000;
const MAX_POLLS = 36; // 3 minutes

export default function PaymentPage() {
  const router = useRouter();
  const {
    items, cartCount, cartTotal,
    deliveryOption, deliveryFee, grandTotal,
    orderDetails, clearCart,
  } = useCart();

  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("card");
  const [paymentState, setPaymentState] = useState<PaymentState>("idle");
  const [transToken, setTransToken] = useState("");
  const [orderRef, setOrderRef] = useState("");
  const [paymentUrl, setPaymentUrl] = useState("");
  const [pollCount, setPollCount] = useState(0);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!orderDetails) router.replace("/checkout");
  }, [orderDetails, router]);

  useEffect(() => {
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, []);

  const stopPolling = () => {
    if (pollRef.current) { clearInterval(pollRef.current); pollRef.current = null; }
  };

  const startPolling = (token: string) => {
    let count = 0;
    pollRef.current = setInterval(async () => {
      count++;
      setPollCount(count);

      if (count >= MAX_POLLS) {
        stopPolling();
        setPaymentState("timeout");
        return;
      }

      try {
        const res = await api.get<{ data: { status: string; order_ref: string } }>(
          `/pharmacy-orders/verify/${token}`
        );
        const { status, order_ref } = res.data.data;
        if (status === "paid") {
          stopPolling();
          setOrderRef(order_ref);
          clearCart();
          setPaymentState("success");
        } else if (status === "failed" || status === "cancelled") {
          stopPolling();
          setPaymentState("failed");
        }
      } catch {
        // silently continue on network blip
      }
    }, POLL_INTERVAL_MS);
  };

  const handlePay = async () => {
    if (!orderDetails) return;
    setPaymentState("initiating");

    try {
      const payload = {
        customer_name: orderDetails.full_name,
        customer_phone: orderDetails.phone,
        delivery_address: orderDetails.address,
        delivery_city: orderDetails.city,
        delivery_option: deliveryOption,
        notes: orderDetails.notes,
        items: items.map(i => ({
          id: i.id,
          type: i.type,
          name: i.name,
          price: i.price,
          quantity: i.quantity,
        })),
        subtotal: cartTotal,
        delivery_fee: deliveryFee,
        total: grandTotal,
        payment_method: paymentMethod,
      };

      const res = await api.post<{ success: boolean; data: { payment_url: string; trans_token: string; order_ref: string } }>(
        "/pharmacy-orders",
        payload
      );

      const { payment_url, trans_token, order_ref } = res.data.data;
      setTransToken(trans_token);
      setOrderRef(order_ref);
      setPaymentUrl(payment_url);

      if (paymentMethod === "card") {
        window.open(payment_url, "_blank", "noopener,noreferrer");
        setPaymentState("polling");
        setPollCount(0);
        startPolling(trans_token);
      } else {
        // M-Pesa: open DPO which handles M-Pesa STK push
        window.open(payment_url, "_blank", "noopener,noreferrer");
        setPaymentState("polling");
        setPollCount(0);
        startPolling(trans_token);
      }
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      toast.error(e?.response?.data?.message ?? "Failed to initiate payment");
      setPaymentState("idle");
    }
  };

  const handleCheckStatus = () => {
    if (!transToken) return;
    setPaymentState("polling");
    setPollCount(0);
    startPolling(transToken);
  };

  const handleRetry = () => {
    stopPolling();
    setPaymentState("idle");
    setTransToken("");
    setPollCount(0);
  };

  if (!orderDetails) return null;

  // ── Success screen ──
  if (paymentState === "success") {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex flex-col items-center justify-center min-h-screen px-4 pb-16">
          <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-10 max-w-md w-full text-center">
            <div className="w-20 h-20 rounded-full bg-green-50 flex items-center justify-center mx-auto mb-6">
              <CheckCircle2 className="w-10 h-10 text-green-500" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Order Placed!</h1>
            <p className="text-gray-500 text-sm mb-4">
              Your payment was successful. We&apos;ll process your order right away.
            </p>
            {orderRef && (
              <div className="flex items-center gap-2 bg-orange-50 rounded-xl px-4 py-3 mb-6">
                <Receipt className="w-4 h-4 text-orange-500 flex-shrink-0" />
                <div className="text-left">
                  <p className="text-xs text-gray-500">Order Reference</p>
                  <p className="text-sm font-bold text-orange-600">{orderRef}</p>
                </div>
              </div>
            )}
            <p className="text-xs text-gray-400 mb-8">
              A confirmation will be sent to {orderDetails.phone}.
            </p>
            <Link
              href="/pharmacy"
              className="inline-flex items-center gap-2 px-6 py-3 bg-orange-500 hover:bg-orange-600 text-white font-bold text-sm rounded-xl transition-colors"
            >
              Continue Shopping
            </Link>
          </div>
        </div>
      </main>
    );
  }

  const deliveryLabel = deliveryOption === "pickup" ? "Pickup" : deliveryOption === "express" ? "Express" : "Standard";

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
            <Link href="/checkout" className="hover:text-white transition-colors">Delivery</Link>
            <ChevronRight className="w-3.5 h-3.5" />
            <span className="text-white font-semibold">Payment</span>
          </div>
          <h1 className="text-xl font-bold text-white">Payment</h1>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 py-6 pb-16">
        <div className="flex flex-col lg:flex-row gap-6">

          {/* ── Left: Payment ── */}
          <div className="flex-1 space-y-5">

            {/* Delivery summary */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-center justify-between mb-1">
                <h3 className="font-bold text-gray-900 text-sm">Delivery Details</h3>
                <Link href="/checkout" className="text-xs text-orange-500 font-semibold hover:text-orange-600">
                  Edit
                </Link>
              </div>
              <div className="text-sm text-gray-600 space-y-0.5 mt-2">
                <p className="font-semibold text-gray-800">{orderDetails.full_name}</p>
                <p>{orderDetails.phone}</p>
                {orderDetails.address && (
                  <p>{orderDetails.address}{orderDetails.city ? `, ${orderDetails.city}` : ""}</p>
                )}
                <p className="text-xs text-orange-600 font-medium mt-1">{deliveryLabel} Delivery</p>
              </div>
            </div>

            {/* Payment method */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-900 text-sm mb-4">Payment Method</h3>

              {paymentState === "idle" && (
                <>
                  <div className="space-y-2 mb-6">
                    <label className={`flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition-all ${
                      paymentMethod === "card" ? "border-orange-400 bg-orange-50" : "border-gray-200 hover:border-orange-200"
                    }`}>
                      <input type="radio" name="payment" value="card"
                        checked={paymentMethod === "card"} onChange={() => setPaymentMethod("card")}
                        className="accent-orange-500" />
                      <div className={`p-2 rounded-lg ${paymentMethod === "card" ? "bg-orange-100" : "bg-gray-100"}`}>
                        <CreditCard className={`w-4 h-4 ${paymentMethod === "card" ? "text-orange-500" : "text-gray-500"}`} />
                      </div>
                      <div>
                        <p className={`text-sm font-semibold ${paymentMethod === "card" ? "text-orange-700" : "text-gray-800"}`}>
                          Debit / Credit Card
                        </p>
                        <p className="text-xs text-gray-500">Visa, Mastercard — secured via DPO Pay</p>
                      </div>
                    </label>

                    <label className={`flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition-all ${
                      paymentMethod === "mpesa" ? "border-orange-400 bg-orange-50" : "border-gray-200 hover:border-orange-200"
                    }`}>
                      <input type="radio" name="payment" value="mpesa"
                        checked={paymentMethod === "mpesa"} onChange={() => setPaymentMethod("mpesa")}
                        className="accent-orange-500" />
                      <div className={`p-2 rounded-lg ${paymentMethod === "mpesa" ? "bg-orange-100" : "bg-gray-100"}`}>
                        <Smartphone className={`w-4 h-4 ${paymentMethod === "mpesa" ? "text-orange-500" : "text-gray-500"}`} />
                      </div>
                      <div>
                        <p className={`text-sm font-semibold ${paymentMethod === "mpesa" ? "text-orange-700" : "text-gray-800"}`}>
                          M-Pesa
                        </p>
                        <p className="text-xs text-gray-500">Pay via M-Pesa — secured via DPO Pay</p>
                      </div>
                    </label>
                  </div>

                  <button onClick={handlePay}
                    className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 active:scale-[0.98] text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm">
                    <ExternalLink className="w-4 h-4" />
                    Pay KSh {grandTotal.toLocaleString()}
                  </button>
                </>
              )}

              {/* Initiating */}
              {paymentState === "initiating" && (
                <div className="flex flex-col items-center py-8 gap-4">
                  <Loader2 className="w-10 h-10 animate-spin text-orange-500" />
                  <p className="text-sm font-semibold text-gray-700">Opening payment page…</p>
                  <p className="text-xs text-gray-400 text-center">Please wait while we set up your secure payment.</p>
                </div>
              )}

              {/* Polling */}
              {paymentState === "polling" && (
                <div className="flex flex-col items-center py-6 gap-3">
                  <div className="w-16 h-16 rounded-full bg-orange-50 flex items-center justify-center">
                    <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
                  </div>
                  <p className="font-bold text-gray-800">Waiting for Payment</p>
                  <p className="text-sm text-gray-500 text-center">
                    Complete the payment in the tab that just opened.
                  </p>
                  <p className="text-xs text-gray-400">
                    Checking status… ({pollCount}/{MAX_POLLS})
                  </p>
                  <div className="w-full bg-gray-100 rounded-full h-1.5 mt-1">
                    <div
                      className="bg-orange-400 h-1.5 rounded-full transition-all"
                      style={{ width: `${(pollCount / MAX_POLLS) * 100}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400 text-center mt-1">
                    Do not close this tab. We&apos;ll confirm automatically.
                  </p>
                  {paymentUrl && (
                    <button onClick={() => window.open(paymentUrl, "_blank", "noopener,noreferrer")}
                      className="text-xs text-orange-500 font-semibold hover:underline flex items-center gap-1">
                      <ExternalLink className="w-3.5 h-3.5" /> Reopen payment page
                    </button>
                  )}
                </div>
              )}

              {/* Timeout */}
              {paymentState === "timeout" && (
                <div className="flex flex-col items-center py-6 gap-4">
                  <div className="w-16 h-16 rounded-full bg-amber-50 flex items-center justify-center">
                    <AlertCircle className="w-8 h-8 text-amber-500" />
                  </div>
                  <p className="font-bold text-gray-800">Taking Longer Than Expected</p>
                  <p className="text-sm text-gray-500 text-center">
                    If you completed the payment, click &quot;Check Status&quot; to confirm. Otherwise retry.
                  </p>
                  <div className="flex gap-3 w-full">
                    <button onClick={handleRetry}
                      className="flex-1 py-3 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50">
                      Try Again
                    </button>
                    <button onClick={handleCheckStatus}
                      className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-orange-500 hover:bg-orange-600 text-white text-sm font-semibold transition-colors">
                      <RefreshCw className="w-4 h-4" /> Check Status
                    </button>
                  </div>
                </div>
              )}

              {/* Failed */}
              {paymentState === "failed" && (
                <div className="flex flex-col items-center py-6 gap-4">
                  <div className="w-16 h-16 rounded-full bg-red-50 flex items-center justify-center">
                    <X className="w-8 h-8 text-red-500" />
                  </div>
                  <p className="font-bold text-gray-800">Payment Failed or Cancelled</p>
                  <p className="text-sm text-gray-500 text-center">
                    Your payment was not completed. You can try again.
                  </p>
                  <button onClick={handleRetry}
                    className="w-full py-3 rounded-xl bg-orange-500 hover:bg-orange-600 text-white text-sm font-bold transition-colors">
                    Try Again
                  </button>
                </div>
              )}
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
                        {item.image
                          ? <img src={item.image} alt={item.name} className="w-full h-full object-cover" />
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

              <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
                <ShieldCheck className="w-4 h-4 text-green-500 flex-shrink-0" />
                <p className="text-xs text-gray-500">Secured payment via DPO Pay.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
