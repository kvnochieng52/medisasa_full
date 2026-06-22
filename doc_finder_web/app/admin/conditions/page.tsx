"use client";

import { Activity } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Conditions",
  subtitle: "Medical conditions used for the doctor finder and screenings",
  singular: "Condition",
  icon: Activity,
  gradient: "from-rose-500 to-pink-600",
  endpoint: "/admin/reference/conditions",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. Diabetes Mellitus" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminConditionsPage() {
  return <ReferenceDataAdmin config={config} />;
}
