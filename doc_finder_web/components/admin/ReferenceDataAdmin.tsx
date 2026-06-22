"use client";

import { useEffect, useState, ComponentType } from "react";
import Navbar from "@/components/Navbar";
import {
  Plus, Pencil, Trash2, Loader2, X, Save, Search, CheckCircle2, XCircle,
} from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";

// ---------------------------------------------------------------------
// Field config — each page describes the shape of its records via this.
// ---------------------------------------------------------------------

export type ReferenceFieldType = "text" | "textarea" | "number" | "boolean";

export interface ReferenceField {
  /** API + record key (e.g. "specialization_name") */
  key: string;
  /** Display label in the form / table */
  label: string;
  type: ReferenceFieldType;
  /** Required on create */
  required?: boolean;
  /** Default when creating */
  default?: string | number | boolean;
  /** Placeholder for inputs */
  placeholder?: string;
  /** Show in the row list? Defaults to true. Booleans show as a badge. */
  showInRow?: boolean;
}

export interface ReferenceConfig {
  /** Page title (e.g. "Specializations") */
  title: string;
  /** Subtitle shown under the title */
  subtitle: string;
  /** Singular noun for buttons / messages (e.g. "Specialization") */
  singular: string;
  /** Icon component, e.g. Stethoscope from lucide-react */
  icon: ComponentType<{ className?: string }>;
  /** Gradient class for the icon badge (e.g. "from-blue-500 to-indigo-600") */
  gradient: string;
  /** API base path under the api client baseURL (e.g. "/admin/reference/specializations") */
  endpoint: string;
  /** Primary field used as the row title */
  primaryField: string;
  /** Optional secondary text field used as the row subtitle */
  secondaryField?: string;
  /** Field definitions used for the form + record reading */
  fields: ReferenceField[];
}

interface ReferenceRecord {
  id: number;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------

export default function ReferenceDataAdmin({ config }: { config: ReferenceConfig }) {
  const [records, setRecords] = useState<ReferenceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<Record<string, string | number | boolean>>({});
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const load = () => {
    setLoading(true);
    api.get(config.endpoint)
      .then(res => {
        const data = Array.isArray(res.data?.data) ? res.data.data : [];
        setRecords(data);
      })
      .catch(() => toast.error(`Failed to load ${config.title.toLowerCase()}`))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config.endpoint]);

  const startCreate = () => {
    setEditingId(null);
    const initial: Record<string, string | number | boolean> = {};
    for (const f of config.fields) {
      initial[f.key] = f.default ?? (f.type === "boolean" ? true : f.type === "number" ? 0 : "");
    }
    setForm(initial);
    setShowForm(true);
  };

  const startEdit = (r: ReferenceRecord) => {
    setEditingId(r.id);
    const initial: Record<string, string | number | boolean> = {};
    for (const f of config.fields) {
      const v = r[f.key];
      if (f.type === "boolean") {
        initial[f.key] = v === true || v === 1 || v === "1";
      } else if (f.type === "number") {
        initial[f.key] = typeof v === "number" ? v : Number(v ?? 0);
      } else {
        initial[f.key] = v == null ? "" : String(v);
      }
    }
    setForm(initial);
    setShowForm(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();

    // basic required-field validation
    for (const f of config.fields) {
      if (f.required && f.type !== "boolean") {
        const v = form[f.key];
        if (v === undefined || v === null || String(v).trim() === "") {
          toast.error(`${f.label} is required`);
          return;
        }
      }
    }

    setSaving(true);
    try {
      const payload: Record<string, unknown> = {};
      for (const f of config.fields) {
        const v = form[f.key];
        if (f.type === "boolean") {
          payload[f.key] = !!v;
        } else if (f.type === "number") {
          payload[f.key] = v === "" || v === undefined ? null : Number(v);
        } else {
          payload[f.key] = typeof v === "string" ? v.trim() : v;
        }
      }

      if (editingId) {
        await api.put(`${config.endpoint}/${editingId}`, payload);
        toast.success(`${config.singular} updated`);
      } else {
        await api.post(config.endpoint, payload);
        toast.success(`${config.singular} created`);
      }
      setShowForm(false);
      load();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const data = ax?.response?.data;
      const msg = data?.errors ? Object.values(data.errors)[0]?.[0] : data?.message;
      toast.error(msg ?? `Failed to save ${config.singular.toLowerCase()}`);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm(`Delete this ${config.singular.toLowerCase()} permanently?`)) return;
    setDeletingId(id);
    try {
      await api.delete(`${config.endpoint}/${id}`);
      toast.success(`${config.singular} deleted`);
      setRecords(prev => prev.filter(r => r.id !== id));
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg ?? `Failed to delete ${config.singular.toLowerCase()}`);
    } finally {
      setDeletingId(null);
    }
  };

  // Search filter (client-side)
  const filtered = search.trim()
    ? records.filter(r => {
        const blob = JSON.stringify(r).toLowerCase();
        return blob.includes(search.toLowerCase());
      })
    : records;

  const Icon = config.icon;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="max-w-5xl mx-auto px-4 pt-28 pb-16">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-2xl bg-gradient-to-br ${config.gradient} flex items-center justify-center shadow-sm`}>
              <Icon className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">{config.title}</h1>
              <p className="text-sm text-gray-400">
                {loading ? "Loading…" : `${records.length} ${config.title.toLowerCase()}`}
                {config.subtitle && ` · ${config.subtitle}`}
              </p>
            </div>
          </div>
          <button onClick={startCreate}
            className={`inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r ${config.gradient} hover:opacity-95 text-white text-sm font-bold rounded-xl transition-all shadow-sm`}>
            <Plus className="w-4 h-4" /> New {config.singular}
          </button>
        </div>

        {/* Search */}
        <div className="bg-white rounded-2xl border border-gray-100 p-3 mb-6">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input type="text" value={search} onChange={e => setSearch(e.target.value)}
              placeholder={`Search ${config.title.toLowerCase()}…`}
              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-brand-200 focus:border-brand-400" />
          </div>
        </div>

        {/* List */}
        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-brand-500" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-gray-100">
            <Icon className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-1">
              {search ? `No ${config.title.toLowerCase()} match your search` : `No ${config.title.toLowerCase()} yet`}
            </p>
            {!search && (
              <>
                <p className="text-sm text-gray-400 mb-5">Add your first {config.singular.toLowerCase()} to get started.</p>
                <button onClick={startCreate}
                  className={`inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r ${config.gradient} text-white text-sm font-bold rounded-xl`}>
                  <Plus className="w-4 h-4" /> New {config.singular}
                </button>
              </>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map(r => (
              <Row
                key={r.id}
                record={r}
                config={config}
                deleting={deletingId === r.id}
                onEdit={() => startEdit(r)}
                onDelete={() => handleDelete(r.id)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden max-h-[92vh] flex flex-col">
            <div className="flex items-center justify-between px-6 py-4 border-b flex-shrink-0">
              <h3 className="font-bold text-gray-800">{editingId ? `Edit ${config.singular}` : `New ${config.singular}`}</h3>
              <button onClick={() => setShowForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>

            <form onSubmit={handleSave} className="overflow-y-auto p-6 space-y-4">
              {config.fields.map(f => (
                <FieldInput
                  key={f.key}
                  field={f}
                  value={form[f.key]}
                  onChange={(v) => setForm(prev => ({ ...prev, [f.key]: v }))}
                />
              ))}
              <button type="submit" disabled={saving}
                className={`w-full py-3.5 bg-gradient-to-r ${config.gradient} hover:opacity-95 disabled:opacity-50 text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm`}>
                {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving…</> : <><Save className="w-4 h-4" /> {editingId ? "Save Changes" : `Create ${config.singular}`}</>}
              </button>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}

// ---------------------------------------------------------------------
// Helpers — kept local; not worth promoting to /components yet.
// ---------------------------------------------------------------------

function Row({
  record, config, deleting, onEdit, onDelete,
}: {
  record: ReferenceRecord;
  config: ReferenceConfig;
  deleting: boolean;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const title = String(record[config.primaryField] ?? "—");
  const subtitle = config.secondaryField ? String(record[config.secondaryField] ?? "") : "";

  const extraFields = config.fields.filter(
    f => f.key !== config.primaryField && f.key !== config.secondaryField && f.showInRow !== false,
  );

  const Icon = config.icon;

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex items-center gap-4">
      <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${config.gradient} flex-shrink-0 flex items-center justify-center text-white opacity-80`}>
        <Icon className="w-5 h-5" />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap mb-1">
          <p className="text-sm font-bold text-gray-900 truncate">{title}</p>
          {extraFields.map(f => {
            const v = record[f.key];
            if (f.type === "boolean") {
              const truthy = v === true || v === 1 || v === "1";
              return (
                <span key={f.key} className={`text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1 ${
                  truthy ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"
                }`}>
                  {truthy ? <CheckCircle2 className="w-2.5 h-2.5" /> : <XCircle className="w-2.5 h-2.5" />}
                  {f.label}
                </span>
              );
            }
            if (f.type === "number" && v != null && v !== "" && Number(v) !== 0) {
              return (
                <span key={f.key} className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
                  {f.label}: {String(v)}
                </span>
              );
            }
            return null;
          })}
        </div>
        {subtitle && <p className="text-xs text-gray-400 line-clamp-2">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-2 flex-shrink-0">
        <button onClick={onEdit}
          className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-blue-300 hover:text-blue-600 transition-colors" title="Edit">
          <Pencil className="w-4 h-4" />
        </button>
        <button onClick={onDelete} disabled={deleting}
          className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-red-300 hover:text-red-600 transition-colors disabled:opacity-50" title="Delete">
          {deleting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
        </button>
      </div>
    </div>
  );
}

function FieldInput({
  field, value, onChange,
}: {
  field: ReferenceField;
  value: string | number | boolean | undefined;
  onChange: (v: string | number | boolean) => void;
}) {
  if (field.type === "boolean") {
    const on = !!value;
    return (
      <div>
        <label className="block text-xs font-bold text-gray-600 mb-2">{field.label}</label>
        <button type="button"
          onClick={() => onChange(!on)}
          className={`w-full py-2.5 rounded-xl text-xs font-bold border-2 transition-all flex items-center justify-center gap-1 ${
            on ? "border-green-400 bg-green-50 text-green-700" : "border-gray-200 text-gray-500"
          }`}>
          {on ? <CheckCircle2 className="w-3.5 h-3.5" /> : <XCircle className="w-3.5 h-3.5" />}
          {on ? "Yes" : "No"}
        </button>
      </div>
    );
  }

  if (field.type === "textarea") {
    return (
      <div>
        <label className="block text-xs font-bold text-gray-600 mb-1.5">
          {field.label} {field.required && <span className="text-red-500">*</span>}
        </label>
        <textarea rows={3}
          value={typeof value === "string" ? value : value == null ? "" : String(value)}
          onChange={e => onChange(e.target.value)}
          placeholder={field.placeholder}
          className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-brand-200 focus:border-brand-400 resize-none" />
      </div>
    );
  }

  return (
    <div>
      <label className="block text-xs font-bold text-gray-600 mb-1.5">
        {field.label} {field.required && <span className="text-red-500">*</span>}
      </label>
      <input
        type={field.type === "number" ? "number" : "text"}
        value={value == null ? "" : String(value)}
        onChange={e => onChange(field.type === "number" ? (e.target.value === "" ? "" : Number(e.target.value)) : e.target.value)}
        placeholder={field.placeholder}
        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-brand-200 focus:border-brand-400" />
    </div>
  );
}
