"use client";

import { Thermometer } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Symptoms",
  subtitle: "Symptoms used to power the doctor finder and triage",
  singular: "Symptom",
  icon: Thermometer,
  gradient: "from-purple-500 to-fuchsia-600",
  endpoint: "/admin/reference/symptoms",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. Chest pain" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminSymptomsPage() {
  return <ReferenceDataAdmin config={config} />;
}
