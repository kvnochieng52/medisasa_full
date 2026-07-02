"use client";

import { Wrench } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Facility Services",
  subtitle: "Catalogue of services facilities can offer (Consultation, X-Ray, …)",
  singular: "Facility Service",
  icon: Wrench,
  gradient: "from-cyan-500 to-teal-600",
  endpoint: "/admin/reference/facility-services",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. General Consultation" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "sort_order", label: "Sort order", type: "number", default: 0 },
    { key: "is_active", label: "Active", type: "boolean", default: true },
  ],
};

export default function AdminFacilityServicesPage() {
  return <ReferenceDataAdmin config={config} />;
}
