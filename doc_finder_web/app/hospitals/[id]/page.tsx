"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  ArrowLeft, Building2, MapPin, Phone, Mail, Globe,
  Star, Shield, Stethoscope, Loader2, AlertCircle,
  CheckCircle2, ChevronRight, Clock,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";

interface Specialty { id: number; specialization_name: string }
interface FacilityType { id: number; name: string }
interface FacilityLevel { id: number; name: string }
interface Insurance { id: number; name: string }
interface OfferedService {
  id: number;
  facility_service_id?: number | null;
  title: string;
  description?: string | null;
  amount?: string | number | null;
  currency?: string | null;
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
  facility_description?: string;
  facility_services?: string;   // legacy free-text field, kept as a fallback
  operating_hours?: string;
  average_rating?: number;
  total_ratings?: number;
  facilityType?: FacilityType;
  facilityLevel?: FacilityLevel;
  specialties?: Specialty[];
  insurances?: Insurance[];
  offered_services?: OfferedService[];
  is_active?: boolean;
}

function formatKES(amount: string | number | null | undefined, currency?: string | null): string {
  if (amount == null || amount === "") return "";
  const n = typeof amount === "number" ? amount : Number(amount);
  if (Number.isNaN(n)) return "";
  const code = (currency || "KES").toUpperCase();
  try {
    return `${code} ${n.toLocaleString("en-KE", { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
  } catch {
    return `${code} ${n}`;
  }
}

function StarRow({ rating, total }: { rating: number; total: number }) {
  return (
    <div className="flex items-center gap-1.5">
      {[1, 2, 3, 4, 5].map(i => (
        <Star key={i} className={`w-4 h-4 ${i <= Math.round(rating) ? "text-amber-400 fill-amber-400" : "text-gray-200"}`} />
      ))}
      <span className="text-sm font-semibold text-gray-700 ml-1">{rating.toFixed(1)}</span>
      <span className="text-sm text-gray-400">({total} review{total !== 1 ? "s" : ""})</span>
    </div>
  );
}

export default function HospitalDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [facility, setFacility] = useState<Facility | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    api.get(`/public-facilities/${id}`)
      .then(res => setFacility(res.data?.data ?? null))
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center min-h-screen">
          <Loader2 className="w-8 h-8 animate-spin text-green-500" />
        </div>
      </main>
    );
  }

  if (error || !facility) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex flex-col items-center justify-center min-h-screen gap-4">
          <AlertCircle className="w-12 h-12 text-gray-300" />
          <p className="text-gray-500">Facility not found.</p>
          <Link href="/hospitals" className="text-green-600 font-semibold hover:underline flex items-center gap-1">
            <ArrowLeft className="w-4 h-4" /> Back to Hospitals
          </Link>
        </div>
      </main>
    );
  }

  const coverUrl = getImageUrl(facility.facility_cover_image);
  const logoUrl  = getImageUrl(facility.facility_logo);
  const rating   = facility.average_rating ?? 0;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Cover image */}
      <div className="relative h-52 sm:h-64 bg-gradient-to-br from-green-600 to-emerald-500 mt-16">
        {coverUrl
          ? <img src={coverUrl} alt="" className="w-full h-full object-cover" />
          : <Building2 className="w-16 h-16 text-white/30 absolute inset-0 m-auto" />}
        <div className="absolute inset-0 bg-black/30" />

        {/* Back button */}
        <Link href="/hospitals"
          className="absolute top-4 left-4 flex items-center gap-1.5 text-white text-sm font-semibold bg-black/30 hover:bg-black/50 px-3 py-1.5 rounded-xl transition-colors backdrop-blur-sm">
          <ArrowLeft className="w-4 h-4" /> Hospitals
        </Link>
      </div>

      {/* Header card */}
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 -mt-10 relative z-10 p-5">
          <div className="flex items-start gap-4">
            {/* Logo */}
            <div className="w-16 h-16 rounded-2xl border-2 border-gray-100 bg-white shadow-sm overflow-hidden flex-shrink-0 flex items-center justify-center">
              {logoUrl
                ? <img src={logoUrl} alt="" className="w-full h-full object-cover" />
                : <Building2 className="w-8 h-8 text-green-400" />}
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap mb-1">
                <h1 className="text-xl font-bold text-gray-900 leading-tight">{facility.facility_name}</h1>
                {facility.is_active && (
                  <span className="flex items-center gap-1 text-xs font-bold text-green-600 bg-green-50 px-2 py-0.5 rounded-full">
                    <CheckCircle2 className="w-3 h-3" /> Active
                  </span>
                )}
              </div>

              {facility.facilityType && (
                <span className="inline-block text-xs font-semibold text-emerald-700 bg-emerald-50 px-2.5 py-0.5 rounded-full mb-2">
                  {facility.facilityType.name}
                </span>
              )}

              {facility.facility_location && (
                <div className="flex items-center gap-1.5 text-sm text-gray-500 mb-2">
                  <MapPin className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                  {facility.facility_location}
                </div>
              )}

              {rating > 0 && <StarRow rating={rating} total={facility.total_ratings ?? 0} />}
            </div>
          </div>

          {/* Contact actions */}
          <div className="flex flex-wrap gap-2 mt-4 pt-4 border-t border-gray-100">
            {facility.facility_phone && (
              <a href={`tel:${facility.facility_phone}`}
                className="flex items-center gap-2 px-4 py-2 bg-green-500 hover:bg-green-600 text-white text-sm font-semibold rounded-xl transition-colors">
                <Phone className="w-4 h-4" /> Call
              </a>
            )}
            {facility.facility_email && (
              <a href={`mailto:${facility.facility_email}`}
                className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 hover:border-green-300 text-gray-700 text-sm font-semibold rounded-xl transition-colors">
                <Mail className="w-4 h-4" /> Email
              </a>
            )}
            {facility.facility_website && (
              <a href={facility.facility_website} target="_blank" rel="noreferrer"
                className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 hover:border-green-300 text-gray-700 text-sm font-semibold rounded-xl transition-colors">
                <Globe className="w-4 h-4" /> Website
              </a>
            )}
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="max-w-4xl mx-auto px-4 py-6 pb-16 space-y-5">

        {/* About */}
        {facility.facility_description && (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
              <Building2 className="w-4 h-4 text-green-500" /> About
            </h2>
            <p className="text-sm text-gray-600 leading-relaxed">{facility.facility_description}</p>
          </div>
        )}

        <div className="grid sm:grid-cols-2 gap-5">

          {/* Specialties */}
          {facility.specialties && facility.specialties.length > 0 && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
                <Stethoscope className="w-4 h-4 text-green-500" /> Specialties
              </h2>
              <div className="flex flex-wrap gap-2">
                {facility.specialties.map(s => (
                  <span key={s.id} className="text-xs font-medium bg-green-50 text-green-700 px-3 py-1 rounded-full">
                    {s.specialization_name}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Insurance */}
          {facility.insurances && facility.insurances.length > 0 && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
                <Shield className="w-4 h-4 text-green-500" /> Accepted Insurance
              </h2>
              <div className="flex flex-wrap gap-2">
                {facility.insurances.map(ins => (
                  <span key={ins.id} className="text-xs font-medium bg-blue-50 text-blue-700 px-3 py-1 rounded-full">
                    {ins.name}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Services */}
        {(facility.offered_services?.length ?? 0) > 0 ? (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h2 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-green-500" />
              Services Offered
              <span className="text-xs font-medium text-gray-400">({facility.offered_services?.length})</span>
            </h2>
            <ul className="divide-y divide-gray-100">
              {facility.offered_services!.map(svc => {
                const price = formatKES(svc.amount, svc.currency);
                return (
                  <li key={svc.id} className="py-3 flex items-start justify-between gap-4">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-gray-900">{svc.title}</p>
                      {svc.description && (
                        <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{svc.description}</p>
                      )}
                    </div>
                    {price && (
                      <span className="text-sm font-bold text-green-700 whitespace-nowrap flex-shrink-0">
                        {price}
                      </span>
                    )}
                  </li>
                );
              })}
            </ul>
          </div>
        ) : facility.facility_services ? (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-green-500" /> Services Offered
            </h2>
            <p className="text-sm text-gray-600 leading-relaxed">{facility.facility_services}</p>
          </div>
        ) : null}

        {/* Operating hours + level */}
        <div className="grid sm:grid-cols-2 gap-5">
          {facility.operating_hours && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h2 className="font-bold text-gray-900 mb-2 flex items-center gap-2">
                <Clock className="w-4 h-4 text-green-500" /> Operating Hours
              </h2>
              <p className="text-sm text-gray-600">{facility.operating_hours}</p>
            </div>
          )}

          {facility.facilityLevel && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h2 className="font-bold text-gray-900 mb-2 flex items-center gap-2">
                <Building2 className="w-4 h-4 text-green-500" /> Facility Level
              </h2>
              <p className="text-sm text-gray-600">{facility.facilityLevel.name}</p>
            </div>
          )}
        </div>

        {/* Book appointment CTA */}
        <div className="bg-gradient-to-r from-green-500 to-emerald-500 rounded-2xl p-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <p className="font-bold text-white text-lg">Need an Appointment?</p>
            <p className="text-green-100 text-sm mt-0.5">Find a doctor at this facility and book online.</p>
          </div>
          <Link href="/doctors"
            className="flex items-center gap-2 bg-white text-green-700 font-bold text-sm px-5 py-2.5 rounded-xl hover:bg-green-50 transition-colors flex-shrink-0">
            Find Doctors <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </main>
  );
}
