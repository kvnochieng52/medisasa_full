"use client";

import { Suspense, useEffect, useState, useCallback } from "react";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Search, X, Star, MapPin, Building2, Phone, Mail,
  Globe, RefreshCw, SortAsc, FlaskConical, Scan,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";

type FacilityTypeFilter = "lab" | "radiology";

/**
 * Homepage quick filters. Facility TYPE is the primary match — we resolve
 * the target type IDs at runtime by SLUG (the "Laboratory & Radiology" row
 * exists twice in the DB under two slugs due to a legacy typo, and matching
 * by slug is safer than hard-coding IDs). If none of that facility type
 * exist, we fall back to a service-name match.
 *
 *   Lab       → facility_type.slug ∈ { "laboratory-radiology", "laboratory" }
 *                fallback service names: lab / pathology / radiology / imaging
 *   Radiology → facility_type.slug = "radiology" (exact)
 *                fallback service names: radiology / imaging / x-ray / MRI /
 *                CT scan / ultrasound / mammogram
 */
const TYPE_FILTERS: Record<FacilityTypeFilter, {
  label: string;
  slugMatches: (slug: string) => boolean;
  matchService: RegExp;
  icon: typeof FlaskConical;
}> = {
  lab: {
    label: "Laboratory & Radiology",
    slugMatches: (slug) => slug === "laboratory-radiology" || slug === "laboratory",
    // Lab facilities in this system also cover imaging, so the fallback
    // catches both lab and radiology services.
    matchService: /\blab|patholog|radiolog|imaging|\bx[- ]?ray\b|mri|ct scan|ultrasound|mammogram/i,
    icon: FlaskConical,
  },
  radiology: {
    label: "Radiology",
    slugMatches: (slug) => slug === "radiology",
    matchService: /radiolog|imaging|\bx[- ]?ray\b|mri|ct scan|ultrasound|mammogram/i,
    icon: Scan,
  },
};

interface Specialty { id: number; specialization_name: string }
interface FacilityType { id: number; name: string; slug?: string }
interface OfferedService {
  id: number;
  facility_service_id?: number | null;
  title: string;
  amount?: string | number | null;
  service?: { id: number; name: string } | null;
}

interface Facility {
  id: number;
  facility_name: string;
  facility_profile?: string;
  facility_cover_image?: string;
  facility_logo?: string;
  facility_phone?: string;
  facility_email?: string;
  facility_location?: string;
  facility_website?: string;
  average_rating?: number;
  total_ratings?: number;
  facilityType?: FacilityType;
  specialties?: Specialty[];
  offered_services?: OfferedService[];
}

type SortKey = "rating" | "name";

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden animate-pulse">
      <div className="h-32 bg-gray-200" />
      <div className="p-4 space-y-2">
        <div className="h-4 bg-gray-200 rounded w-2/3" />
        <div className="h-3 bg-gray-100 rounded w-1/2" />
        <div className="h-3 bg-gray-100 rounded w-1/3" />
      </div>
    </div>
  );
}

function StarRow({ rating, total }: { rating: number; total: number }) {
  return (
    <div className="flex items-center gap-1">
      {[1,2,3,4,5].map(i => (
        <Star key={i} className={`w-3 h-3 ${i <= Math.round(rating) ? "text-amber-400 fill-amber-400" : "text-gray-200"}`} />
      ))}
      <span className="text-xs text-gray-500 ml-1">{rating.toFixed(1)} ({total})</span>
    </div>
  );
}

function HospitalsContent() {
  const searchParams = useSearchParams();
  const initialTypeParam = searchParams.get("type");
  const initialTypeFilter: FacilityTypeFilter | null =
    initialTypeParam === "lab" || initialTypeParam === "radiology"
      ? initialTypeParam
      : null;

  const [facilities, setFacilities] = useState<Facility[]>([]);
  const [filtered, setFiltered] = useState<Facility[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState<SortKey>("rating");
  const [showSort, setShowSort] = useState(false);
  const [typeFilter, setTypeFilter] = useState<FacilityTypeFilter | null>(initialTypeFilter);

  useEffect(() => {
    api.get("/public-facilities/approved", { params: { per_page: 50 } })
      .then(res => {
        const list: Facility[] = Array.isArray(res.data?.data) ? res.data.data : [];
        setFacilities(list);
        setFiltered(list);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);

  const applyFilterSort = useCallback((
    query: string,
    sort: SortKey,
    type: FacilityTypeFilter | null,
    list: Facility[],
  ) => {
    let result = list;

    if (type) {
      const def = TYPE_FILTERS[type];
      result = result.filter(f => {
        // Primary: facility type slug matches. Fall back to a case-insensitive
        // match against the type name for older records that lack a slug.
        const slug = f.facilityType?.slug?.toLowerCase();
        const nameSlugified = f.facilityType?.name?.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "");
        if ((slug && def.slugMatches(slug)) || (nameSlugified && def.slugMatches(nameSlugified))) {
          return true;
        }
        // Fallback: any offered service matches (title or catalogue name)
        if (f.offered_services?.some(os =>
          def.matchService.test(os.title) ||
          (os.service?.name && def.matchService.test(os.service.name))
        )) {
          return true;
        }
        return false;
      });
    }

    if (query.trim()) {
      const q = query.toLowerCase();
      result = result.filter(f =>
        f.facility_name.toLowerCase().includes(q) ||
        f.facility_location?.toLowerCase().includes(q) ||
        f.facilityType?.name.toLowerCase().includes(q) ||
        f.specialties?.some(s => s.specialization_name.toLowerCase().includes(q))
      );
    }
    result = [...result].sort((a, b) =>
      sort === "rating"
        ? (b.average_rating ?? 0) - (a.average_rating ?? 0)
        : a.facility_name.localeCompare(b.facility_name)
    );
    setFiltered(result);
  }, []);

  useEffect(() => {
    applyFilterSort(search, sortBy, typeFilter, facilities);
  }, [search, sortBy, typeFilter, facilities, applyFilterSort]);

  const activeFilter = typeFilter ? TYPE_FILTERS[typeFilter] : null;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-emerald-500 pt-28 pb-8 px-4">
        <div className="max-w-5xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            {activeFilter ? (
              <activeFilter.icon className="w-7 h-7 text-white" />
            ) : (
              <Building2 className="w-7 h-7 text-white" />
            )}
            <h1 className="text-2xl font-bold text-white">
              {activeFilter ? activeFilter.label : "Hospitals & Clinics"}
            </h1>
          </div>
          <p className="text-green-100 text-sm mb-6">
            {activeFilter
              ? `Approved facilities offering ${activeFilter.label.toLowerCase()} services`
              : "Find approved healthcare facilities near you"}
          </p>
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, location or specialty…"
              className="w-full pl-11 pr-10 py-3.5 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm"
            />
            {search && (
              <button onClick={() => setSearch("")} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
          {activeFilter && (
            <div className="mt-4 flex items-center gap-2">
              <span className="inline-flex items-center gap-2 bg-white/95 text-green-700 px-3 py-1.5 rounded-full text-xs font-semibold shadow-sm">
                <activeFilter.icon className="w-3.5 h-3.5" />
                Filtering: {activeFilter.label}
                <button
                  onClick={() => setTypeFilter(null)}
                  className="ml-1 text-green-600 hover:text-green-800"
                  aria-label="Clear filter"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Bar */}
      <div className="max-w-5xl mx-auto px-4 py-4 flex items-center justify-between">
        <p className="text-sm text-gray-500 font-medium">
          {loading ? "Loading…" : `${filtered.length} facilit${filtered.length !== 1 ? "ies" : "y"} found`}
        </p>
        <div className="relative">
          <button onClick={() => setShowSort(!showSort)}
            className="flex items-center gap-1.5 text-sm font-medium text-gray-600 bg-white px-3 py-1.5 rounded-xl shadow-sm border border-gray-100 hover:border-green-300 transition-colors">
            <SortAsc className="w-4 h-4" /> Sort: {sortBy === "rating" ? "Rating" : "Name"}
          </button>
          {showSort && (
            <div className="absolute right-0 mt-1 bg-white rounded-xl shadow-lg border border-gray-100 z-20 py-1 min-w-36">
              {(["rating","name"] as SortKey[]).map(key => (
                <button key={key} onClick={() => { setSortBy(key); setShowSort(false); }}
                  className={`w-full text-left px-4 py-2 text-sm capitalize transition-colors ${
                    sortBy === key ? "text-green-600 font-semibold bg-green-50" : "text-gray-700 hover:bg-gray-50"
                  }`}>
                  {key === "rating" ? "⭐ By Rating" : "🔤 By Name"}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Grid */}
      <div className="max-w-5xl mx-auto px-4 pb-12">
        {loading && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => <CardSkeleton key={i} />)}
          </div>
        )}

        {error && (
          <div className="text-center py-16">
            <Building2 className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-2">Failed to load facilities</p>
            <button onClick={() => window.location.reload()}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-green-500 hover:bg-green-600 text-white font-semibold text-sm rounded-xl transition-colors">
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <div className="text-center py-16">
            <Search className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-1">No facilities found</p>
            <p className="text-sm text-gray-400">Try adjusting your search</p>
          </div>
        )}

        {!loading && !error && filtered.length > 0 && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map(f => {
              const logoUrl = getImageUrl(f.facility_logo);
              const coverUrl = getImageUrl(f.facility_cover_image);
              const rating = f.average_rating ?? 0;

              return (
                <Link key={f.id} href={`/hospitals/${f.id}`} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow flex flex-col group">
                  {/* Cover */}
                  <div className="relative h-32 bg-gradient-to-br from-green-100 to-emerald-50 flex-shrink-0">
                    {coverUrl
                      ? <img src={coverUrl} alt="" className="w-full h-full object-cover" />
                      : <Building2 className="w-10 h-10 text-green-300 absolute inset-0 m-auto" />}
                    {f.facilityType && (
                      <span className="absolute top-2 right-2 text-xs font-bold bg-white/90 text-green-700 px-2.5 py-1 rounded-full shadow-sm">
                        {f.facilityType.name}
                      </span>
                    )}
                    {logoUrl && (
                      <div className="absolute -bottom-5 left-4 w-10 h-10 rounded-xl border-2 border-white shadow-sm overflow-hidden bg-white">
                        <img src={logoUrl} alt="" className="w-full h-full object-cover" />
                      </div>
                    )}
                  </div>

                  <div className="p-4 pt-7 flex flex-col flex-1">
                    <h3 className="font-bold text-gray-900 text-sm leading-tight mb-1 group-hover:text-green-700 transition-colors">{f.facility_name}</h3>
                    {f.facility_location && (
                      <div className="flex items-center gap-1 mb-2">
                        <MapPin className="w-3 h-3 text-gray-400 flex-shrink-0" />
                        <span className="text-xs text-gray-500 truncate">{f.facility_location}</span>
                      </div>
                    )}

                    {rating > 0 && <StarRow rating={rating} total={f.total_ratings ?? 0} />}

                    {f.specialties && f.specialties.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-2">
                        {f.specialties.slice(0, 3).map(s => (
                          <span key={s.id} className="text-xs bg-green-50 text-green-700 px-2 py-0.5 rounded-full">{s.specialization_name}</span>
                        ))}
                        {f.specialties.length > 3 && (
                          <span className="text-xs text-gray-400">+{f.specialties.length - 3} more</span>
                        )}
                      </div>
                    )}

                    <div className="mt-auto pt-3 flex items-center gap-2">
                      {f.facility_phone && (
                        <button
                          onClick={e => { e.preventDefault(); e.stopPropagation(); window.location.href = `tel:${f.facility_phone}`; }}
                          className="flex items-center gap-1 text-xs font-semibold text-green-600 hover:text-green-700 transition-colors">
                          <Phone className="w-3.5 h-3.5" /> Call
                        </button>
                      )}
                      {f.facility_email && (
                        <button
                          onClick={e => { e.preventDefault(); e.stopPropagation(); window.location.href = `mailto:${f.facility_email}`; }}
                          className="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 transition-colors">
                          <Mail className="w-3.5 h-3.5" /> Email
                        </button>
                      )}
                      {f.facility_website && (
                        <button
                          onClick={e => { e.preventDefault(); e.stopPropagation(); window.open(f.facility_website, '_blank', 'noreferrer'); }}
                          className="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 transition-colors ml-auto">
                          <Globe className="w-3.5 h-3.5" /> Website
                        </button>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}

export default function HospitalsPage() {
  return (
    <Suspense>
      <HospitalsContent />
    </Suspense>
  );
}
