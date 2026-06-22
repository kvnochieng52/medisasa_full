"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  Brain, Plus, Pencil, Trash2, Globe, Lock,
  FileText, Play, Loader2, X, Upload, Image as ImageIcon,
  ChevronDown, ClipboardList, Unlink,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";

interface Survey {
  id: number;
  title: string;
  slug: string;
}

interface Material {
  id: number;
  title: string;
  description?: string;
  image_path?: string;
  file_path?: string;
  file_type?: "pdf" | "video";
  is_free: boolean;
  price?: number | null;
  is_active: boolean;
  survey_id?: number | null;
  survey?: { id: number; title: string; slug: string } | null;
}

const EMPTY_FORM = {
  title: "", description: "", is_free: true, price: "", is_active: true,
  survey_id: "" as string | number,
  image: null as File | null,
  file: null as File | null,
};

export default function AdminMentalHealthPage() {
  const router = useRouter();
  const imgRef = useRef<HTMLInputElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const [materials, setMaterials] = useState<Material[]>([]);
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterSurveyId, setFilterSurveyId] = useState<string>("all");
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState({ ...EMPTY_FORM });
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) { router.replace("/login"); return; }
    load();
    api.get("/admin/surveys").then(res => {
      setSurveys(Array.isArray(res.data?.data) ? res.data.data : []);
    }).catch(() => {});
  }, [router]);

  const load = () => {
    setLoading(true);
    api.get("/mental-health-materials")
      .then(res => setMaterials(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => toast.error("Failed to load materials"))
      .finally(() => setLoading(false));
  };

  const openNew = (preselectedSurveyId?: number) => {
    setEditId(null);
    setForm({ ...EMPTY_FORM, survey_id: preselectedSurveyId ?? "" });
    setShowForm(true);
  };

  const openEdit = (m: Material) => {
    setEditId(m.id);
    setForm({
      title: m.title,
      description: m.description ?? "",
      is_free: m.is_free,
      price: m.price != null ? String(m.price) : "",
      is_active: m.is_active,
      survey_id: m.survey_id ?? "",
      image: null,
      file: null,
    });
    setShowForm(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) { toast.error("Title is required"); return; }
    setSaving(true);

    const fd = new FormData();
    fd.append("title", form.title);
    if (form.description) fd.append("description", form.description);
    fd.append("is_free", form.is_free ? "1" : "0");
    if (!form.is_free && form.price !== "") fd.append("price", String(form.price));
    fd.append("is_active", form.is_active ? "1" : "0");
    if (form.survey_id !== "") fd.append("survey_id", String(form.survey_id));
    if (form.image) fd.append("image", form.image);
    if (form.file)  fd.append("file", form.file);

    try {
      if (editId) {
        fd.append("_method", "PUT");
        await api.post(`/mental-health-materials/${editId}`, fd, { headers: { "Content-Type": "multipart/form-data" } });
        toast.success("Material updated");
      } else {
        await api.post("/mental-health-materials", fd, { headers: { "Content-Type": "multipart/form-data" } });
        toast.success("Material uploaded");
      }
      setShowForm(false);
      load();
    } catch {
      toast.error("Failed to save material");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this material?")) return;
    setDeletingId(id);
    try {
      await api.delete(`/mental-health-materials/${id}`);
      toast.success("Deleted");
      setMaterials(prev => prev.filter(m => m.id !== id));
    } catch {
      toast.error("Failed to delete");
    } finally {
      setDeletingId(null);
    }
  };

  // Group materials by survey
  const filtered = filterSurveyId === "all"
    ? materials
    : filterSurveyId === "none"
      ? materials.filter(m => !m.survey_id)
      : materials.filter(m => String(m.survey_id) === filterSurveyId);

  // Group displayed materials by survey for organised list view
  const grouped: { label: string; surveyId: number | null; items: Material[] }[] = [];
  if (filterSurveyId === "all") {
    const bySurvey: Record<string, Material[]> = {};
    filtered.forEach(m => {
      const key = m.survey_id ? String(m.survey_id) : "__none__";
      if (!bySurvey[key]) bySurvey[key] = [];
      bySurvey[key].push(m);
    });

    // Surveys first
    surveys.forEach(s => {
      if (bySurvey[String(s.id)]?.length) {
        grouped.push({ label: s.title, surveyId: s.id, items: bySurvey[String(s.id)] });
      }
    });
    // General (unlinked)
    if (bySurvey["__none__"]?.length) {
      grouped.push({ label: "General Resources", surveyId: null, items: bySurvey["__none__"] });
    }
  } else {
    const label = filterSurveyId === "none"
      ? "General Resources"
      : surveys.find(s => String(s.id) === filterSurveyId)?.title ?? "Resources";
    grouped.push({ label, surveyId: filterSurveyId === "none" ? null : Number(filterSurveyId), items: filtered });
  }

  const selectedSurveyName = form.survey_id
    ? surveys.find(s => s.id === Number(form.survey_id))?.title
    : null;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="max-w-5xl mx-auto px-4 pt-28 pb-16">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center shadow-sm">
              <Brain className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">Mental Health Resources</h1>
              <p className="text-sm text-gray-400">Upload materials under a questionnaire or as general resources</p>
            </div>
          </div>
          <div className="flex gap-2">
            <Link href="/mental-health" className="px-4 py-2 border border-gray-200 text-sm font-semibold text-gray-600 rounded-xl hover:bg-gray-50 transition-colors">
              Preview
            </Link>
            <button onClick={() => openNew()}
              className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-violet-500 to-purple-600 text-white text-sm font-bold rounded-xl hover:from-violet-600 hover:to-purple-700 transition-all shadow-sm">
              <Plus className="w-4 h-4" /> Upload Resource
            </button>
          </div>
        </div>

        {/* Filter bar */}
        <div className="flex items-center gap-2 mb-6 flex-wrap">
          <button
            onClick={() => setFilterSurveyId("all")}
            className={`px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all ${filterSurveyId === "all" ? "bg-violet-600 text-white border-violet-600" : "border-gray-200 text-gray-500 hover:border-violet-300"}`}>
            All
          </button>
          {surveys.map(s => (
            <button key={s.id}
              onClick={() => setFilterSurveyId(String(s.id))}
              className={`px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all ${filterSurveyId === String(s.id) ? "bg-violet-600 text-white border-violet-600" : "border-gray-200 text-gray-500 hover:border-violet-300"}`}>
              {s.title}
            </button>
          ))}
          <button
            onClick={() => setFilterSurveyId("none")}
            className={`px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all ${filterSurveyId === "none" ? "bg-gray-700 text-white border-gray-700" : "border-gray-200 text-gray-500 hover:border-gray-400"}`}>
            General
          </button>
        </div>

        {/* List */}
        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-purple-500" />
          </div>
        ) : grouped.length === 0 || grouped.every(g => g.items.length === 0) ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-gray-100">
            <Brain className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-1">No materials yet</p>
            <p className="text-sm text-gray-400 mb-5">Upload your first mental health resource to get started.</p>
            <button onClick={() => openNew()}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-violet-500 to-purple-600 text-white text-sm font-bold rounded-xl">
              <Plus className="w-4 h-4" /> Upload Resource
            </button>
          </div>
        ) : (
          <div className="space-y-8">
            {grouped.map(group => (
              <div key={group.label}>
                {/* Group header */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    {group.surveyId
                      ? <ClipboardList className="w-4 h-4 text-violet-500" />
                      : <Unlink className="w-4 h-4 text-gray-400" />}
                    <h2 className="text-sm font-bold text-gray-700">{group.label}</h2>
                    <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">{group.items.length}</span>
                  </div>
                  {group.surveyId && (
                    <button
                      onClick={() => openNew(group.surveyId!)}
                      className="text-xs font-semibold text-violet-600 hover:text-violet-800 flex items-center gap-1 transition-colors">
                      <Plus className="w-3.5 h-3.5" /> Add resource here
                    </button>
                  )}
                </div>

                <div className="space-y-3">
                  {group.items.map(m => {
                    const img  = getImageUrl(m.image_path);
                    const Icon = m.file_type === "video" ? Play : FileText;
                    return (
                      <div key={m.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex items-center gap-4">
                        <div className="w-16 h-16 rounded-xl bg-purple-50 flex-shrink-0 overflow-hidden flex items-center justify-center">
                          {img
                            ? <img src={img} alt={m.title} className="w-full h-full object-cover" />
                            : <Brain className="w-7 h-7 text-purple-300" />}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap mb-0.5">
                            <p className="text-sm font-bold text-gray-900 truncate">{m.title}</p>
                            <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${m.is_free ? "bg-green-100 text-green-700" : "bg-purple-100 text-purple-700"}`}>
                              {m.is_free ? "Free" : m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
                            </span>
                            {!m.is_active && (
                              <span className="text-xs font-bold bg-gray-100 text-gray-500 px-2 py-0.5 rounded-full">Hidden</span>
                            )}
                          </div>
                          {m.description && <p className="text-xs text-gray-400 truncate">{m.description}</p>}
                          {m.file_type && (
                            <p className="text-xs text-purple-500 font-medium flex items-center gap-1 mt-0.5">
                              <Icon className="w-3 h-3" /> {m.file_type === "video" ? "Video" : "PDF"}
                            </p>
                          )}
                        </div>

                        <div className="flex items-center gap-2 flex-shrink-0">
                          <button onClick={() => openEdit(m)}
                            className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-purple-300 hover:text-purple-600 transition-colors">
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button onClick={() => handleDelete(m.id)} disabled={deletingId === m.id}
                            className="p-2 rounded-xl border border-gray-200 text-gray-400 hover:border-red-300 hover:text-red-500 transition-colors">
                            {deletingId === m.id ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Upload / Edit Modal ── */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white z-10">
              <div>
                <h3 className="font-bold text-gray-800">{editId ? "Edit Resource" : "Upload Resource"}</h3>
                {selectedSurveyName && (
                  <p className="text-xs text-violet-600 font-semibold mt-0.5 flex items-center gap-1">
                    <ClipboardList className="w-3 h-3" /> Under: {selectedSurveyName}
                  </p>
                )}
              </div>
              <button onClick={() => setShowForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>

            <form onSubmit={handleSave} className="p-6 space-y-5">

              {/* ── Questionnaire selector (step 1) ── */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">
                  Link to Questionnaire <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <div className="relative">
                  <select
                    value={form.survey_id}
                    onChange={e => setForm(f => ({ ...f, survey_id: e.target.value }))}
                    className="w-full appearance-none px-4 py-2.5 pr-10 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-purple-200 focus:border-purple-400 bg-white text-gray-700">
                    <option value="">— General resource (not linked to a questionnaire) —</option>
                    {surveys.map(s => (
                      <option key={s.id} value={s.id}>{s.title}</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                </div>
                {form.survey_id && (
                  <p className="text-xs text-violet-600 mt-1.5 font-medium">
                    This resource will appear under <strong>{selectedSurveyName}</strong> results and on the questionnaire page.
                  </p>
                )}
              </div>

              {/* Title */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">Title <span className="text-red-500">*</span></label>
                <input type="text" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                  placeholder="e.g. Managing Anxiety — A Beginner's Guide"
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-purple-200 focus:border-purple-400" />
              </div>

              {/* Description */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">Description</label>
                <textarea rows={3} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Brief description of what this resource covers…"
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-purple-200 focus:border-purple-400 resize-none" />
              </div>

              {/* Image */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">Cover Image</label>
                <div onClick={() => imgRef.current?.click()}
                  className="border-2 border-dashed border-gray-200 rounded-xl p-4 text-center cursor-pointer hover:border-purple-300 transition-colors">
                  {form.image
                    ? <p className="text-sm font-semibold text-purple-600">{form.image.name}</p>
                    : <><ImageIcon className="w-6 h-6 text-gray-300 mx-auto mb-1" /><p className="text-xs text-gray-400">Click to upload image (JPG, PNG, WebP)</p></>}
                </div>
                <input ref={imgRef} type="file" accept="image/*" className="hidden"
                  onChange={e => setForm(f => ({ ...f, image: e.target.files?.[0] ?? null }))} />
              </div>

              {/* File */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">Resource File (PDF or Video)</label>
                <div onClick={() => fileRef.current?.click()}
                  className="border-2 border-dashed border-gray-200 rounded-xl p-4 text-center cursor-pointer hover:border-purple-300 transition-colors">
                  {form.file
                    ? <p className="text-sm font-semibold text-purple-600">{form.file.name}</p>
                    : <><Upload className="w-6 h-6 text-gray-300 mx-auto mb-1" /><p className="text-xs text-gray-400">Click to upload PDF or video (max 100MB)</p></>}
                </div>
                <input ref={fileRef} type="file" accept=".pdf,video/*" className="hidden"
                  onChange={e => setForm(f => ({ ...f, file: e.target.files?.[0] ?? null }))} />
              </div>

              {/* Price */}
              {!form.is_free && (
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-1.5">
                    Price (KES) <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-sm font-bold text-gray-400">KES</span>
                    <input type="number" min="0" step="0.01" value={form.price}
                      onChange={e => setForm(f => ({ ...f, price: e.target.value }))}
                      placeholder="0.00"
                      className="w-full pl-14 pr-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-purple-200 focus:border-purple-400" />
                  </div>
                </div>
              )}

              {/* Free / Paid + Visibility */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-2">Access Type</label>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_free: true }))}
                      className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${form.is_free ? "border-green-400 bg-green-50 text-green-700" : "border-gray-200 text-gray-500 hover:border-green-200"}`}>
                      <Globe className="w-3.5 h-3.5" /> Free
                    </button>
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_free: false }))}
                      className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${!form.is_free ? "border-purple-400 bg-purple-50 text-purple-700" : "border-gray-200 text-gray-500 hover:border-purple-200"}`}>
                      <Lock className="w-3.5 h-3.5" /> Paid
                    </button>
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-2">Visibility</label>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_active: true }))}
                      className={`flex-1 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${form.is_active ? "border-blue-400 bg-blue-50 text-blue-700" : "border-gray-200 text-gray-500"}`}>
                      Visible
                    </button>
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_active: false }))}
                      className={`flex-1 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${!form.is_active ? "border-gray-400 bg-gray-50 text-gray-700" : "border-gray-200 text-gray-400"}`}>
                      Hidden
                    </button>
                  </div>
                </div>
              </div>

              <button type="submit" disabled={saving}
                className="w-full py-3.5 bg-gradient-to-r from-violet-500 to-purple-600 hover:from-violet-600 hover:to-purple-700 disabled:opacity-50 text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm">
                {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving…</> : <><Upload className="w-4 h-4" /> {editId ? "Save Changes" : "Upload Resource"}</>}
              </button>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
