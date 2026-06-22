"use client";

import { useMemo } from "react";

export interface UserFormValues {
  name: string;
  email: string;
  password?: string;
  telephone?: string | null;
  id_number?: string | null;
  address?: string | null;
  dob?: string | null;
  account_type: number;
  licence_number?: string | null;
  professional_bio?: string | null;
  specializations?: number[];
  is_active: boolean;
  sp_approved?: number;
}

interface Spec { id: number; name: string }

export default function UserForm({
  initial, specs, mode, onSubmit, submitting, submitLabel, submitIcon,
}: {
  initial: UserFormValues;
  specs: Spec[];
  mode: "create" | "edit";
  onSubmit: (values: UserFormValues) => void;
  submitting: boolean;
  submitLabel: string;
  submitIcon: React.ReactNode;
}) {
  const initialValues = useMemo(() => ({ ...initial, specializations: initial.specializations ?? [] }), [initial]);

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        const f = new FormData(e.currentTarget);
        const account_type = Number(f.get("account_type"));
        const values: UserFormValues = {
          name: String(f.get("name") || "").trim(),
          email: String(f.get("email") || "").trim(),
          password: String(f.get("password") || "") || undefined,
          telephone: String(f.get("telephone") || "") || null,
          id_number: String(f.get("id_number") || "") || null,
          address: String(f.get("address") || "") || null,
          dob: String(f.get("dob") || "") || null,
          account_type,
          licence_number: String(f.get("licence_number") || "") || null,
          professional_bio: String(f.get("professional_bio") || "") || null,
          specializations: f.getAll("specializations").map(v => Number(v)),
          is_active: f.get("is_active") === "1",
          sp_approved: account_type === 2 ? Number(f.get("sp_approved") || 0) : 0,
        };
        if (!values.name || !values.email) return;
        onSubmit(values);
      }}
      className="bg-white rounded-2xl border border-gray-100 p-6 space-y-5"
    >
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Field label="Full Name" required>
          <input name="name" type="text" defaultValue={initialValues.name} required
            className="input" placeholder="Jane Doe" />
        </Field>
        <Field label="Email" required>
          <input name="email" type="email" defaultValue={initialValues.email} required
            className="input" placeholder="jane@example.com" />
        </Field>
        <Field label={mode === "create" ? "Password" : "New Password (optional)"} required={mode === "create"}>
          <input name="password" type="password" minLength={8}
            required={mode === "create"}
            className="input" placeholder={mode === "edit" ? "Leave blank to keep current" : "At least 8 characters"} />
        </Field>
        <Field label="Telephone">
          <input name="telephone" type="tel" defaultValue={initialValues.telephone ?? ""}
            className="input" placeholder="+254..." />
        </Field>
        <Field label="ID Number">
          <input name="id_number" type="text" defaultValue={initialValues.id_number ?? ""}
            className="input" />
        </Field>
        <Field label="Date of Birth">
          <input name="dob" type="date" defaultValue={initialValues.dob ?? ""}
            className="input" />
        </Field>
        <Field label="Address" full>
          <input name="address" type="text" defaultValue={initialValues.address ?? ""}
            className="input" placeholder="Street, City" />
        </Field>
      </div>

      <Field label="Account Type" required>
        <select name="account_type" defaultValue={String(initialValues.account_type)} className="input">
          <option value="1">Standard</option>
          <option value="2">Service Provider</option>
          <option value="3">Admin</option>
        </select>
      </Field>

      {/* Service-provider extras */}
      <details open={initialValues.account_type === 2} className="border border-gray-200 rounded-xl p-4">
        <summary className="text-sm font-bold text-gray-700 cursor-pointer">Service provider details (only used when role is "Service Provider")</summary>
        <div className="mt-4 space-y-4">
          <Field label="Licence Number">
            <input name="licence_number" type="text" defaultValue={initialValues.licence_number ?? ""} className="input" />
          </Field>
          <Field label="Professional Bio">
            <textarea name="professional_bio" rows={3} defaultValue={initialValues.professional_bio ?? ""}
              className="input resize-none" placeholder="Brief biography or areas of expertise" />
          </Field>
          <Field label="Approval Status">
            <select name="sp_approved" defaultValue={String(initialValues.sp_approved ?? 0)} className="input">
              <option value="0">Pending</option>
              <option value="1">Approved</option>
              <option value="3">Declined</option>
            </select>
          </Field>
          {specs.length > 0 && (
            <Field label="Specializations">
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 max-h-48 overflow-y-auto p-2 border border-gray-200 rounded-xl">
                {specs.map(s => (
                  <label key={s.id} className="flex items-center gap-2 text-sm">
                    <input type="checkbox" name="specializations" value={s.id}
                      defaultChecked={initialValues.specializations?.includes(s.id)}
                      className="rounded text-brand-500 focus:ring-brand-400" />
                    <span className="text-gray-700">{s.name}</span>
                  </label>
                ))}
              </div>
            </Field>
          )}
        </div>
      </details>

      <Field label="Active">
        <select name="is_active" defaultValue={initialValues.is_active ? "1" : "0"} className="input">
          <option value="1">Active</option>
          <option value="0">Inactive</option>
        </select>
      </Field>

      <button type="submit" disabled={submitting}
        className="w-full inline-flex items-center justify-center gap-2 py-3 bg-brand-500 hover:bg-brand-600 disabled:opacity-50 text-white font-bold text-sm rounded-xl transition-colors shadow-sm">
        {submitIcon} {submitLabel}
      </button>

      <style jsx>{`
        :global(.input) {
          width: 100%;
          padding: 0.625rem 1rem;
          border-radius: 0.75rem;
          border: 1px solid #e5e7eb;
          font-size: 0.875rem;
          outline: none;
          background: white;
          color: #1f2937;
        }
        :global(.input:focus) {
          border-color: rgb(var(--brand-400, 99 102 241));
          box-shadow: 0 0 0 3px rgb(var(--brand-200, 199 210 254));
        }
      `}</style>
    </form>
  );
}

function Field({ label, required, children, full }: {
  label: string; required?: boolean; children: React.ReactNode; full?: boolean;
}) {
  return (
    <div className={full ? "sm:col-span-2" : ""}>
      <label className="block text-xs font-bold text-gray-600 mb-1.5">
        {label}{required && <span className="text-red-500 ml-0.5">*</span>}
      </label>
      {children}
    </div>
  );
}
