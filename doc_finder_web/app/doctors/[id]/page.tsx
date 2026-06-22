"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import {
  ArrowLeft, MapPin, Star, Phone, Clock, Stethoscope,
  Calendar, Heart, Loader2, AlertCircle, User,
  Building2, ChevronLeft, ChevronRight, X, MessageCircle,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { getInitials } from "@/lib/utils";
import toast from "react-hot-toast";

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

interface Rating {
  id: number;
  user_name?: string;
  rating: number;
  review?: string;
  created_at?: string;
}

type AppointmentType = "In-Person" | "Online";

const MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"];
const DAYS = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
const TIME_SLOTS = ["9:00 AM","10:00 AM","11:00 AM","1:00 PM","2:00 PM","3:00 PM","4:00 PM"];

function StarRating({ value, size = "md" }: { value: number; size?: "sm" | "md" }) {
  const sz = size === "sm" ? "w-3.5 h-3.5" : "w-4 h-4";
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <Star key={i} className={`${sz} ${i <= Math.round(value) ? "text-amber-400 fill-amber-400" : "text-gray-200"}`} />
      ))}
    </div>
  );
}

/* ───────── Mini Calendar ───────── */
function MiniCalendar({ selected, onSelect }: { selected: Date; onSelect: (d: Date) => void }) {
  const [viewDate, setViewDate] = useState(new Date());
  const today = new Date(); today.setHours(0,0,0,0);

  const year = viewDate.getFullYear();
  const month = viewDate.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const prevMonth = () => setViewDate(new Date(year, month - 1, 1));
  const nextMonth = () => setViewDate(new Date(year, month + 1, 1));

  const cells: (number | null)[] = [...Array(firstDay).fill(null), ...Array.from({length: daysInMonth}, (_, i) => i + 1)];

  return (
    <div className="select-none">
      <div className="flex items-center justify-between mb-3">
        <button onClick={prevMonth} className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors">
          <ChevronLeft className="w-4 h-4 text-gray-500" />
        </button>
        <span className="font-bold text-gray-800 text-sm">{MONTHS[month]} {year}</span>
        <button onClick={nextMonth} className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors">
          <ChevronRight className="w-4 h-4 text-gray-500" />
        </button>
      </div>
      <div className="grid grid-cols-7 mb-1">
        {DAYS.map(d => <div key={d} className="text-center text-xs font-semibold text-gray-400 py-1">{d}</div>)}
      </div>
      <div className="grid grid-cols-7 gap-0.5">
        {cells.map((day, i) => {
          if (!day) return <div key={i} />;
          const date = new Date(year, month, day);
          date.setHours(0,0,0,0);
          const isPast = date < today;
          const isToday = date.getTime() === today.getTime();
          const isSelected = selected.getFullYear() === year && selected.getMonth() === month && selected.getDate() === day;
          return (
            <button
              key={i}
              disabled={isPast}
              onClick={() => onSelect(new Date(year, month, day))}
              className={`aspect-square rounded-full text-xs font-medium transition-all flex items-center justify-center
                ${isPast ? "text-gray-300 cursor-not-allowed" : "hover:bg-brand-50 cursor-pointer"}
                ${isSelected ? "bg-brand-500 text-white hover:bg-brand-600" : ""}
                ${isToday && !isSelected ? "border border-brand-400 text-brand-600 font-bold" : "text-gray-700"}
              `}
            >
              {day}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ───────── Appointment Booking Modal ───────── */
function AppointmentModal({
  doctor,
  selectedDate,
  onClose,
}: {
  doctor: Doctor;
  selectedDate: Date;
  onClose: () => void;
}) {
  const [type, setType] = useState<AppointmentType>("In-Person");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [time, setTime] = useState("");
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const formattedDate = `${String(selectedDate.getDate()).padStart(2,"0")}-${String(selectedDate.getMonth()+1).padStart(2,"0")}-${selectedDate.getFullYear()}`;

  const handleBook = async () => {
    if (!name.trim() || !email.trim() || !phone.trim() || !time) {
      toast.error("Please fill in all required fields and select a time.");
      return;
    }
    setSubmitting(true);
    try {
      await api.post("/appointments/book", {
        doctor_id: doctor.id,
        appointment_date: `${selectedDate.getFullYear()}-${String(selectedDate.getMonth()+1).padStart(2,"0")}-${String(selectedDate.getDate()).padStart(2,"0")}`,
        appointment_time: time,
        appointment_type: type,
        patient_name: name,
        patient_email: email,
        patient_phone: phone,
        notes,
      });
      toast.success("Appointment booked successfully!");
      onClose();
    } catch {
      toast.error("Failed to book appointment. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 px-0 sm:px-4" onClick={onClose}>
      <div
        className="bg-white w-full sm:max-w-md rounded-t-3xl sm:rounded-3xl p-6 max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-gray-900">Book Appointment</h3>
            <p className="text-brand-500 text-sm font-semibold">{formattedDate}</p>
          </div>
          <button onClick={onClose} className="p-2 rounded-full hover:bg-gray-100 transition-colors">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Appointment type */}
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Appointment Type</p>
        <div className="grid grid-cols-2 gap-2 mb-4">
          {(["In-Person","Online"] as AppointmentType[]).map((t) => (
            <button
              key={t}
              onClick={() => setType(t)}
              className={`py-2.5 rounded-xl border text-sm font-semibold transition-all ${
                type === t ? "bg-brand-500 border-brand-500 text-white" : "border-gray-200 text-gray-600 hover:border-brand-300"
              }`}
            >
              {t === "In-Person" ? "🏥 In-Person" : "💻 Online"}
            </button>
          ))}
        </div>

        {/* Patient details */}
        <div className="space-y-3 mb-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Full Name *</label>
            <input value={name} onChange={e=>setName(e.target.value)} placeholder="Your full name"
              className="mt-1 w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm bg-gray-50 outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100" />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Email *</label>
            <input value={email} onChange={e=>setEmail(e.target.value)} type="email" placeholder="your@email.com"
              className="mt-1 w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm bg-gray-50 outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100" />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Phone *</label>
            <input value={phone} onChange={e=>setPhone(e.target.value)} type="tel" placeholder="+254 7XX XXX XXX"
              className="mt-1 w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm bg-gray-50 outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100" />
          </div>
        </div>

        {/* Time slot */}
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Select Time *</p>
        <div className="grid grid-cols-3 gap-2 mb-4">
          {TIME_SLOTS.map((t) => (
            <button key={t} onClick={() => setTime(t)}
              className={`py-2 rounded-xl border text-xs font-semibold transition-all ${
                time === t ? "bg-brand-500 border-brand-500 text-white" : "border-gray-200 text-gray-600 hover:border-brand-300"
              }`}
            >
              {t}
            </button>
          ))}
        </div>

        {/* Notes */}
        <div className="mb-5">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Notes (optional)</label>
          <textarea value={notes} onChange={e=>setNotes(e.target.value)} rows={2} placeholder="Symptoms or reason for visit…"
            className="mt-1 w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm bg-gray-50 outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100 resize-none" />
        </div>

        <button onClick={handleBook} disabled={submitting}
          className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white font-bold text-sm transition-colors flex items-center justify-center gap-2">
          {submitting ? <><Loader2 className="w-4 h-4 animate-spin"/> Booking…</> : <><Calendar className="w-4 h-4"/> Book Appointment</>}
        </button>
      </div>
    </div>
  );
}

/* ───────── Rating Form ───────── */
function RatingForm({ doctorId, doctorName, onSubmitted }: { doctorId: number; doctorName: string; onSubmitted: () => void }) {
  const [stars, setStars] = useState(0);
  const [hovered, setHovered] = useState(0);
  const [review, setReview] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (stars === 0) { toast.error("Please select a star rating."); return; }
    if (!localStorage.getItem("auth_token")) { toast.error("Please login to submit a rating."); return; }
    setSubmitting(true);
    try {
      await api.post("/ratings", { rateable_type: "doctor", rateable_id: doctorId, rating: stars, review });
      toast.success(`Thank you for rating ${doctorName}!`);
      onSubmitted();
    } catch { toast.error("Failed to submit rating. Please try again."); }
    finally { setSubmitting(false); }
  };

  return (
    <div className="bg-gray-50 rounded-2xl p-4 border border-gray-100">
      <h3 className="font-bold text-gray-900 mb-3 text-sm">Rate {doctorName}</h3>
      <div className="flex items-center gap-1 mb-3">
        {[1,2,3,4,5].map((i) => (
          <button key={i} onMouseEnter={()=>setHovered(i)} onMouseLeave={()=>setHovered(0)} onClick={()=>setStars(i)}>
            <Star className={`w-7 h-7 transition-colors ${i<=(hovered||stars)?"text-amber-400 fill-amber-400":"text-gray-200"}`} />
          </button>
        ))}
        {stars > 0 && <span className="text-xs text-gray-500 ml-1">{["","Poor","Fair","Good","Very Good","Excellent"][stars]}</span>}
      </div>
      <textarea value={review} onChange={e=>setReview(e.target.value)} placeholder="Share your experience (optional)…" rows={2}
        className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm bg-white outline-none focus:border-brand-400 resize-none mb-3" />
      <button onClick={handleSubmit} disabled={submitting||stars===0}
        className="w-full py-2.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2">
        {submitting ? <><Loader2 className="w-4 h-4 animate-spin"/>Submitting…</> : "Submit Rating"}
      </button>
    </div>
  );
}

/* ───────── Main Page ───────── */
export default function DoctorProfilePage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();

  const [doctor, setDoctor] = useState<Doctor | null>(null);
  const [ratings, setRatings] = useState<Rating[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [showRatingForm, setShowRatingForm] = useState(false);
  const [favorited, setFavorited] = useState(false);
  const [favLoading, setFavLoading] = useState(false);
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [showBookingModal, setShowBookingModal] = useState(false);

  const fetchDoctor = async () => {
    try {
      const res = await api.get("/doctors/approved");
      const list: Doctor[] = Array.isArray(res.data?.data) ? res.data.data : [];
      const found = list.find((d) => d.id === Number(id));
      if (!found) { setError(true); return; }
      setDoctor(found);
    } catch { setError(true); }
    finally { setLoading(false); }
  };

  const fetchRatings = async () => {
    try {
      const res = await api.get(`/ratings/doctor/${id}`);
      setRatings(Array.isArray(res.data?.data) ? res.data.data : []);
    } catch { /* optional */ }
  };

  useEffect(() => { fetchDoctor(); fetchRatings(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [id]);

  const handleToggleFavorite = async () => {
    if (!localStorage.getItem("auth_token")) { toast.error("Please login to save favorites."); return; }
    setFavLoading(true);
    try {
      await api.post("/doctor-favorites/toggle", { doctor_id: Number(id) });
      setFavorited((p) => !p);
      toast.success(favorited ? "Removed from favorites" : "Added to favorites");
    } catch { toast.error("Failed to update favorites."); }
    finally { setFavLoading(false); }
  };

  if (loading) return (
    <main className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-b from-brand-500 to-brand-600 h-72 animate-pulse" />
      <div className="max-w-2xl mx-auto px-4 mt-6 space-y-4">
        {[1,2,3,4].map(i=><div key={i} className="bg-white rounded-2xl p-5 shadow-card animate-pulse h-24"/>)}
      </div>
    </main>
  );

  if (error || !doctor) return (
    <main className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center px-4">
        <AlertCircle className="w-12 h-12 text-gray-300 mx-auto mb-3" />
        <p className="font-semibold text-gray-600 mb-4">Doctor not found</p>
        <Link href="/doctors" className="btn-primary text-sm">← Back to Doctors</Link>
      </div>
    </main>
  );

  const imageUrl = getImageUrl(doctor.profile_image);
  const specialty = doctor.specialties?.length ? doctor.specialties.join(", ") : "General Practice";
  const rating = doctor.rating ?? 0;

  return (
    <main className="min-h-screen bg-gray-50 pb-32">
      {/* ── Hero Header ── */}
      <div className="relative bg-gradient-to-b from-brand-600 to-brand-500 pt-14 pb-10 px-4 text-center">
        <button onClick={() => router.back()}
          className="absolute top-4 left-4 w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors">
          <ArrowLeft className="w-5 h-5 text-white" />
        </button>
        <button onClick={handleToggleFavorite} disabled={favLoading}
          className="absolute top-4 right-4 w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors">
          <Heart className={`w-5 h-5 ${favorited ? "text-red-400 fill-red-400" : "text-white"}`} />
        </button>

        {imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={imageUrl} alt={doctor.name}
            className="w-28 h-28 rounded-full object-cover border-4 border-white shadow-lg mx-auto mb-4" />
        ) : (
          <div className="w-28 h-28 rounded-full bg-white/20 border-4 border-white shadow-lg mx-auto mb-4 flex items-center justify-center">
            <span className="text-white font-bold text-3xl">{getInitials(doctor.name)}</span>
          </div>
        )}
        <h1 className="text-2xl font-bold text-white mb-1">{doctor.name}</h1>
        <p className="text-brand-100 text-sm mb-3">{specialty}</p>

        {rating > 0 && (
          <div className="inline-flex items-center gap-1.5 bg-white/20 rounded-full px-3 py-1">
            <Star className="w-4 h-4 text-amber-300 fill-amber-300" />
            <span className="text-white font-semibold text-sm">{rating.toFixed(1)}/5</span>
            {rating >= 4.5 && <span className="text-xs bg-green-400 text-white px-2 py-0.5 rounded-full font-bold ml-1">Top Rated</span>}
          </div>
        )}
      </div>

      <div className="max-w-2xl mx-auto px-4 mt-4 space-y-4">

        {/* ── Intro card: location, rating, actions ── */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <div className="flex flex-col gap-3">
            {doctor.location && (
              <div className="flex items-center gap-2">
                <MapPin className="w-4 h-4 text-brand-500 flex-shrink-0" />
                <span className="text-sm text-gray-700">{doctor.location}</span>
              </div>
            )}
            {rating > 0 && (
              <div className="flex items-center gap-2">
                <Star className="w-4 h-4 text-amber-400 flex-shrink-0" />
                <StarRating value={rating} />
                <span className="text-sm text-gray-600">{rating.toFixed(1)} / 5</span>
              </div>
            )}
          </div>
          {/* Action buttons row */}
          <div className="flex items-center gap-2 mt-4 pt-4 border-t border-gray-50">
            {doctor.telephone && (
              <a href={`tel:${doctor.telephone}`}
                className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-brand-200 text-brand-600 text-sm font-semibold hover:bg-brand-50 transition-colors">
                <Phone className="w-4 h-4" /> Contact
              </a>
            )}
            <Link href={`/chat?doctor=${doctor.id}`}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-brand-200 text-brand-600 text-sm font-semibold hover:bg-brand-50 transition-colors">
              <MessageCircle className="w-4 h-4" /> Chat
            </Link>
            <div className="flex-1" />
            <button onClick={handleToggleFavorite} disabled={favLoading}
              className={`p-2 rounded-xl transition-colors ${favorited ? "bg-red-50 text-red-500" : "bg-gray-50 text-gray-400 hover:text-red-400"}`}>
              <Heart className={`w-5 h-5 ${favorited ? "fill-red-500" : ""}`} />
            </button>
          </div>
        </div>

        {/* ── Clinic Card ── */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-brand-50 flex items-center justify-center flex-shrink-0">
              <Building2 className="w-7 h-7 text-brand-500" />
            </div>
            <div>
              <p className="font-bold text-gray-900 text-sm">{doctor.location ?? "Nairobi Hospital"}</p>
              <div className="flex items-center gap-1 mt-1">
                <MapPin className="w-3 h-3 text-brand-400" />
                <span className="text-xs text-gray-500">Nairobi, Kenya</span>
              </div>
              <div className="flex items-center gap-3 mt-1">
                <div className="flex items-center gap-1">
                  <Calendar className="w-3 h-3 text-brand-400" />
                  <span className="text-xs text-gray-500">Mon–Sun</span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock className="w-3 h-3 text-brand-400" />
                  <span className="text-xs text-gray-500">8:00 AM – 6:00 PM</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── Profile/Bio ── */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
            <User className="w-4 h-4 text-brand-500" /> Profile
          </h2>
          <p className="text-sm text-gray-600 leading-relaxed">
            {doctor.bio ??
              `${doctor.name} is an experienced medical professional specializing in ${specialty}. Committed to providing quality, patient-centred healthcare.`}
          </p>
        </div>

        {/* ── Specialties ── */}
        {doctor.specialties && doctor.specialties.length > 0 && (
          <div className="bg-white rounded-2xl shadow-card p-5">
            <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
              <Stethoscope className="w-4 h-4 text-brand-500" /> Specialties
            </h2>
            <div className="flex flex-wrap gap-2">
              {doctor.specialties.map((s) => (
                <span key={s} className="px-3 py-1.5 rounded-full text-xs font-semibold text-brand-600 bg-brand-50 border border-brand-100">{s}</span>
              ))}
            </div>
          </div>
        )}

        {/* ── Available Times ── */}
        {doctor.availability && doctor.availability.length > 0 && (
          <div className="bg-white rounded-2xl shadow-card p-5">
            <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
              <Clock className="w-4 h-4 text-brand-500" /> Available Times
            </h2>
            <div className="flex flex-wrap gap-2">
              {doctor.availability.map((t) => (
                <span key={t} className="px-3 py-1.5 rounded-full text-xs font-semibold text-green-700 bg-green-50 border border-green-200">{t}</span>
              ))}
            </div>
          </div>
        )}

        {/* ── Contact ── */}
        {doctor.telephone && (
          <div className="bg-white rounded-2xl shadow-card p-5">
            <h2 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
              <Phone className="w-4 h-4 text-brand-500" /> Contact Information
            </h2>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2.5 bg-green-50 rounded-xl"><Phone className="w-4 h-4 text-green-600" /></div>
                <span className="text-sm font-semibold text-gray-800">{doctor.telephone}</span>
              </div>
              <a href={`tel:${doctor.telephone}`}
                className="px-4 py-2 rounded-xl bg-green-500 hover:bg-green-600 text-white text-xs font-bold transition-colors">
                Call Now
              </a>
            </div>
          </div>
        )}

        {/* ── Book an Appointment (Calendar) ── */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <h2 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            <Calendar className="w-4 h-4 text-brand-500" /> Book an Appointment
          </h2>
          <MiniCalendar selected={selectedDate} onSelect={(d) => { setSelectedDate(d); setShowBookingModal(true); }} />
          <p className="text-xs text-gray-400 text-center mt-3">Tap a date to book your appointment</p>
        </div>

        {/* ── Patient Ratings ── */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold text-gray-900 flex items-center gap-2">
              <Star className="w-4 h-4 text-amber-400 fill-amber-400" /> Patient Ratings
              {ratings.length > 0 && <span className="text-xs text-gray-400 font-normal">({ratings.length})</span>}
            </h2>
            <button onClick={() => setShowRatingForm(p=>!p)}
              className="text-xs font-semibold text-brand-500 hover:text-brand-600 transition-colors">
              {showRatingForm ? "Cancel" : "+ Rate Doctor"}
            </button>
          </div>

          {showRatingForm && (
            <div className="mb-4">
              <RatingForm doctorId={doctor.id} doctorName={doctor.name}
                onSubmitted={() => { setShowRatingForm(false); fetchRatings(); }} />
            </div>
          )}

          {ratings.length === 0 ? (
            <div className="text-center py-8">
              <Star className="w-10 h-10 text-gray-200 mx-auto mb-2" />
              <p className="text-sm text-gray-400">No ratings yet — be the first!</p>
            </div>
          ) : (
            <div className="space-y-4">
              {ratings.map((r) => (
                <div key={r.id} className="border-b border-gray-50 pb-4 last:border-0 last:pb-0">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-semibold text-gray-800">{r.user_name ?? "Anonymous"}</span>
                    <StarRating value={r.rating} size="sm" />
                  </div>
                  {r.review && <p className="text-xs text-gray-500 leading-relaxed">{r.review}</p>}
                  {r.created_at && <p className="text-xs text-gray-300 mt-1">{new Date(r.created_at).toLocaleDateString()}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Sticky bottom bar ── */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 shadow-lg px-4 py-3 z-30">
        <div className="max-w-2xl mx-auto flex gap-3">
          {doctor.telephone && (
            <a href={`tel:${doctor.telephone}`}
              className="flex items-center justify-center gap-1.5 px-4 py-3 rounded-xl border border-brand-200 text-brand-600 text-sm font-semibold hover:bg-brand-50 transition-colors">
              <Phone className="w-4 h-4" /> Call
            </a>
          )}
          <button onClick={() => { setShowRatingForm(p=>!p); document.querySelector("#ratings-section")?.scrollIntoView({behavior:"smooth"}); }}
            className="flex items-center justify-center gap-1.5 px-4 py-3 rounded-xl border border-amber-200 text-amber-600 text-sm font-semibold hover:bg-amber-50 transition-colors">
            <Star className="w-4 h-4" /> Rate
          </button>
          <button onClick={() => setShowBookingModal(true)}
            className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-sm font-bold transition-colors">
            <Calendar className="w-4 h-4" /> Book Appointment
          </button>
        </div>
      </div>

      {/* ── Booking Modal ── */}
      {showBookingModal && (
        <AppointmentModal doctor={doctor} selectedDate={selectedDate} onClose={() => setShowBookingModal(false)} />
      )}
    </main>
  );
}
