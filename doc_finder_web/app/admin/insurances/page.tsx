"use client";

import { ShieldCheck } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Insurances",
  subtitle: "Insurance providers accepted by facilities",
  singular: "Insurance",
  icon: ShieldCheck,
  gradient: "from-amber-500 to-orange-600",
  endpoint: "/admin/reference/insurances",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. NHIF, AAR, Jubilee" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "sort_order", label: "Sort order", type: "number", default: 0 },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminInsurancesPage() {
  return <ReferenceDataAdmin config={config} />;
}
