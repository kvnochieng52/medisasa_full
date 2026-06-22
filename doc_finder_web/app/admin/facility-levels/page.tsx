"use client";

import { Layers } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Facility Levels",
  subtitle: "Health facility tier classifications",
  singular: "Facility Level",
  icon: Layers,
  gradient: "from-teal-500 to-cyan-600",
  endpoint: "/admin/reference/facility-levels",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. Level 4 Hospital" },
    { key: "level_number", label: "Level number", type: "number", required: true, default: 1 },
    { key: "description", label: "Description", type: "textarea" },
    { key: "sort_order", label: "Sort order", type: "number", default: 0 },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminFacilityLevelsPage() {
  return <ReferenceDataAdmin config={config} />;
}
