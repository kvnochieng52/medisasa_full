"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Building2, Plus, Search, MapPin, Mail, Phone,
  Pencil, Trash2, Loader2, ChevronRight, Globe,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface FacilityType {
  id: number;
  name: string;
}

interface Facility {
  id: number;
  facility_name: string;
  facility_profile: string;
  facility_email: string;
  facility_phone: string;
  facility_location: string;
  facility_website?: string;
  facility_logo?: string;
  facility_cover_image?: string;
  is_active: number;
  facilityType?: FacilityType;
  specialties?: { id: number; specialization_name: string }[];
}

export default function FacilitiesPage() {
  const router = useRouter();
  const [facilities, setFacilities] = useState<Facility[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const fetchFacilities = (q = "") => {
    setLoading(true);
    api.get<{ success: boolean; data: Facility[] }>("/facilities", { params: q ? { search: q } : {} })
      .then(res => setFacilities(res.data.data ?? []))
      .catch(() => toast.error("Failed to load facilities"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchFacilities(); }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchFacilities(search);
  };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    setDeletingId(id);
    try {
      await api.delete(`/facilities/${id}`);
      toast.success("Facility deleted");
      setFacilities(prev => prev.filter(f => f.id !== id));
    } catch {
      toast.error("Failed to delete facility");
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-28 pb-16">

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
          <div>
            <div className="flex items-center gap-2 text-sm text-gray-500 mb-1">
              <Link href="/dashboard" className="hover:text-brand-500 transition-colors">Dashboard</Link>
              <ChevronRight className="w-3.5 h-3.5" />
              <span className="text-gray-700 font-medium">Facilities</span>
            </div>
            <h1 className="text-2xl font-bold text-gray-900">My Facilities</h1>
          </div>
          <Link
            href="/admin/facilities/new"
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-sm font-semibold transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" /> Add Facility
          </Link>
        </div>

        {/* Search */}
        <form onSubmit={handleSearch} className="mb-6">
          <div className="relative max-w-md">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, email, or location…"
              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 bg-white text-sm outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100 transition-all"
            />
          </div>
        </form>

        {/* List */}
        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 className="w-7 h-7 animate-spin text-brand-500" />
          </div>
        ) : facilities.length === 0 ? (
          <div className="bg-white rounded-2xl shadow-card p-12 text-center">
            <Building2 className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <h3 className="font-semibold text-gray-700 mb-2">No facilities yet</h3>
            <p className="text-sm text-gray-400 mb-6">Add your first clinic, hospital, or healthcare facility.</p>
            <Link
              href="/admin/facilities/new"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-sm font-semibold transition-colors"
            >
              <Plus className="w-4 h-4" /> Add Facility
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {facilities.map(f => (
              <div key={f.id} className="bg-white rounded-2xl shadow-card overflow-hidden flex flex-col">
                {/* Cover / Logo */}
                <div className="relative h-32 bg-gradient-to-br from-brand-50 to-brand-100 flex-shrink-0">
                  {f.facility_cover_image && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={getImageUrl(f.facility_cover_image)}
                      alt=""
                      className="w-full h-full object-cover"
                    />
                  )}
                  {f.facility_logo && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={getImageUrl(f.facility_logo)}
                      alt={f.facility_name}
                      className="absolute bottom-0 left-4 translate-y-1/2 w-12 h-12 rounded-xl border-2 border-white shadow object-cover bg-white"
                    />
                  )}
                  <span className={`absolute top-3 right-3 px-2 py-0.5 rounded-full text-xs font-semibold ${
                    f.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"
                  }`}>
                    {f.is_active ? "Active" : "Inactive"}
                  </span>
                </div>

                <div className={`flex-1 flex flex-col p-5 ${f.facility_logo ? "pt-8" : "pt-5"}`}>
                  <div className="mb-3">
                    <h3 className="font-bold text-gray-900 text-sm leading-tight">{f.facility_name}</h3>
                    {f.facilityType && (
                      <span className="text-xs text-brand-600 font-medium">{f.facilityType.name}</span>
                    )}
                  </div>

                  <div className="space-y-1.5 text-xs text-gray-500 mb-4 flex-1">
                    {f.facility_location && (
                      <div className="flex items-center gap-1.5">
                        <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
                        <span className="truncate">{f.facility_location}</span>
                      </div>
                    )}
                    {f.facility_email && (
                      <div className="flex items-center gap-1.5">
                        <Mail className="w-3.5 h-3.5 flex-shrink-0" />
                        <span className="truncate">{f.facility_email}</span>
                      </div>
                    )}
                    {f.facility_phone && (
                      <div className="flex items-center gap-1.5">
                        <Phone className="w-3.5 h-3.5 flex-shrink-0" />
                        <span>{f.facility_phone}</span>
                      </div>
                    )}
                    {f.facility_website && (
                      <div className="flex items-center gap-1.5">
                        <Globe className="w-3.5 h-3.5 flex-shrink-0" />
                        <a
                          href={f.facility_website}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="truncate text-brand-500 hover:underline"
                        >
                          {f.facility_website.replace(/^https?:\/\//, "")}
                        </a>
                      </div>
                    )}
                  </div>

                  {/* Specialties chips */}
                  {f.specialties && f.specialties.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 mb-4">
                      {f.specialties.slice(0, 3).map(s => (
                        <span key={s.id} className="px-2 py-0.5 bg-brand-50 text-brand-600 text-xs rounded-full">
                          {s.specialization_name}
                        </span>
                      ))}
                      {f.specialties.length > 3 && (
                        <span className="px-2 py-0.5 bg-gray-100 text-gray-500 text-xs rounded-full">
                          +{f.specialties.length - 3}
                        </span>
                      )}
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex gap-2">
                    <Link
                      href={`/admin/facilities/${f.id}/edit`}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl border border-gray-200 text-xs font-semibold text-gray-600 hover:bg-gray-50 transition-colors"
                    >
                      <Pencil className="w-3.5 h-3.5" /> Edit
                    </Link>
                    <button
                      onClick={() => handleDelete(f.id, f.facility_name)}
                      disabled={deletingId === f.id}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl border border-red-100 text-xs font-semibold text-red-500 hover:bg-red-50 transition-colors disabled:opacity-50"
                    >
                      {deletingId === f.id
                        ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        : <Trash2 className="w-3.5 h-3.5" />}
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
