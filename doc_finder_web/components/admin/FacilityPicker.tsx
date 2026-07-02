"use client";

import { useEffect, useState } from "react";
import { ChevronDown, Building2, Loader2 } from "lucide-react";
import api from "@/lib/api";

interface FacilityOption {
  id: number;
  facility_name?: string;
  name?: string;
}

/**
 * Dropdown for picking which facility a medicine / product belongs to.
 *
 * The backend already scopes GET /facilities:
 *   - admin (account_type = 3): all facilities in the platform
 *   - anyone else:              their own facilities only
 *
 * So this picker just reads from that endpoint and doesn't need to know the
 * caller's role.
 */
export default function FacilityPicker({
  value,
  onChange,
  required = true,
  label = "Facility",
  hint,
}: {
  value: string;
  onChange: (id: string) => void;
  required?: boolean;
  label?: string;
  hint?: string;
}) {
  const [facilities, setFacilities] = useState<FacilityOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    api.get<{ data: FacilityOption[] }>("/facilities")
      .then(res => setFacilities(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setError("Failed to load facilities"))
      .finally(() => setLoading(false));
  }, []);

  const empty = !loading && facilities.length === 0;

  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">
        {label}{required && <span className="text-red-400 ml-0.5">*</span>}
      </label>

      <div className="relative">
        <Building2 className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <select
          value={value}
          onChange={e => onChange(e.target.value)}
          disabled={loading || empty}
          className="w-full pl-10 pr-10 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none appearance-none focus:bg-white focus:border-brand-400 disabled:opacity-60"
        >
          <option value="">
            {loading
              ? "Loading facilities…"
              : empty
                ? "No facilities available — create one first"
                : "Select facility"}
          </option>
          {facilities.map(f => (
            <option key={f.id} value={f.id}>
              {f.facility_name ?? f.name ?? `Facility #${f.id}`}
            </option>
          ))}
        </select>
        {loading
          ? <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 animate-spin" />
          : <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />}
      </div>

      {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
      {empty && !error && (
        <p className="text-xs text-amber-600 mt-1">
          You have no facilities yet — <a href="/admin/facilities/new" className="underline font-semibold">create one</a> before adding medicines or products.
        </p>
      )}
      {hint && !empty && <p className="text-xs text-gray-400 mt-1">{hint}</p>}
    </div>
  );
}
