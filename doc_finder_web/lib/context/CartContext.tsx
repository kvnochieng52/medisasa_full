"use client";

import { createContext, useContext, useState, useEffect, useCallback } from "react";

export const FREE_DELIVERY_THRESHOLD = 2000;   // KSh 2,000+  → free
export const STANDARD_DELIVERY_FEE  = 200;     // KSh 200 flat
export const EXPRESS_DELIVERY_FEE   = 500;     // KSh 500

export type DeliveryOption = "standard" | "express" | "pickup";

export interface OrderDetails {
  full_name: string;
  phone: string;
  address: string;
  city: string;
  notes: string;
}

export interface CartItem {
  id: string;         // "med-{id}" or "prod-{id}"
  type: "medicine" | "product";
  name: string;
  price: number;
  image: string;
  strength?: string;
  form?: string;
  category?: string;
  quantity: number;
}

interface CartContextValue {
  items: CartItem[];
  cartCount: number;
  cartTotal: number;
  deliveryOption: DeliveryOption;
  deliveryFee: number;
  grandTotal: number;
  orderDetails: OrderDetails | null;
  setDeliveryOption: (opt: DeliveryOption) => void;
  setOrderDetails: (d: OrderDetails) => void;
  addToCart: (item: Omit<CartItem, "quantity">) => void;
  removeFromCart: (id: string) => void;
  updateQty: (id: string, qty: number) => void;
  clearCart: () => void;
}

const CartContext = createContext<CartContextValue | null>(null);

const STORAGE_KEY = "xyvra_cart";

function calcDeliveryFee(total: number, option: DeliveryOption): number {
  if (option === "pickup") return 0;
  if (option === "express") return EXPRESS_DELIVERY_FEE;
  // Standard: free above threshold
  return total >= FREE_DELIVERY_THRESHOLD ? 0 : STANDARD_DELIVERY_FEE;
}

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [deliveryOption, setDeliveryOption] = useState<DeliveryOption>("standard");
  const [orderDetails, setOrderDetails] = useState<OrderDetails | null>(null);

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) setItems(JSON.parse(stored));
    } catch { /* ignore */ }
  }, []);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  }, [items]);

  const addToCart = useCallback((item: Omit<CartItem, "quantity">) => {
    setItems(prev => {
      const existing = prev.find(i => i.id === item.id);
      if (existing) {
        return prev.map(i => i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i);
      }
      return [...prev, { ...item, quantity: 1 }];
    });
  }, []);

  const removeFromCart = useCallback((id: string) => {
    setItems(prev => prev.filter(i => i.id !== id));
  }, []);

  const updateQty = useCallback((id: string, qty: number) => {
    if (qty <= 0) {
      setItems(prev => prev.filter(i => i.id !== id));
    } else {
      setItems(prev => prev.map(i => i.id === id ? { ...i, quantity: qty } : i));
    }
  }, []);

  const clearCart = useCallback(() => setItems([]), []);

  const cartCount  = items.reduce((sum, i) => sum + i.quantity, 0);
  const cartTotal  = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const deliveryFee = calcDeliveryFee(cartTotal, deliveryOption);
  const grandTotal  = cartTotal + deliveryFee;

  return (
    <CartContext.Provider value={{
      items, cartCount, cartTotal,
      deliveryOption, deliveryFee, grandTotal,
      orderDetails,
      setDeliveryOption,
      setOrderDetails,
      addToCart, removeFromCart, updateQty, clearCart,
    }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within CartProvider");
  return ctx;
}
