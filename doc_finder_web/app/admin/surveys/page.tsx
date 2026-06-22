"use client";

import { useEffect, useState, useCallback } from "react";
import Navbar from "@/components/Navbar";
import Link from "next/link";
import {
  Brain, Plus, Trash2, ChevronDown, ChevronUp,
  Save, Loader2, Edit2, Eye, CheckCircle2, X,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

// ── Types ─────────────────────────────────────────────────────────────────────

interface Material { id: number; title: string; is_free: boolean; price?: number | null }

interface OptionDraft {
  label: string;
  score_value: number | "";
  color: string;
  order_index: number;
}

interface QuestionDraft {
  question_text: string;
  hint: string;
  order_index: number;
  options: OptionDraft[];
}

interface BandDraft {
  label: string;
  min_score: number | "";
  max_score: number | "";
  message: string;
  result_type: "low" | "moderate" | "high";
  show_therapist_cta: boolean;
  order_index: number;
  material_ids: number[];
}

interface SurveyDraft {
  title: string;
  description: string;
  instructions: string;
  slug: string;
  is_active: boolean;
  questions: QuestionDraft[];
  result_bands: BandDraft[];
}

interface SurveyListItem {
  id: number;
  title: string;
  description?: string;
  slug: string;
  is_active: boolean;
  questions_count: number;
  responses_count: number;
}

const EMPTY_OPTION = (): OptionDraft => ({ label: "", score_value: "", color: "green", order_index: 0 });
const EMPTY_QUESTION = (): QuestionDraft => ({
  question_text: "", hint: "", order_index: 0,
  options: [EMPTY_OPTION(), EMPTY_OPTION(), EMPTY_OPTION(), EMPTY_OPTION()],
});
const EMPTY_BAND = (): BandDraft => ({
  label: "", min_score: "", max_score: "", message: "",
  result_type: "low", show_therapist_cta: false, order_index: 0, material_ids: [],
});
const EMPTY_SURVEY = (): SurveyDraft => ({
  title: "", description: "", instructions: "", slug: "", is_active: true,
  questions: [EMPTY_QUESTION()],
  result_bands: [EMPTY_BAND()],
});

// ── Main page ─────────────────────────────────────────────────────────────────

export default function AdminSurveysPage() {
  const [surveys, setSurveys]   = useState<SurveyListItem[]>([]);
  const [loading, setLoading]   = useState(true);
  const [materials, setMaterials] = useState<Material[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId]     = useState<number | null>(null);
  const [form, setForm]         = useState<SurveyDraft>(EMPTY_SURVEY());
  const [saving, setSaving]     = useState(false);
  const [openQIdx, setOpenQIdx] = useState<number | null>(0);
  const [openBIdx, setOpenBIdx] = useState<number | null>(0);

  const loadSurveys = useCallback(() => {
    setLoading(true);
    api.get("/admin/surveys")
      .then(res => setSurveys(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => setSurveys([]))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { loadSurveys(); }, [loadSurveys]);

  useEffect(() => {
    api.get("/mental-health-materials")
      .then(res => setMaterials(Array.isArray(res.data?.data) ? res.data.data : []))
      .catch(() => {});
  }, []);

  const openCreate = () => {
    setEditId(null);
    setForm(EMPTY_SURVEY());
    setOpenQIdx(0);
    setOpenBIdx(0);
    setShowForm(true);
  };

  const openEdit = async (id: number) => {
    try {
      const res = await api.get(`/admin/surveys/${id}`);
      const s = res.data?.data;
      if (!s) return;
      setEditId(id);
      setForm({
        title: s.title, description: s.description ?? "", instructions: s.instructions ?? "",
        slug: s.slug, is_active: s.is_active,
        questions: s.questions.map((q: QuestionDraft & { id: number; options: (OptionDraft & { id: number })[] }) => ({
          question_text: q.question_text, hint: q.hint ?? "", order_index: q.order_index,
          options: q.options.map((o) => ({
            label: o.label, score_value: o.score_value, color: o.color, order_index: o.order_index,
          })),
        })),
        result_bands: s.result_bands.map((b: BandDraft & { id: number; materials: { id: number }[] }) => ({
          label: b.label, min_score: b.min_score, max_score: b.max_score,
          message: b.message, result_type: b.result_type,
          show_therapist_cta: b.show_therapist_cta, order_index: b.order_index,
          material_ids: b.materials?.map((m: { id: number }) => m.id) ?? [],
        })),
      });
      setOpenQIdx(0);
      setOpenBIdx(0);
      setShowForm(true);
    } catch {
      toast.error("Failed to load survey details");
    }
  };

  const deleteSurvey = async (id: number) => {
    if (!confirm("Delete this survey and all its responses?")) return;
    try {
      await api.delete(`/surveys/${id}`);
      toast.success("Survey deleted");
      loadSurveys();
    } catch {
      toast.error("Delete failed");
    }
  };

  const handleSave = async () => {
    if (!form.title.trim()) { toast.error("Title is required"); return; }
    if (!form.questions.length) { toast.error("Add at least one question"); return; }
    if (!form.result_bands.length) { toast.error("Add at least one result band"); return; }

    setSaving(true);
    try {
      const payload = {
        ...form,
        slug: form.slug || form.title.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, ""),
        questions: form.questions.map((q, qi) => ({
          ...q, order_index: qi,
          options: q.options.map((o, oi) => ({ ...o, order_index: oi, score_value: Number(o.score_value) })),
        })),
        result_bands: form.result_bands.map((b, bi) => ({
          ...b, order_index: bi, min_score: Number(b.min_score), max_score: Number(b.max_score),
        })),
      };

      if (editId) {
        await api.put(`/surveys/${editId}`, payload);
        toast.success("Survey updated");
      } else {
        await api.post("/surveys", payload);
        toast.success("Survey created");
      }
      setShowForm(false);
      loadSurveys();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg ?? "Save failed");
    } finally {
      setSaving(false);
    }
  };

  // ── Question helpers ─────────────────────────────────────────────────────────

  const addQuestion = () => {
    setForm(f => ({ ...f, questions: [...f.questions, EMPTY_QUESTION()] }));
    setOpenQIdx(form.questions.length);
  };
  const removeQuestion = (qi: number) => setForm(f => ({ ...f, questions: f.questions.filter((_, i) => i !== qi) }));
  const updateQuestion = (qi: number, patch: Partial<QuestionDraft>) =>
    setForm(f => { const qs = [...f.questions]; qs[qi] = { ...qs[qi], ...patch }; return { ...f, questions: qs }; });
  const updateOption = (qi: number, oi: number, patch: Partial<OptionDraft>) =>
    setForm(f => {
      const qs = [...f.questions];
      const opts = [...qs[qi].options];
      opts[oi] = { ...opts[oi], ...patch };
      qs[qi] = { ...qs[qi], options: opts };
      return { ...f, questions: qs };
    });
  const addOption = (qi: number) =>
    setForm(f => {
      const qs = [...f.questions];
      qs[qi] = { ...qs[qi], options: [...qs[qi].options, EMPTY_OPTION()] };
      return { ...f, questions: qs };
    });
  const removeOption = (qi: number, oi: number) =>
    setForm(f => {
      const qs = [...f.questions];
      qs[qi] = { ...qs[qi], options: qs[qi].options.filter((_, i) => i !== oi) };
      return { ...f, questions: qs };
    });

  // ── Band helpers ─────────────────────────────────────────────────────────────

  const addBand = () => {
    setForm(f => ({ ...f, result_bands: [...f.result_bands, EMPTY_BAND()] }));
    setOpenBIdx(form.result_bands.length);
  };
  const removeBand = (bi: number) => setForm(f => ({ ...f, result_bands: f.result_bands.filter((_, i) => i !== bi) }));
  const updateBand = (bi: number, patch: Partial<BandDraft>) =>
    setForm(f => { const bs = [...f.result_bands]; bs[bi] = { ...bs[bi], ...patch }; return { ...f, result_bands: bs }; });
  const toggleBandMaterial = (bi: number, mid: number) =>
    setForm(f => {
      const bs = [...f.result_bands];
      const ids = bs[bi].material_ids.includes(mid)
        ? bs[bi].material_ids.filter(i => i !== mid)
        : [...bs[bi].material_ids, mid];
      bs[bi] = { ...bs[bi], material_ids: ids };
      return { ...f, result_bands: bs };
    });

  // ── Render ────────────────────────────────────────────────────────────────────

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="max-w-5xl mx-auto px-4 pt-28 pb-16">

        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <Brain className="w-6 h-6 text-brand-600" />
            <h1 className="text-xl font-bold text-gray-900">Surveys & Screenings</h1>
          </div>
          <button
            onClick={openCreate}
            className="flex items-center gap-2 px-4 py-2.5 bg-brand-600 hover:bg-brand-700 text-white font-bold text-sm rounded-xl transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" /> New Survey
          </button>
        </div>

        {/* Survey list */}
        {loading ? (
          <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-400" /></div>
        ) : surveys.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-gray-100">
            <Brain className="w-10 h-10 text-gray-200 mx-auto mb-3" />
            <p className="text-gray-500 font-semibold">No surveys yet. Create one above.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {surveys.map(s => (
              <div key={s.id} className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4 flex items-center gap-4">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${s.is_active ? "bg-brand-100" : "bg-gray-100"}`}>
                  <Brain className={`w-5 h-5 ${s.is_active ? "text-brand-600" : "text-gray-400"}`} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-bold text-gray-900 text-sm">{s.title}</p>
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${s.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}>
                      {s.is_active ? "Active" : "Inactive"}
                    </span>
                  </div>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {s.questions_count} question{s.questions_count !== 1 ? "s" : ""} · {s.responses_count} response{s.responses_count !== 1 ? "s" : ""}
                  </p>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <Link href={`/surveys/${s.id}`} target="_blank"
                    className="p-2 rounded-lg text-gray-400 hover:text-brand-600 hover:bg-brand-50 transition-colors">
                    <Eye className="w-4 h-4" />
                  </Link>
                  <button onClick={() => openEdit(s.id)}
                    className="p-2 rounded-lg text-gray-400 hover:text-brand-600 hover:bg-brand-50 transition-colors">
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button onClick={() => deleteSurvey(s.id)}
                    className="p-2 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Form overlay ── */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-start justify-end overflow-y-auto">
          <div className="bg-white w-full max-w-2xl min-h-screen shadow-xl flex flex-col">
            {/* Form header */}
            <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between z-10">
              <h2 className="text-lg font-bold text-gray-900">{editId ? "Edit Survey" : "New Survey"}</h2>
              <div className="flex items-center gap-3">
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex items-center gap-2 px-5 py-2 bg-brand-600 hover:bg-brand-700 disabled:opacity-60 text-white font-bold text-sm rounded-xl transition-colors"
                >
                  {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                  {saving ? "Saving…" : "Save"}
                </button>
                <button onClick={() => setShowForm(false)} className="p-2 text-gray-400 hover:text-gray-600">
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-6">

              {/* ── Basic info ── */}
              <section>
                <h3 className="text-sm font-bold text-gray-700 uppercase tracking-wide mb-3">Basic Info</h3>
                <div className="space-y-3">
                  <input
                    placeholder="Survey title *"
                    value={form.title}
                    onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:border-brand-400"
                  />
                  <textarea
                    placeholder="Short description"
                    rows={2}
                    value={form.description}
                    onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:border-brand-400 resize-none"
                  />
                  <input
                    placeholder="Instructions (shown above each question)"
                    value={form.instructions}
                    onChange={e => setForm(f => ({ ...f, instructions: e.target.value }))}
                    className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:border-brand-400"
                  />
                  <div className="flex gap-3">
                    <input
                      placeholder="slug (auto-generated if blank)"
                      value={form.slug}
                      onChange={e => setForm(f => ({ ...f, slug: e.target.value }))}
                      className="flex-1 border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:border-brand-400"
                    />
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={form.is_active}
                        onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))}
                        className="w-4 h-4 accent-brand-600"
                      />
                      <span className="text-sm font-semibold text-gray-700">Active</span>
                    </label>
                  </div>
                </div>
              </section>

              {/* ── Questions ── */}
              <section>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-bold text-gray-700 uppercase tracking-wide">Questions ({form.questions.length})</h3>
                  <button onClick={addQuestion}
                    className="flex items-center gap-1 text-xs font-bold text-brand-600 hover:text-brand-700 px-2 py-1 rounded-lg hover:bg-brand-50 transition-colors">
                    <Plus className="w-3.5 h-3.5" /> Add Question
                  </button>
                </div>
                <div className="space-y-3">
                  {form.questions.map((q, qi) => (
                    <div key={qi} className="border border-gray-200 rounded-xl overflow-hidden">
                      <button
                        onClick={() => setOpenQIdx(openQIdx === qi ? null : qi)}
                        className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors"
                      >
                        <span className="text-sm font-semibold text-gray-700">
                          Q{qi + 1}: {q.question_text || <span className="text-gray-400 font-normal italic">Untitled question</span>}
                        </span>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={e => { e.stopPropagation(); removeQuestion(qi); }}
                            className="p-1 text-gray-400 hover:text-red-500 transition-colors"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                          {openQIdx === qi ? <ChevronUp className="w-4 h-4 text-gray-400" /> : <ChevronDown className="w-4 h-4 text-gray-400" />}
                        </div>
                      </button>

                      {openQIdx === qi && (
                        <div className="p-4 space-y-3">
                          <input
                            placeholder="Question text *"
                            value={q.question_text}
                            onChange={e => updateQuestion(qi, { question_text: e.target.value })}
                            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400"
                          />
                          <input
                            placeholder="Hint / sub-text (optional)"
                            value={q.hint}
                            onChange={e => updateQuestion(qi, { hint: e.target.value })}
                            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400"
                          />

                          <p className="text-xs font-bold text-gray-500 uppercase tracking-wide mt-2">Options</p>
                          {q.options.map((opt, oi) => (
                            <div key={oi} className="flex items-center gap-2">
                              <input
                                placeholder={`Option ${oi + 1} label`}
                                value={opt.label}
                                onChange={e => updateOption(qi, oi, { label: e.target.value })}
                                className="flex-1 border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:border-brand-400"
                              />
                              <input
                                type="number"
                                placeholder="Score"
                                min={0}
                                value={opt.score_value}
                                onChange={e => updateOption(qi, oi, { score_value: e.target.value === "" ? "" : Number(e.target.value) })}
                                className="w-20 border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:border-brand-400"
                              />
                              <select
                                value={opt.color}
                                onChange={e => updateOption(qi, oi, { color: e.target.value })}
                                className="w-28 border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:border-brand-400"
                              >
                                {["green", "yellow", "orange", "red"].map(c => (
                                  <option key={c} value={c}>{c}</option>
                                ))}
                              </select>
                              <button
                                onClick={() => removeOption(qi, oi)}
                                className="p-1.5 text-gray-400 hover:text-red-500 transition-colors"
                              >
                                <X className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          ))}
                          <button
                            onClick={() => addOption(qi)}
                            className="text-xs font-bold text-brand-600 hover:text-brand-700 flex items-center gap-1 mt-1"
                          >
                            <Plus className="w-3.5 h-3.5" /> Add option
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </section>

              {/* ── Result Bands ── */}
              <section>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-bold text-gray-700 uppercase tracking-wide">Result Bands ({form.result_bands.length})</h3>
                  <button onClick={addBand}
                    className="flex items-center gap-1 text-xs font-bold text-brand-600 hover:text-brand-700 px-2 py-1 rounded-lg hover:bg-brand-50 transition-colors">
                    <Plus className="w-3.5 h-3.5" /> Add Band
                  </button>
                </div>
                <div className="space-y-3">
                  {form.result_bands.map((b, bi) => (
                    <div key={bi} className="border border-gray-200 rounded-xl overflow-hidden">
                      <button
                        onClick={() => setOpenBIdx(openBIdx === bi ? null : bi)}
                        className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors"
                      >
                        <span className="text-sm font-semibold text-gray-700">
                          {b.label || <span className="text-gray-400 font-normal italic">Untitled band</span>}
                          {b.min_score !== "" && b.max_score !== "" && (
                            <span className="text-gray-400 font-normal"> ({b.min_score}–{b.max_score})</span>
                          )}
                        </span>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={e => { e.stopPropagation(); removeBand(bi); }}
                            className="p-1 text-gray-400 hover:text-red-500 transition-colors"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                          {openBIdx === bi ? <ChevronUp className="w-4 h-4 text-gray-400" /> : <ChevronDown className="w-4 h-4 text-gray-400" />}
                        </div>
                      </button>

                      {openBIdx === bi && (
                        <div className="p-4 space-y-3">
                          <input
                            placeholder="Band label (e.g. Mild Anxiety)"
                            value={b.label}
                            onChange={e => updateBand(bi, { label: e.target.value })}
                            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400"
                          />
                          <div className="flex gap-3">
                            <input
                              type="number" min={0} placeholder="Min score"
                              value={b.min_score}
                              onChange={e => updateBand(bi, { min_score: e.target.value === "" ? "" : Number(e.target.value) })}
                              className="flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400"
                            />
                            <input
                              type="number" min={0} placeholder="Max score"
                              value={b.max_score}
                              onChange={e => updateBand(bi, { max_score: e.target.value === "" ? "" : Number(e.target.value) })}
                              className="flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400"
                            />
                            <select
                              value={b.result_type}
                              onChange={e => updateBand(bi, { result_type: e.target.value as "low" | "moderate" | "high" })}
                              className="w-36 border border-gray-200 rounded-xl px-3 py-2.5 text-sm outline-none focus:border-brand-400"
                            >
                              <option value="low">Low</option>
                              <option value="moderate">Moderate</option>
                              <option value="high">High</option>
                            </select>
                          </div>
                          <textarea
                            placeholder="Result message shown to the user"
                            rows={3}
                            value={b.message}
                            onChange={e => updateBand(bi, { message: e.target.value })}
                            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm outline-none focus:border-brand-400 resize-none"
                          />
                          <label className="flex items-center gap-2 cursor-pointer">
                            <input
                              type="checkbox"
                              checked={b.show_therapist_cta}
                              onChange={e => updateBand(bi, { show_therapist_cta: e.target.checked })}
                              className="w-4 h-4 accent-brand-600"
                            />
                            <span className="text-sm text-gray-700">Show "Book a Therapist" button</span>
                          </label>

                          {/* Linked materials */}
                          <div>
                            <p className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">Linked Resources ({b.material_ids.length} selected)</p>
                            {materials.length === 0 ? (
                              <p className="text-xs text-gray-400">No materials available. Add some in the Mental Health section first.</p>
                            ) : (
                              <div className="max-h-40 overflow-y-auto space-y-1.5 pr-1">
                                {materials.map(m => (
                                  <label key={m.id} className="flex items-center gap-2.5 cursor-pointer p-2 rounded-lg hover:bg-gray-50 transition-colors">
                                    <div className={`w-5 h-5 rounded flex items-center justify-center flex-shrink-0 border-2 transition-colors ${
                                      b.material_ids.includes(m.id) ? "bg-brand-600 border-brand-600" : "border-gray-300"
                                    }`}>
                                      {b.material_ids.includes(m.id) && <CheckCircle2 className="w-3.5 h-3.5 text-white" />}
                                    </div>
                                    <span className="text-sm text-gray-700 flex-1 min-w-0 truncate">{m.title}</span>
                                    <span className={`text-xs font-semibold px-1.5 py-0.5 rounded-full flex-shrink-0 ${m.is_free ? "bg-green-100 text-green-700" : "bg-brand-100 text-brand-700"}`}>
                                      {m.is_free ? "Free" : m.price != null ? `KES ${Number(m.price).toLocaleString()}` : "Premium"}
                                    </span>
                                    <input
                                      type="checkbox"
                                      checked={b.material_ids.includes(m.id)}
                                      onChange={() => toggleBandMaterial(bi, m.id)}
                                      className="sr-only"
                                    />
                                  </label>
                                ))}
                              </div>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </section>

            </div>
          </div>
        </div>
      )}
    </main>
  );
}
