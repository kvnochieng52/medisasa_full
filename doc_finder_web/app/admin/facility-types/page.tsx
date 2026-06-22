"use client";

import { Building2 } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Facility Types",
  subtitle: "Hospitals, clinics, labs, imaging centers, etc.",
  singular: "Facility Type",
  icon: Building2,
  gradient: "from-green-500 to-emerald-600",
  endpoint: "/admin/reference/facility-types",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. Diagnostic and Imaging Centers" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "sort_order", label: "Sort order", type: "number", default: 0 },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminFacilityTypesPage() {
  return <ReferenceDataAdmin config={config} />;
}
