"use client";

import { Users } from "lucide-react";
import ReferenceDataAdmin, { ReferenceConfig } from "@/components/admin/ReferenceDataAdmin";

const config: ReferenceConfig = {
  title: "Group Categories",
  subtitle: "Categories used to organise support groups",
  singular: "Group Category",
  icon: Users,
  gradient: "from-orange-500 to-red-500",
  endpoint: "/admin/reference/group-categories",
  primaryField: "name",
  secondaryField: "description",
  fields: [
    { key: "name", label: "Name", type: "text", required: true, placeholder: "e.g. Mental Health Support" },
    { key: "description", label: "Description", type: "textarea" },
    { key: "position", label: "Position", type: "number", default: 0 },
  ],
};

export default function AdminGroupCategoriesPage() {
  return <ReferenceDataAdmin config={config} />;
}
