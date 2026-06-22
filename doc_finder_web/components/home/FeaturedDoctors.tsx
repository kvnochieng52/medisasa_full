"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Star, MapPin, Heart, ChevronRight, Stethoscope } from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { getInitials } from "@/lib/utils";

interface Doctor {
  id: number;
  name: string;
  specialties?: string[];
  specialty?: string;
  bio?: string;
  location?: string;
  profile_image?: string;
  rating?: number;
  average_rating?: number;
  total_ratings?: number;
  consultation_fee?: number | string;
  is_available?: boolean;
  telephone?: string;
}

function DoctorCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl p-5 shadow-card animate-pulse">
      <div className="flex items-start gap-4">
        <div className="w-16 h-16 rounded-xl bg-gray-200 flex-shrink-0" />
        <div className="flex-1 space-y-2">
          <div className="h-4 bg-gray-200 rounded w-3/4" />
          <div className="h-3 bg-gray-100 rounded w-1/2" />
          <div className="h-3 bg-gray-100 rounded w-2/3" />
        </div>
      </div>
      <div className="mt-4 flex gap-2">
        <div className="h-9 bg-gray-100 rounded-xl flex-1" />
        <div className="h-9 w-9 bg-gray-100 rounded-xl" />
      </div>
    </div>
  );
}

function DoctorCard({ doctor }: { doctor: Doctor }) {
  const [favorited, setFavorited] = useState(false);
  const imageUrl = getImageUrl(doctor.profile_image);
  const rating = doctor.rating ?? doctor.average_rating ?? 0;
  const specialty =
    (doctor.specialties && doctor.specialties.length > 0
      ? doctor.specialties.join(" · ")
      : null) ??
    doctor.specialty ??
    "General Practitioner";

  return (
    <div className="bg-white rounded-2xl p-5 shadow-card hover:shadow-card-hover transition-all duration-300 hover:-translate-y-0.5 group">
      <div className="flex items-start gap-4">
        {/* Avatar */}
        <div className="relative flex-shrink-0">
          {imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={imageUrl}
              alt={doctor.name}
              className="w-16 h-16 rounded-xl object-cover"
            />
          ) : (
            <div className="w-16 h-16 rounded-xl bg-brand-50 flex items-center justify-center text-brand-600 font-bold text-lg">
              {getInitials(doctor.name)}
            </div>
          )}
          {doctor.is_available && (
            <span className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-400 border-2 border-white rounded-full" />
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-gray-900 text-sm leading-tight truncate group-hover:text-brand-500 transition-colors">
            Dr. {doctor.name}
          </h3>
          <p className="text-xs text-brand-500 font-medium mt-0.5 truncate">
            {specialty}
          </p>

          {/* Rating */}
          {rating > 0 && (
            <div className="flex items-center gap-1 mt-1.5">
              <Star className="w-3.5 h-3.5 text-yellow-400 fill-yellow-400" />
              <span className="text-xs font-semibold text-gray-700">
                {rating.toFixed(1)}
              </span>
              {doctor.total_ratings && (
                <span className="text-xs text-gray-400">
                  ({doctor.total_ratings})
                </span>
              )}
            </div>
          )}

          {/* Location */}
          {doctor.location && (
            <div className="flex items-center gap-1 mt-1">
              <MapPin className="w-3 h-3 text-gray-400" />
              <span className="text-xs text-gray-500 truncate">{doctor.location}</span>
            </div>
          )}
        </div>
      </div>

      {/* Phone */}
      {doctor.telephone && (
        <div className="mt-3 flex items-center gap-1.5 text-xs text-gray-400">
          <span className="w-1.5 h-1.5 rounded-full bg-green-400 inline-block" />
          Available for booking
        </div>
      )}

      {/* Actions */}
      <div className="mt-4 flex gap-2">
        <Link
          href={`/doctors/${doctor.id}`}
          className="flex-1 btn-primary text-xs py-2 text-center"
        >
          Book Appointment
        </Link>
        <button
          onClick={() => setFavorited(!favorited)}
          className={`w-9 h-9 rounded-xl border flex items-center justify-center transition-colors ${
            favorited
              ? "bg-red-50 border-red-200 text-red-500"
              : "border-gray-200 text-gray-400 hover:border-red-200 hover:text-red-400"
          }`}
        >
          <Heart className={`w-4 h-4 ${favorited ? "fill-red-500" : ""}`} />
        </button>
      </div>
    </div>
  );
}

export default function FeaturedDoctors() {
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    api
      .get("/doctors/approved?per_page=6")
      .then((res) => {
        const data = res.data;
        const list: Doctor[] = Array.isArray(data?.data)
          ? data.data
          : data?.data?.doctors ?? data?.doctors ?? [];
        setDoctors(list.slice(0, 6));
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);

  return (
    <section className="py-12 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 rounded-lg bg-brand-50">
                <Stethoscope className="w-4 h-4 text-brand-500" />
              </div>
              <span className="text-sm font-medium text-brand-500 uppercase tracking-wide">
                Healthcare Professionals
              </span>
            </div>
            <h2 className="section-title text-2xl">Featured Doctors</h2>
          </div>
          <Link
            href="/doctors"
            className="hidden sm:flex items-center gap-1 text-sm font-medium text-brand-500 hover:text-brand-600 transition-colors"
          >
            View All
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Cards grid */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {Array.from({ length: 6 }).map((_, i) => (
              <DoctorCardSkeleton key={i} />
            ))}
          </div>
        ) : error || doctors.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl">
            <Stethoscope className="w-12 h-12 text-gray-200 mx-auto mb-3" />
            <p className="text-gray-400">
              {error ? "Unable to load doctors right now." : "No doctors available."}
            </p>
            <Link href="/doctors" className="btn-primary mt-4 inline-block text-sm">
              Browse All Doctors
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {doctors.map((doctor) => (
              <DoctorCard key={doctor.id} doctor={doctor} />
            ))}
          </div>
        )}

        {/* Mobile view all */}
        <div className="sm:hidden mt-6 text-center">
          <Link href="/doctors" className="btn-outline text-sm inline-flex items-center gap-1">
            View All Doctors
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}
