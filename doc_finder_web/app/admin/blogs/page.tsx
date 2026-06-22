"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import {
  BookOpen, Plus, Pencil, Trash2, Eye, Globe, Clock,
  Loader2, X, Upload, Image as ImageIcon, Tag, TrendingUp, Star,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import toast from "react-hot-toast";
import RichTextEditor from "@/components/RichTextEditor";

interface Blog {
  id: number;
  title: string;
  slug: string;
  excerpt?: string;
  content?: string;
  featured_image?: string;
  author_name?: string;
  status: "draft" | "published";
  is_featured: boolean;
  is_trending: boolean;
  tags?: string[] | null;
  views_count?: number;
  published_at?: string;
  created_at?: string;
}

interface Pagination {
  current_page: number;
  last_page: number;
  total: number;
}

const EMPTY_FORM = {
  title: "",
  excerpt: "",
  content: "",
  status: "draft" as "draft" | "published",
  is_featured: false,
  is_trending: false,
  tagsRaw: "",
  image: null as File | null,
};

export default function AdminBlogsPage() {
  const router   = useRouter();
  const imgRef   = useRef<HTMLInputElement>(null);

  const [blogs, setBlogs]           = useState<Blog[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [page, setPage]             = useState(1);
  const [loading, setLoading]       = useState(true);
  const [showForm, setShowForm]     = useState(false);
  const [editId, setEditId]         = useState<number | null>(null);
  const [form, setForm]             = useState({ ...EMPTY_FORM });
  const [saving, setSaving]         = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  useEffect(() => {
    if (!localStorage.getItem("auth_token")) { router.replace("/login"); return; }
    load(page);
  }, [page]);

  const load = (p: number) => {
    setLoading(true);
    api.get("/my-blogs", { params: { page: p, per_page: 10 } })
      .then(res => {
        setBlogs(Array.isArray(res.data?.data) ? res.data.data : []);
        if (res.data?.pagination) setPagination(res.data.pagination);
      })
      .catch(() => toast.error("Failed to load articles"))
      .finally(() => setLoading(false));
  };

  const openNew = () => {
    setEditId(null);
    setForm({ ...EMPTY_FORM });
    setShowForm(true);
  };

  const openEdit = (b: Blog) => {
    setEditId(b.id);
    setForm({
      title: b.title,
      excerpt: b.excerpt ?? "",
      content: b.content ?? "",
      status: b.status,
      is_featured: b.is_featured,
      is_trending: b.is_trending,
      tagsRaw: b.tags ? b.tags.join(", ") : "",
      image: null,
    });
    setShowForm(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) { toast.error("Title is required"); return; }
    if (!form.excerpt.trim()) { toast.error("Excerpt is required"); return; }
    if (!form.content.trim()) { toast.error("Content is required"); return; }
    setSaving(true);

    const fd = new FormData();
    fd.append("title", form.title);
    fd.append("excerpt", form.excerpt);
    fd.append("content", form.content);
    fd.append("status", form.status);
    fd.append("is_featured", form.is_featured ? "true" : "false");
    fd.append("is_trending", form.is_trending ? "true" : "false");

    // Send tags as individual indexed fields
    const tags = form.tagsRaw.split(",").map(t => t.trim()).filter(Boolean);
    tags.forEach((tag, i) => fd.append(`tags[${i}]`, tag));

    if (form.image) fd.append("featured_image", form.image);

    try {
      if (editId) {
        fd.append("_method", "PUT");
        await api.post(`/blogs/${editId}`, fd, { headers: { "Content-Type": "multipart/form-data" } });
        toast.success("Article updated");
      } else {
        await api.post("/blogs", fd, { headers: { "Content-Type": "multipart/form-data" } });
        toast.success("Article published");
      }
      setShowForm(false);
      load(page);
    } catch (err: unknown) {
      const errors = (err as { response?: { data?: { errors?: Record<string, string[]> } } })?.response?.data?.errors;
      if (errors) {
        const first = Object.values(errors)[0]?.[0];
        toast.error(first ?? "Failed to save article");
      } else {
        toast.error("Failed to save article");
      }
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this article permanently?")) return;
    setDeletingId(id);
    try {
      await api.delete(`/blogs/${id}`);
      toast.success("Article deleted");
      setBlogs(prev => prev.filter(b => b.id !== id));
    } catch {
      toast.error("Failed to delete article");
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      <div className="max-w-5xl mx-auto px-4 pt-28 pb-16">

        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-sm">
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">Articles & Blogs</h1>
              <p className="text-sm text-gray-400">Write and publish health articles</p>
            </div>
          </div>
          <div className="flex gap-2">
            <Link href="/trending" className="px-4 py-2 border border-gray-200 text-sm font-semibold text-gray-600 rounded-xl hover:bg-gray-50 transition-colors">
              Preview
            </Link>
            <button onClick={openNew}
              className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold rounded-xl hover:from-blue-600 hover:to-indigo-700 transition-all shadow-sm">
              <Plus className="w-4 h-4" /> New Article
            </button>
          </div>
        </div>

        {/* List */}
        {loading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-indigo-500" />
          </div>
        ) : blogs.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-gray-100">
            <BookOpen className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="font-semibold text-gray-600 mb-1">No articles yet</p>
            <p className="text-sm text-gray-400 mb-5">Write your first health article to get started.</p>
            <button onClick={openNew}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-sm font-bold rounded-xl">
              <Plus className="w-4 h-4" /> New Article
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {blogs.map(b => {
              const img = getImageUrl(b.featured_image);
              return (
                <div key={b.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex items-center gap-4">
                  <div className="w-16 h-16 rounded-xl bg-indigo-50 flex-shrink-0 overflow-hidden flex items-center justify-center">
                    {img
                      ? <img src={img} alt={b.title} className="w-full h-full object-cover" />
                      : <BookOpen className="w-7 h-7 text-indigo-300" />}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-0.5">
                      <p className="text-sm font-bold text-gray-900 truncate">{b.title}</p>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded-full flex items-center gap-1 ${
                        b.status === "published" ? "bg-green-100 text-green-700" : "bg-amber-100 text-amber-700"
                      }`}>
                        {b.status === "published" ? <Globe className="w-2.5 h-2.5" /> : <Clock className="w-2.5 h-2.5" />}
                        {b.status === "published" ? "Published" : "Draft"}
                      </span>
                      {b.is_featured && (
                        <span className="text-xs font-bold bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded-full flex items-center gap-1">
                          <Star className="w-2.5 h-2.5" /> Featured
                        </span>
                      )}
                      {b.is_trending && (
                        <span className="text-xs font-bold bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full flex items-center gap-1">
                          <TrendingUp className="w-2.5 h-2.5" /> Trending
                        </span>
                      )}
                    </div>
                    {b.excerpt && <p className="text-xs text-gray-400 truncate">{b.excerpt}</p>}
                    <div className="flex items-center gap-3 mt-0.5">
                      {b.tags && b.tags.length > 0 && (
                        <span className="text-xs text-indigo-500 font-medium flex items-center gap-1">
                          <Tag className="w-3 h-3" /> {b.tags.slice(0, 3).join(", ")}
                        </span>
                      )}
                      {b.views_count != null && (
                        <span className="text-xs text-gray-400 flex items-center gap-1">
                          <Eye className="w-3 h-3" /> {b.views_count}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2 flex-shrink-0">
                    {b.slug && (
                      <Link href={`/trending/${b.slug}`} target="_blank"
                        className="p-2 rounded-xl border border-gray-200 text-gray-400 hover:border-indigo-300 hover:text-indigo-500 transition-colors">
                        <Eye className="w-4 h-4" />
                      </Link>
                    )}
                    <button onClick={() => openEdit(b)}
                      className="p-2 rounded-xl border border-gray-200 text-gray-500 hover:border-indigo-300 hover:text-indigo-600 transition-colors">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button onClick={() => handleDelete(b.id)} disabled={deletingId === b.id}
                      className="p-2 rounded-xl border border-gray-200 text-gray-400 hover:border-red-300 hover:text-red-500 transition-colors">
                      {deletingId === b.id ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Pagination */}
        {pagination && pagination.last_page > 1 && (
          <div className="flex items-center justify-center gap-3 mt-8">
            <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
              className="px-4 py-2 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 disabled:opacity-40 hover:bg-gray-50 transition-colors">
              Previous
            </button>
            <span className="text-sm text-gray-500">Page {page} of {pagination.last_page}</span>
            <button disabled={page === pagination.last_page} onClick={() => setPage(p => p + 1)}
              className="px-4 py-2 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 disabled:opacity-40 hover:bg-gray-50 transition-colors">
              Next
            </button>
          </div>
        )}
      </div>

      {/* ── Create / Edit Modal ── */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-3xl w-full max-w-2xl shadow-2xl overflow-hidden max-h-[92vh] flex flex-col">

            {/* Modal header */}
            <div className="flex items-center justify-between px-6 py-4 border-b flex-shrink-0">
              <h3 className="font-bold text-gray-800">{editId ? "Edit Article" : "New Article"}</h3>
              <button onClick={() => setShowForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>

            <form onSubmit={handleSave} className="overflow-y-auto p-6 space-y-5">

              {/* Title */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">
                  Title <span className="text-red-500">*</span>
                </label>
                <input type="text" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                  placeholder="e.g. 5 Signs You Might Be Experiencing Burnout"
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-indigo-200 focus:border-indigo-400" />
              </div>

              {/* Excerpt */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">
                  Excerpt <span className="text-red-500">*</span>
                  <span className="font-normal text-gray-400 ml-1">(max 500 chars)</span>
                </label>
                <textarea rows={2} maxLength={500} value={form.excerpt} onChange={e => setForm(f => ({ ...f, excerpt: e.target.value }))}
                  placeholder="A short summary shown in article listings…"
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-indigo-200 focus:border-indigo-400 resize-none" />
                <p className="text-xs text-gray-400 mt-1 text-right">{form.excerpt.length}/500</p>
              </div>

              {/* Content */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">
                  Content <span className="text-red-500">*</span>
                </label>
                <RichTextEditor
                  value={form.content}
                  onChange={html => setForm(f => ({ ...f, content: html }))}
                  placeholder="Write your full article here…"
                  minHeight="320px"
                />
              </div>

              {/* Featured image */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">Cover Image</label>
                <div onClick={() => imgRef.current?.click()}
                  className="border-2 border-dashed border-gray-200 rounded-xl p-4 text-center cursor-pointer hover:border-indigo-300 transition-colors">
                  {form.image
                    ? <p className="text-sm font-semibold text-indigo-600">{form.image.name}</p>
                    : <><ImageIcon className="w-6 h-6 text-gray-300 mx-auto mb-1" /><p className="text-xs text-gray-400">Click to upload image (JPG, PNG, max 5MB)</p></>}
                </div>
                <input ref={imgRef} type="file" accept="image/*" className="hidden"
                  onChange={e => setForm(f => ({ ...f, image: e.target.files?.[0] ?? null }))} />
              </div>

              {/* Tags */}
              <div>
                <label className="block text-xs font-bold text-gray-600 mb-1.5">
                  Tags <span className="font-normal text-gray-400">(comma separated)</span>
                </label>
                <div className="relative">
                  <Tag className="absolute left-3.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
                  <input type="text" value={form.tagsRaw} onChange={e => setForm(f => ({ ...f, tagsRaw: e.target.value }))}
                    placeholder="e.g. mental health, anxiety, wellness"
                    className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:ring-2 focus:ring-indigo-200 focus:border-indigo-400" />
                </div>
              </div>

              {/* Status + Featured + Trending */}
              <div className="grid grid-cols-3 gap-3">
                {/* Status */}
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-2">Status</label>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => setForm(f => ({ ...f, status: "published" }))}
                      className={`flex-1 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${form.status === "published" ? "border-green-400 bg-green-50 text-green-700" : "border-gray-200 text-gray-500"}`}>
                      Publish
                    </button>
                    <button type="button" onClick={() => setForm(f => ({ ...f, status: "draft" }))}
                      className={`flex-1 py-2.5 rounded-xl text-xs font-bold border-2 transition-all ${form.status === "draft" ? "border-amber-400 bg-amber-50 text-amber-700" : "border-gray-200 text-gray-500"}`}>
                      Draft
                    </button>
                  </div>
                </div>

                {/* Featured */}
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-2">Featured</label>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_featured: !f.is_featured }))}
                      className={`w-full py-2.5 rounded-xl text-xs font-bold border-2 transition-all flex items-center justify-center gap-1 ${form.is_featured ? "border-yellow-400 bg-yellow-50 text-yellow-700" : "border-gray-200 text-gray-500"}`}>
                      <Star className="w-3 h-3" /> {form.is_featured ? "Yes" : "No"}
                    </button>
                  </div>
                </div>

                {/* Trending */}
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-2">Trending</label>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => setForm(f => ({ ...f, is_trending: !f.is_trending }))}
                      className={`w-full py-2.5 rounded-xl text-xs font-bold border-2 transition-all flex items-center justify-center gap-1 ${form.is_trending ? "border-orange-400 bg-orange-50 text-orange-700" : "border-gray-200 text-gray-500"}`}>
                      <TrendingUp className="w-3 h-3" /> {form.is_trending ? "Yes" : "No"}
                    </button>
                  </div>
                </div>
              </div>

              <button type="submit" disabled={saving}
                className="w-full py-3.5 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 disabled:opacity-50 text-white font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm">
                {saving ? <><Loader2 className="w-4 h-4 animate-spin" /> Saving…</> : <><Upload className="w-4 h-4" /> {editId ? "Save Changes" : "Publish Article"}</>}
              </button>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
