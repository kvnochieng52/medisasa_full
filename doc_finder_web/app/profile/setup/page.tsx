"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  User, Mail, Phone, CreditCard, MapPin, Calendar,
  Upload, CheckCircle, Stethoscope, FileText, X,
  ChevronRight, ChevronLeft, Loader2, Heart, Plus, LayoutDashboard,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import Navbar from "@/components/Navbar";

interface Specialization {
  id: number;
  specialization_name: string;
  specialization_description?: string;
}

interface UploadedDocument {
  id: number;
  document_type: string;
  document_path: string;
}

interface UserSpecialization {
  id: number;
  specialization_id: number;
}

interface ProfileUser {
  id: number;
  name: string;
  email: string;
  telephone?: string;
  address?: string;
  dob?: string;
  id_number?: string;
  profile_image?: string;
  account_type?: number | string | null;
  licence_number?: string;
  professional_bio?: string;
}

interface ProfileResponse extends Partial<ProfileUser> {
  user?: ProfileUser;
  specializations?: Specialization[];
  user_specializations?: UserSpecialization[];
  user_documents?: UploadedDocument[];
  user_ids?: UploadedDocument[];
}

interface BasicDetails {
  name: string;
  email: string;
  dateOfBirth: string;
  telephone: string;
  idNumber: string;
  address: string;
  userType: "user" | "serviceProvider";
  profileImageFile: File | null;
  profileImagePreview: string;
}

interface SPDetails {
  licenceNumber: string;
  professionalBio: string;
  selectedSpecializations: number[];
  newCertFiles: File[];
  newIdFiles: File[];
  existingDocs: UploadedDocument[];
  existingIds: UploadedDocument[];
}

export default function ProfileSetupPage() {
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [pageLoading, setPageLoading] = useState(true);
  const [specializations, setSpecializations] = useState<Specialization[]>([]);
  const [showSpecModal, setShowSpecModal] = useState(false);

  const imageInputRef = useRef<HTMLInputElement>(null);
  const certInputRef = useRef<HTMLInputElement>(null);
  const idInputRef = useRef<HTMLInputElement>(null);

  const [basic, setBasic] = useState<BasicDetails>({
    name: "",
    email: "",
    dateOfBirth: "",
    telephone: "",
    idNumber: "",
    address: "",
    userType: "user",
    profileImageFile: null,
    profileImagePreview: "",
  });

  const [sp, setSP] = useState<SPDetails>({
    licenceNumber: "",
    professionalBio: "",
    selectedSpecializations: [],
    newCertFiles: [],
    newIdFiles: [],
    existingDocs: [],
    existingIds: [],
  });

  const totalSteps = basic.userType === "serviceProvider" ? 3 : 2;

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (!token) { router.replace("/login"); return; }

    const raw = localStorage.getItem("user_data");
    if (raw) {
      try {
        const u = JSON.parse(raw);
        setBasic(prev => ({ ...prev, name: u.name || "", email: u.email || "" }));
      } catch { /* ignore */ }
    }

    api.get<{ success: boolean; data: ProfileResponse }>("/user-profile")
      .then(res => {
        // API returns { success, data: { user, specializations, ... } }
        const data = res.data.data ?? (res.data as unknown as ProfileResponse);
        const u = data.user ?? (data as unknown as ProfileResponse["user"]);
        const specs = data.specializations ?? [];
        const user_specializations = data.user_specializations ?? [];
        const user_documents = data.user_documents ?? [];
        const user_ids = data.user_ids ?? [];

        if (!u) return;

        setBasic(prev => ({
          ...prev,
          name: u.name || prev.name,
          email: u.email || prev.email,
          telephone: u.telephone || "",
          idNumber: u.id_number || "",
          address: u.address || "",
          dateOfBirth: u.dob ? u.dob.substring(0, 10) : "",
          userType: (u.account_type === 2 || u.account_type === "serviceProvider") ? "serviceProvider" : "user",
          profileImagePreview: u.profile_image ? getImageUrl(u.profile_image) : "",
        }));
        setSP(prev => ({
          ...prev,
          licenceNumber: u.licence_number || "",
          professionalBio: u.professional_bio || "",
          selectedSpecializations: user_specializations.map(s => s.specialization_id),
          existingDocs: user_documents,
          existingIds: user_ids,
        }));
        setSpecializations(specs);
      })
      .catch(() => {
        toast.error("Could not load profile data. You can still fill in your details.");
      })
      .finally(() => setPageLoading(false));
  }, [router]);

  const handleStep1 = async () => {
    if (!basic.name.trim()) { toast.error("Full name is required"); return; }
    if (!basic.dateOfBirth) { toast.error("Date of birth is required"); return; }
    if (!basic.telephone.trim()) { toast.error("Phone number is required"); return; }
    if (!basic.idNumber.trim()) { toast.error("ID number is required"); return; }
    if (!basic.address.trim()) { toast.error("Address is required"); return; }

    setLoading(true);
    try {
      await api.post("/save-basic-details", {
        name: basic.name.trim(),
        email: basic.email,
        telephone: basic.telephone.trim(),
        idNumber: basic.idNumber.trim(),
        address: basic.address.trim(),
        dateOfBirth: basic.dateOfBirth,
        userType: basic.userType,
      });

      if (basic.profileImageFile) {
        const raw = localStorage.getItem("user_data");
        const userId = raw ? JSON.parse(raw).id : "";
        const fd = new FormData();
        fd.append("user_id", String(userId));
        fd.append("profile_image", basic.profileImageFile);
        await api.post("/upload-profile-image", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      const raw = localStorage.getItem("user_data");
      if (raw) {
        try {
          const u = JSON.parse(raw);
          u.account_type = basic.userType;
          u.name = basic.name;
          localStorage.setItem("user_data", JSON.stringify(u));
        } catch { /* ignore */ }
      }

      toast.success("Basic details saved!");
      setStep(basic.userType === "serviceProvider" ? 2 : totalSteps);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      toast.error(e?.response?.data?.message ?? "Failed to save details");
    } finally {
      setLoading(false);
    }
  };

  const handleStep2 = async () => {
    if (!sp.licenceNumber.trim()) { toast.error("License number is required"); return; }
    if (!sp.professionalBio.trim()) { toast.error("Professional bio is required"); return; }
    if (sp.selectedSpecializations.length === 0) { toast.error("Select at least one specialization"); return; }

    setLoading(true);
    try {
      const raw = localStorage.getItem("user_data");
      const userId = raw ? JSON.parse(raw).id : "";

      for (const file of sp.newCertFiles) {
        const fd = new FormData();
        fd.append("user_id", String(userId));
        fd.append("document_type", "certificate");
        fd.append("document", file);
        await api.post("/upload-user-document", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      for (const file of sp.newIdFiles) {
        const fd = new FormData();
        fd.append("user_id", String(userId));
        fd.append("document_type", "id");
        fd.append("document", file);
        await api.post("/upload-user-document", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      await api.post("/save-service-provider-details", {
        licence_number: sp.licenceNumber.trim(),
        professional_bio: sp.professionalBio.trim(),
        specializations: sp.selectedSpecializations,
        account_type: 2,
      });

      toast.success("Professional details saved!");
      setStep(3);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      toast.error(e?.response?.data?.message ?? "Failed to save details");
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteDoc = async (docId: number, type: "cert" | "id") => {
    try {
      await api.delete(`/user-document/${docId}`);
      if (type === "cert") {
        setSP(prev => ({ ...prev, existingDocs: prev.existingDocs.filter(d => d.id !== docId) }));
      } else {
        setSP(prev => ({ ...prev, existingIds: prev.existingIds.filter(d => d.id !== docId) }));
      }
      toast.success("Document removed");
    } catch {
      toast.error("Failed to remove document");
    }
  };

  if (pageLoading) {
    return (
      <main className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center min-h-screen">
          <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
        </div>
      </main>
    );
  }

  const stepLabels = basic.userType === "serviceProvider"
    ? ["Basic Details", "Professional Info", "Complete"]
    : ["Basic Details", "Complete"];

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white">
      <Navbar />
      <div className="max-w-2xl mx-auto px-4 pt-28 pb-16">
        {/* Back to Dashboard */}
        <div className="mb-6">
          <Link href="/dashboard"
            className="inline-flex items-center gap-2 text-sm font-medium text-gray-600 hover:text-brand-500 transition-colors">
            <LayoutDashboard className="w-4 h-4" />
            Back to Dashboard
          </Link>
        </div>

        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-brand-500 flex items-center justify-center shadow-md mx-auto mb-4">
            <Heart className="w-8 h-8 text-white" fill="white" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Complete Your Profile</h1>
          <p className="text-gray-500 text-sm mt-1">Help us personalise your experience</p>
        </div>

        {/* Step Indicator */}
        <div className="flex items-center justify-center gap-2 mb-8 flex-wrap">
          {stepLabels.map((label, idx) => {
            const stepNum = idx + 1;
            const isActive = step === stepNum;
            const isDone = step > stepNum;
            return (
              <div key={stepNum} className="flex items-center gap-2">
                <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  isActive ? "bg-brand-500 text-white shadow" :
                  isDone ? "bg-green-500 text-white" :
                  "bg-gray-200 text-gray-500"
                }`}>
                  {isDone ? <CheckCircle className="w-3.5 h-3.5" /> : <span>{stepNum}</span>}
                  <span>{label}</span>
                </div>
                {idx < stepLabels.length - 1 && (
                  <div className={`w-8 h-0.5 ${step > stepNum ? "bg-green-400" : "bg-gray-200"}`} />
                )}
              </div>
            );
          })}
        </div>

        <div className="bg-white rounded-3xl shadow-xl p-8">

          {/* ─── STEP 1: BASIC DETAILS ─── */}
          {step === 1 && (
            <div className="space-y-5">
              <h2 className="text-lg font-bold text-gray-800">Basic Information</h2>

              {/* Profile Picture */}
              <div className="flex flex-col items-center gap-2">
                <div
                  onClick={() => imageInputRef.current?.click()}
                  className="w-24 h-24 rounded-full bg-gray-100 border-2 border-dashed border-gray-300 flex items-center justify-center cursor-pointer hover:border-brand-400 overflow-hidden transition-colors"
                >
                  {basic.profileImagePreview ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={basic.profileImagePreview} alt="Profile" className="w-full h-full object-cover" />
                  ) : (
                    <div className="text-center">
                      <Upload className="w-6 h-6 text-gray-400 mx-auto mb-1" />
                      <span className="text-xs text-gray-400">Photo</span>
                    </div>
                  )}
                </div>
                <button
                  type="button"
                  onClick={() => imageInputRef.current?.click()}
                  className="text-xs text-brand-500 font-semibold hover:text-brand-600"
                >
                  {basic.profileImagePreview ? "Change Photo" : "Upload Profile Photo"}
                </button>
                <input
                  ref={imageInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={e => {
                    const file = e.target.files?.[0];
                    if (file) {
                      setBasic(prev => ({
                        ...prev,
                        profileImageFile: file,
                        profileImagePreview: URL.createObjectURL(file),
                      }));
                    }
                  }}
                />
              </div>

              <InputField icon={<User className="w-4 h-4" />} label="Full Name" value={basic.name}
                onChange={v => setBasic(p => ({ ...p, name: v }))} placeholder="John Doe" />

              <InputField icon={<Mail className="w-4 h-4" />} label="Email Address" value={basic.email}
                onChange={() => {}} placeholder="" disabled />

              <InputField icon={<Calendar className="w-4 h-4" />} label="Date of Birth" value={basic.dateOfBirth}
                onChange={v => setBasic(p => ({ ...p, dateOfBirth: v }))} type="date" />

              <InputField icon={<Phone className="w-4 h-4" />} label="Phone Number" value={basic.telephone}
                onChange={v => setBasic(p => ({ ...p, telephone: v }))} placeholder="+254 700 000 000" type="tel" />

              <InputField icon={<CreditCard className="w-4 h-4" />} label="ID / Passport Number" value={basic.idNumber}
                onChange={v => setBasic(p => ({ ...p, idNumber: v }))} placeholder="12345678" />

              <InputField icon={<MapPin className="w-4 h-4" />} label="Address" value={basic.address}
                onChange={v => setBasic(p => ({ ...p, address: v }))} placeholder="123 Main St, Nairobi" />

              {/* User Type */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-3">I am a...</label>
                <div className="grid grid-cols-2 gap-3">
                  {([
                    { value: "user", label: "Patient / User", desc: "Looking for healthcare services", icon: <User className="w-5 h-5" /> },
                    { value: "serviceProvider", label: "Service Provider", desc: "Doctor or healthcare professional", icon: <Stethoscope className="w-5 h-5" /> },
                  ] as const).map(opt => (
                    <button
                      key={opt.value}
                      type="button"
                      onClick={() => setBasic(p => ({ ...p, userType: opt.value }))}
                      className={`flex flex-col items-start gap-2 p-4 rounded-xl border-2 text-left transition-all ${
                        basic.userType === opt.value
                          ? "border-brand-500 bg-brand-50"
                          : "border-gray-200 hover:border-gray-300"
                      }`}
                    >
                      <div className={basic.userType === opt.value ? "text-brand-500" : "text-gray-400"}>
                        {opt.icon}
                      </div>
                      <div>
                        <p className={`text-sm font-semibold ${basic.userType === opt.value ? "text-brand-600" : "text-gray-700"}`}>
                          {opt.label}
                        </p>
                        <p className="text-xs text-gray-400 mt-0.5">{opt.desc}</p>
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              <button
                type="button"
                onClick={handleStep1}
                disabled={loading}
                className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm mt-2"
              >
                {loading
                  ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving...</>
                  : <>Save & Continue <ChevronRight className="w-4 h-4" /></>}
              </button>
            </div>
          )}

          {/* ─── STEP 2: SERVICE PROVIDER DETAILS ─── */}
          {step === 2 && basic.userType === "serviceProvider" && (
            <div className="space-y-5">
              <h2 className="text-lg font-bold text-gray-800">Professional Information</h2>

              <InputField icon={<CreditCard className="w-4 h-4" />} label="License / Registration Number"
                value={sp.licenceNumber} onChange={v => setSP(p => ({ ...p, licenceNumber: v }))}
                placeholder="e.g. KMC/12345" />

              {/* Bio */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Professional Bio</label>
                <textarea
                  value={sp.professionalBio}
                  onChange={e => setSP(p => ({ ...p, professionalBio: e.target.value }))}
                  rows={4}
                  placeholder="Describe your experience, expertise, and approach to patient care..."
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm outline-none transition-all focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 resize-none"
                />
              </div>

              {/* Specializations */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Specializations</label>
                <button
                  type="button"
                  onClick={() => setShowSpecModal(true)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 text-sm text-left flex items-center justify-between hover:border-brand-400 transition-colors"
                >
                  <span className={sp.selectedSpecializations.length > 0 ? "text-gray-700" : "text-gray-400"}>
                    {sp.selectedSpecializations.length > 0
                      ? `${sp.selectedSpecializations.length} specialization${sp.selectedSpecializations.length > 1 ? "s" : ""} selected`
                      : "Select specializations"}
                  </span>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </button>
                {sp.selectedSpecializations.length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-2">
                    {sp.selectedSpecializations.map(id => {
                      const s = specializations.find(x => x.id === id);
                      return s ? (
                        <span key={id} className="inline-flex items-center gap-1 px-2.5 py-1 bg-brand-50 text-brand-600 text-xs rounded-full font-medium">
                          {s.specialization_name}
                          <button
                            type="button"
                            onClick={() => setSP(p => ({ ...p, selectedSpecializations: p.selectedSpecializations.filter(i => i !== id) }))}
                          >
                            <X className="w-3 h-3" />
                          </button>
                        </span>
                      ) : null;
                    })}
                  </div>
                )}
              </div>

              {/* Professional Certificates */}
              <DocumentUploadSection
                label="Professional Certificates"
                icon={<FileText className="w-4 h-4 text-brand-500" />}
                existingDocs={sp.existingDocs}
                newFiles={sp.newCertFiles}
                inputRef={certInputRef}
                onDelete={id => handleDeleteDoc(id, "cert")}
                onAddFiles={files => setSP(p => ({ ...p, newCertFiles: [...p.newCertFiles, ...files] }))}
                onRemoveNew={i => setSP(p => ({ ...p, newCertFiles: p.newCertFiles.filter((_, j) => j !== i) }))}
                addLabel="Add Certificate"
              />

              {/* ID Documents */}
              <DocumentUploadSection
                label="ID Documents"
                icon={<CreditCard className="w-4 h-4 text-brand-500" />}
                existingDocs={sp.existingIds}
                newFiles={sp.newIdFiles}
                inputRef={idInputRef}
                onDelete={id => handleDeleteDoc(id, "id")}
                onAddFiles={files => setSP(p => ({ ...p, newIdFiles: [...p.newIdFiles, ...files] }))}
                onRemoveNew={i => setSP(p => ({ ...p, newIdFiles: p.newIdFiles.filter((_, j) => j !== i) }))}
                addLabel="Add ID Document"
              />

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="flex-1 py-3.5 rounded-xl border border-gray-200 text-gray-700 font-semibold text-sm hover:bg-gray-50 transition-colors flex items-center justify-center gap-2"
                >
                  <ChevronLeft className="w-4 h-4" /> Back
                </button>
                <button
                  type="button"
                  onClick={handleStep2}
                  disabled={loading}
                  className="flex-1 py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm"
                >
                  {loading
                    ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving...</>
                    : <>Save & Continue <ChevronRight className="w-4 h-4" /></>}
                </button>
              </div>
            </div>
          )}

          {/* ─── CONFIRMATION STEP ─── */}
          {step === totalSteps && (
            <div className="text-center space-y-6">
              <div className="w-20 h-20 rounded-full bg-green-50 flex items-center justify-center mx-auto">
                <CheckCircle className="w-10 h-10 text-green-500" />
              </div>

              <div>
                <h2 className="text-xl font-bold text-gray-900">
                  {basic.userType === "serviceProvider" ? "Profile Submitted!" : "Profile Complete!"}
                </h2>
                <p className="text-gray-500 text-sm mt-2">
                  {basic.userType === "serviceProvider"
                    ? "Your profile has been submitted for review. You'll be notified once approved."
                    : "Your profile has been saved successfully."}
                </p>
              </div>

              <div className="bg-gray-50 rounded-2xl p-5 text-left space-y-3">
                <SummaryRow label="Name" value={basic.name} />
                <SummaryRow label="Email" value={basic.email} />
                <SummaryRow
                  label="Account Type"
                  value={basic.userType === "serviceProvider" ? "Service Provider / Doctor" : "Patient / User"}
                />
                {basic.userType === "serviceProvider" && (
                  <>
                    <SummaryRow label="License" value={sp.licenceNumber} />
                    <SummaryRow label="Specializations" value={`${sp.selectedSpecializations.length} selected`} />
                  </>
                )}
              </div>

              {basic.userType === "serviceProvider" && (
                <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 text-left">
                  <p className="text-sm font-semibold text-orange-700">Pending Verification</p>
                  <p className="text-xs text-orange-600 mt-1">
                    Our team will review your credentials and activate your profile within 2–3 business days.
                  </p>
                </div>
              )}

              <button
                type="button"
                onClick={() => router.push("/dashboard")}
                className="w-full py-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                Go to Dashboard <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* ─── SPECIALIZATIONS MODAL ─── */}
      {showSpecModal && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-md max-h-[80vh] flex flex-col shadow-2xl">
            <div className="flex items-center justify-between p-5 border-b">
              <h3 className="font-bold text-gray-800">Select Specializations</h3>
              <button type="button" onClick={() => setShowSpecModal(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 p-4 space-y-2">
              {specializations.length === 0 && (
                <p className="text-sm text-gray-400 text-center py-8">No specializations available</p>
              )}
              {specializations.map(s => {
                const selected = sp.selectedSpecializations.includes(s.id);
                return (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => setSP(p => ({
                      ...p,
                      selectedSpecializations: selected
                        ? p.selectedSpecializations.filter(i => i !== s.id)
                        : [...p.selectedSpecializations, s.id],
                    }))}
                    className={`w-full flex items-center gap-3 p-3 rounded-xl border text-left transition-all ${
                      selected ? "border-brand-400 bg-brand-50" : "border-gray-200 hover:border-gray-300"
                    }`}
                  >
                    <div className={`w-5 h-5 rounded flex items-center justify-center border-2 flex-shrink-0 ${
                      selected ? "border-brand-500 bg-brand-500" : "border-gray-300"
                    }`}>
                      {selected && <CheckCircle className="w-3 h-3 text-white" />}
                    </div>
                    <div>
                      <p className={`text-sm font-medium ${selected ? "text-brand-700" : "text-gray-700"}`}>{s.specialization_name}</p>
                      {s.specialization_description && <p className="text-xs text-gray-400">{s.specialization_description}</p>}
                    </div>
                  </button>
                );
              })}
            </div>
            <div className="p-4 border-t flex gap-3">
              <button
                type="button"
                onClick={() => setSP(p => ({ ...p, selectedSpecializations: [] }))}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm text-gray-600 font-semibold hover:bg-gray-50"
              >
                Clear All
              </button>
              <button
                type="button"
                onClick={() => setShowSpecModal(false)}
                className="flex-1 py-2.5 rounded-xl bg-brand-500 text-white text-sm font-semibold hover:bg-brand-600"
              >
                Done ({sp.selectedSpecializations.length})
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

/* ─── Helper Components ─── */

function InputField({
  icon, label, value, onChange, placeholder, type = "text", disabled = false,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  disabled?: boolean;
}) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">{label}</label>
      <div className="relative">
        <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400">{icon}</div>
        <input
          type={type}
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder={placeholder}
          disabled={disabled}
          className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-gray-50 text-sm outline-none transition-all focus:bg-white focus:border-brand-400 focus:ring-2 focus:ring-brand-100 ${
            disabled ? "text-gray-400 cursor-not-allowed" : "border-gray-200"
          }`}
        />
      </div>
    </div>
  );
}

function DocumentUploadSection({
  label, icon, existingDocs, newFiles, inputRef, onDelete, onAddFiles, onRemoveNew, addLabel,
}: {
  label: string;
  icon: React.ReactNode;
  existingDocs: UploadedDocument[];
  newFiles: File[];
  inputRef: React.RefObject<HTMLInputElement>;
  onDelete: (id: number) => void;
  onAddFiles: (files: File[]) => void;
  onRemoveNew: (index: number) => void;
  addLabel: string;
}) {
  return (
    <div>
      <label className="block text-sm font-semibold text-gray-700 mb-1.5">{label}</label>
      <div className="space-y-2">
        {existingDocs.map(doc => (
          <div key={doc.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl border border-gray-200">
            <div className="flex items-center gap-2">
              {icon}
              <span className="text-xs text-gray-600 truncate max-w-[200px]">
                {doc.document_path.split("/").pop()}
              </span>
            </div>
            <button type="button" onClick={() => onDelete(doc.id)} className="text-red-400 hover:text-red-600">
              <X className="w-4 h-4" />
            </button>
          </div>
        ))}
        {newFiles.map((file, i) => (
          <div key={i} className="flex items-center justify-between p-3 bg-green-50 rounded-xl border border-green-200">
            <div className="flex items-center gap-2">
              <FileText className="w-4 h-4 text-green-600" />
              <span className="text-xs text-gray-600 truncate max-w-[200px]">{file.name}</span>
            </div>
            <button type="button" onClick={() => onRemoveNew(i)} className="text-red-400 hover:text-red-600">
              <X className="w-4 h-4" />
            </button>
          </div>
        ))}
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          className="w-full py-2.5 rounded-xl border-2 border-dashed border-gray-300 text-xs text-gray-500 hover:border-brand-400 hover:text-brand-500 transition-colors flex items-center justify-center gap-2"
        >
          <Plus className="w-4 h-4" /> {addLabel}
        </button>
        <input
          ref={inputRef}
          type="file"
          accept="image/*,.pdf"
          className="hidden"
          multiple
          onChange={e => {
            const files = Array.from(e.target.files || []);
            if (files.length) onAddFiles(files);
            e.target.value = "";
          }}
        />
      </div>
    </div>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-sm text-gray-500">{label}</span>
      <span className="text-sm font-semibold text-gray-800">{value}</span>
    </div>
  );
}
