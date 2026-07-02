import Link from "next/link";
import { Building2, MapPin, Phone, Mail, ChevronRight } from "lucide-react";
import { getImageUrl } from "@/lib/api";

export interface SoldByFacilityData {
  id: number;
  facility_name?: string | null;
  facility_phone?: string | null;
  facility_email?: string | null;
  facility_location?: string | null;
  facility_website?: string | null;
  facility_logo?: string | null;
}

/**
 * Compact "Sold by" card used on medicine + product detail pages so shoppers
 * know which facility is supplying the item.
 */
export default function SoldByFacility({
  facility,
  accent = "orange",
}: {
  facility: SoldByFacilityData | null | undefined;
  accent?: "orange" | "green" | "brand";
}) {
  if (!facility) return null;

  const name = facility.facility_name ?? "Facility";
  const logo = facility.facility_logo ? getImageUrl(facility.facility_logo) : "";

  const tones = {
    orange: {
      icon: "text-orange-500",
      chipBg: "bg-orange-50",
      link: "text-orange-600 hover:text-orange-700",
    },
    green: {
      icon: "text-green-500",
      chipBg: "bg-green-50",
      link: "text-green-600 hover:text-green-700",
    },
    brand: {
      icon: "text-brand-500",
      chipBg: "bg-brand-50",
      link: "text-brand-600 hover:text-brand-700",
    },
  }[accent];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">
        Sold by
      </p>

      <div className="flex items-start gap-3">
        <div className={`w-12 h-12 rounded-xl ${tones.chipBg} flex-shrink-0 overflow-hidden flex items-center justify-center`}>
          {logo
            ? <img src={logo} alt={name} className="w-full h-full object-cover" />
            : <Building2 className={`w-5 h-5 ${tones.icon}`} />}
        </div>

        <div className="min-w-0 flex-1">
          <Link
            href={`/hospitals/${facility.id}`}
            className={`text-sm font-bold text-gray-900 hover:underline inline-flex items-center gap-1`}
          >
            {name}
            <ChevronRight className={`w-3.5 h-3.5 ${tones.link}`} />
          </Link>

          <ul className="mt-2 space-y-1.5 text-xs text-gray-600">
            {facility.facility_location && (
              <li className="flex items-start gap-2">
                <MapPin className="w-3.5 h-3.5 text-gray-400 flex-shrink-0 mt-0.5" />
                <span className="leading-relaxed">{facility.facility_location}</span>
              </li>
            )}
            {facility.facility_phone && (
              <li className="flex items-center gap-2">
                <Phone className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                <a
                  href={`tel:${facility.facility_phone}`}
                  className={tones.link}
                >
                  {facility.facility_phone}
                </a>
              </li>
            )}
            {facility.facility_email && (
              <li className="flex items-center gap-2">
                <Mail className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                <a
                  href={`mailto:${facility.facility_email}`}
                  className={`${tones.link} truncate`}
                >
                  {facility.facility_email}
                </a>
              </li>
            )}
          </ul>
        </div>
      </div>
    </div>
  );
}
