"use client";

import { Stethoscope } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Specializations",
  subtitle: "Doctor specialties used across the platform",
  singular: "Specialization",
  icon: Stethoscope,
  gradient: "from-blue-500 to-indigo-600",
  endpoint: "/admin/reference/specializations",
  primaryField: "specialization_name",
  secondaryField: "specialization_description",
  fields: [
    { key: "specialization_name", label: "Name", type: "text", required: true, placeholder: "e.g. Cardiologist" },
    { key: "specialization_description", label: "Description", type: "textarea", placeholder: "What this specialty covers" },
    { key: "is_active", label: "Active", type: "boolean", default: true },
    { key: "is_active_for_facility", label: "Active for facilities", type: "boolean", default: true },
  ],
};

export default function AdminSpecializationsPage() {
  return <ReferenceDataAdmin config={config} />;
}
