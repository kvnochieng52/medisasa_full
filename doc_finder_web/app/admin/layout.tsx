"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";

// Admin-only routes — SPs should NOT access these. Everything else under
// /admin/* (facilities, support-groups, pharmacy) is for SPs managing their
// own practice and stays open to approved SPs.
const ADMIN_ONLY_PATHS = [
  "/admin",                       // Admin Console index (exact match below)
  "/admin/users",
  "/admin/service-providers",
  "/admin/blogs",
  "/admin/surveys",
  "/admin/mental-health",
  "/admin/specializations",
  "/admin/facility-types",
  "/admin/facility-levels",
  "/admin/insurances",
  "/admin/group-categories",
  "/admin/conditions",
  "/admin/symptoms",
];

function isAdminOnly(path: string): boolean {
  // /admin (exact) is admin-only; deeper paths match by prefix.
  if (path === "/admin") return true;
  return ADMIN_ONLY_PATHS.some(p => p !== "/admin" && (path === p || path.startsWith(`${p}/`)));
}

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    const raw = localStorage.getItem("user_data");
    if (!raw) { router.replace("/dashboard"); return; }

    try {
      const user = JSON.parse(raw);
      const isAdmin = Number(user.account_type) === 3;
      const isSP = Number(user.account_type) === 2 || user.account_type === "serviceProvider";
      const isApprovedSP = isSP && !!user.sp_approved;

      // Block unauthenticated-ish users entirely.
      if (!isAdmin && !isApprovedSP) {
        router.replace("/dashboard");
        return;
      }

      // SPs are allowed in /admin/facilities, /admin/support-groups, /admin/pharmacy
      // (their own practice management) but not in admin-only routes.
      if (!isAdmin && isAdminOnly(pathname)) {
        router.replace("/dashboard");
        return;
      }
    } catch {
      router.replace("/dashboard");
      return;
    }
    setReady(true);
  }, [router, pathname]);

  if (!ready) return null;
  return <>{children}</>;
}
