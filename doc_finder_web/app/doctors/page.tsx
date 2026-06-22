"use client";

import { useEffect, useState, useCallback, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Search, X, Star, MapPin, Stethoscope, ChevronRight,
  SortAsc, RefreshCw, BadgeCheck, Loader2,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { getInitials } from "@/lib/utils";

interface Doctor {
  id: number;
  name: string;
  specialties?: string[];
  bio?: string;
  location?: string;
  profile_image?: string;
  rating?: number;
  telephone?: string;
  availability?: string[];
}

type SortKey = "rating" | "name";

function DoctorCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl p-5 shadow-card animate-pulse flex gap-4">
      <div className="w-16 h-16 rounded-full bg-gray-200 flex-shrink-0" />
      <div className="flex-1 space-y-2 py-1">
        <div className="h-4 bg-gray-200 rounded w-2/3" />
        <div className="h-3 bg-gray-100 rounded w-1/2" />
        <div className="h-3 bg-gray-100 rounded w-1/3" />
        <div className="h-3 bg-gray-100 rounded w-1/4" />
      </div>
      <div className="w-5 h-5 bg-gray-100 rounded self-center" />
    </div>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          className={`w-3.5 h-3.5 ${i <= Math.round(rating) ? "text-amber-400 fill-amber-400" : "text-gray-200"}`}
        />
      ))}
      <span className="text-xs font-semibold text-gray-600 ml-1">{rating.toFixed(1)}</span>
    </div>
  );
}

function DoctorsPageInner() {
  const searchParams = useSearchParams();
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [filtered, setFiltered] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState(searchParams.get("q") ?? "");
  const [sortBy, setSortBy] = useState<SortKey>("rating");
  const [showSort, setShowSort] = useState(false);

  useEffect(() => {
    api
      .get("/doctors/approved", { params: { per_page: 100 } })
      .then((res) => {
        const data = res.data;
        const list: Doctor[] = Array.isArray(data?.data) ? data.data : [];
        setDoctors(list);
        setFiltered(list);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);

  const applyFilterSort = useCallback(
    (query: string, sort: SortKey, list: Doctor[]) => {
      let result = list;
      if (query.trim()) {
        const q = query.toLowerCase();
        result = result.filter(
          (d) =>
            d.name.toLowerCase().includes(q) ||
            d.specialties?.some((s) => s.toLowerCase().includes(q)) ||
            d.location?.toLowerCase().includes(q)
        );
      }
      result = [...result].sort((a, b) => {
        if (sort === "rating") return (b.rating ?? 0) - (a.rating ?? 0);
        return a.name.localeCompare(b.name);
      });
      setFiltered(result);
    },
    []
  );

  useEffect(() => {
    applyFilterSort(search, sortBy, doctors);
  }, [search, sortBy, doctors, applyFilterSort]);

  const sortLabel = sortBy === "rating" ? "Rating" : "Name";

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Header */}
      <div className="bg-gradient-to-r from-brand-500 to-brand-600 pt-28 pb-8 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            <Stethoscope className="w-7 h-7 text-white" />
            <h1 className="text-2xl font-bold text-white">Find a Doctor</h1>
          </div>
          <p className="text-brand-100 text-sm mb-6">
            Browse our network of verified, approved specialists
          </p>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name, specialty or location…"
              className="w-full pl-11 pr-10 py-3.5 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm"
            />
            {search && (
              <button
                onClick={() => setSearch("")}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Stats & sort bar */}
      <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
        <p className="text-sm text-gray-500 font-medium">
          {loading ? "Loading…" : `${filtered.length} doctor${filtered.length !== 1 ? "s" : ""} found`}
        </p>
        <div className="relative">
          <button
            onClick={() => setShowSort(!showSort)}
            className="flex items-center gap-1.5 text-sm font-medium text-gray-600 bg-white px-3 py-1.5 rounded-xl shadow-sm border border-gray-100 hover:border-brand-300 transition-colors"
          >
            <SortAsc className="w-4 h-4" />
            Sort: {sortLabel}
          </button>
          {showSort && (
            <div className="absolute right-0 mt-1 bg-white rounded-xl shadow-lg border border-gray-100 z-20 py-1 min-w-36">
              {(["rating", "name"] as SortKey[]).map((key) => (
                <button
                  key={key}
                  onClick={() => { setSortBy(key); setShowSort(false); }}
                  className={`w-full text-left px-4 py-2 text-sm capitalize transition-colors ${
                    sortBy === key ? "text-brand-600 font-semibold bg-brand-50" : "text-gray-700 hover:bg-gray-50"
                  }`}
                >
                  {key === "rating" ? "⭐ By Rating" : "🔤 By Name"}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* List */}
      <div className="max-w-4xl mx-auto px-4 pb-12 space-y-3">
        {loading && Array.from({ length: 6 }).map((_, i) => <DoctorCardSkeleton key={i} />)}

        {error && (
          <div className="text-center py-16">
            <Stethoscope className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-2">Failed to load doctors</p>
            <button
              onClick={() => window.location.reload()}
              className="btn-primary text-sm inline-flex items-center gap-2"
            >
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <div className="text-center py-16">
            <Search className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="font-semibold text-gray-600 mb-1">No doctors found</p>
            <p className="text-sm text-gray-400">Try adjusting your search or filters</p>
          </div>
        )}

        {!loading &&
          filtered.map((doctor) => {
            const imageUrl = getImageUrl(doctor.profile_image);
            const specialty = doctor.specialties?.length
              ? doctor.specialties.join(" · ")
              : "General Practice";
            const rating = doctor.rating ?? 0;
            const isTopRated = rating >= 4.5;

            return (
              <Link
                key={doctor.id}
                href={`/doctors/${doctor.id}`}
                className="bg-white rounded-2xl p-5 shadow-card hover:shadow-card-hover transition-all duration-200 hover:-translate-y-0.5 flex items-center gap-4 group"
              >
                {/* Avatar */}
                <div className="relative flex-shrink-0">
                  {imageUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={imageUrl}
                      alt={doctor.name}
                      className="w-16 h-16 rounded-full object-cover"
                    />
                  ) : (
                    <div className="w-16 h-16 rounded-full bg-brand-100 flex items-center justify-center text-brand-600 font-bold text-lg">
                      {getInitials(doctor.name)}
                    </div>
                  )}
                  {isTopRated && (
                    <div className="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-green-400 border-2 border-white flex items-center justify-center">
                      <BadgeCheck className="w-3 h-3 text-white" />
                    </div>
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="font-bold text-gray-900 text-sm group-hover:text-brand-600 transition-colors">
                      {doctor.name}
                    </h3>
                    {isTopRated && (
                      <span className="text-xs font-bold text-green-700 bg-green-100 px-2 py-0.5 rounded-full">
                        Top Rated
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-brand-500 font-medium mt-0.5 truncate">{specialty}</p>
                  {doctor.location && (
                    <div className="flex items-center gap-1 mt-1">
                      <MapPin className="w-3 h-3 text-gray-400 flex-shrink-0" />
                      <span className="text-xs text-gray-500 truncate">{doctor.location}</span>
                    </div>
                  )}
                  <div className="mt-1.5">
                    {rating > 0 ? (
                      <StarRating rating={rating} />
                    ) : (
                      <span className="text-xs text-gray-400 italic">No ratings yet</span>
                    )}
                  </div>
                </div>

                <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-brand-400 flex-shrink-0 transition-colors" />
              </Link>
            );
          })}
      </div>
    </main>
  );
}

export default function DoctorsPage() {
  return (
    <Suspense fallback={
      <main className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
      </main>
    }>
      <DoctorsPageInner />
    </Suspense>
  );
}
