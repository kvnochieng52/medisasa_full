"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    const raw = localStorage.getItem("user_data");
    if (raw) {
      try {
        const user = JSON.parse(raw);
        const isAdmin = user.account_type === 3;
        const isSP = user.account_type === 2 || user.account_type === "serviceProvider";
        const isApprovedSP = isSP && user.sp_approved;
        if (!isAdmin && !isApprovedSP) {
          router.replace("/dashboard");
          return;
        }
      } catch {
        router.replace("/dashboard");
        return;
      }
    } else {
      router.replace("/dashboard");
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) return null;
  return <>{children}</>;
}
