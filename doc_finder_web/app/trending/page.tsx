"use client";

import { useEffect, useState, useCallback } from "react";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Link from "next/link";
import {
  TrendingUp, Search, X, Clock, Tag, BookOpen,
  RefreshCw, ChevronRight, Flame,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";
import { truncate } from "@/lib/utils";

interface Blog {
  id: number;
  title: string;
  slug: string;
  excerpt?: string;
  content?: string;
  featured_image?: string;
  author_name?: string;
  created_at?: string;
  published_at?: string;
  tags?: string[] | null;
  views_count?: number;
  is_trending?: boolean;
  is_featured?: boolean;
}

interface Pagination {
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 animate-pulse">
      <div className="h-48 bg-gray-200" />
      <div className="p-5 space-y-2">
        <div className="h-3 bg-gray-100 rounded w-1/4" />
        <div className="h-4 bg-gray-200 rounded w-full" />
        <div className="h-3 bg-gray-100 rounded w-4/5" />
        <div className="h-3 bg-gray-100 rounded w-1/2" />
      </div>
    </div>
  );
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const diff = Math.floor((now.getTime() - date.getTime()) / 1000);
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} hours ago`;
  if (diff < 2592000) return `${Math.floor(diff / 86400)} days ago`;
  return date.toLocaleDateString("en-KE", { day: "numeric", month: "short", year: "numeric" });
}

export default function TrendingPage() {
  const [blogs, setBlogs] = useState<Blog[]>([]);
  const [trendingBlogs, setTrendingBlogs] = useState<Blog[]>([]);
  const [tags, setTags] = useState<string[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState("");
  const [selectedTag, setSelectedTag] = useState("");
  const [page, setPage] = useState(1);

  // Load trending sidebar + tags on mount
  useEffect(() => {
    api.get<{ success: boolean; data: Blog[] }>("/blogs/trending")
      .then(res => setTrendingBlogs(Array.isArray(res.data?.data) ? res.data.data.slice(0, 5) : []))
      .catch(() => {});

    api.get<{ success: boolean; data: string[] }>("/blogs/tags")
      .then(res => setTags(Array.isArray(res.data?.data) ? res.data.data.slice(0, 15) : []))
      .catch(() => {});
  }, []);

  const fetchBlogs = useCallback((pageNum: number, searchQ: string, tag: string) => {
    setLoading(true);
    const params: Record<string, string | number> = { page: pageNum, per_page: 9 };
    if (searchQ.trim()) params.search = searchQ.trim();
    if (tag) params.tags = tag;

    api.get<{ success: boolean; data: Blog[]; pagination: Pagination }>("/blogs", { params })
      .then(res => {
        setBlogs(Array.isArray(res.data?.data) ? res.data.data : []);
        setPagination(res.data?.pagination ?? null);
        setError(false);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchBlogs(page, search, selectedTag);
  }, [page, search, selectedTag, fetchBlogs]);

  const handleSearch = (q: string) => { setSearch(q); setPage(1); };
  const handleTag = (t: string) => { setSelectedTag(t === selectedTag ? "" : t); setPage(1); };

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Hero header */}
      <div className="bg-gradient-to-r from-rose-600 to-pink-500 pt-28 pb-10 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            <TrendingUp className="w-7 h-7 text-white" />
            <h1 className="text-2xl sm:text-3xl font-bold text-white">Trending</h1>
          </div>
          <p className="text-rose-100 text-sm mb-6">Health insights, news, and advice from our experts</p>

          {/* Search */}
          <div className="relative max-w-xl">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => handleSearch(e.target.value)}
              placeholder="Search articles…"
              className="w-full pl-11 pr-10 py-3.5 rounded-2xl border-0 bg-white text-sm outline-none shadow-sm"
            />
            {search && (
              <button onClick={() => handleSearch("")} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-8 pb-16">
        <div className="flex flex-col lg:flex-row gap-8">

          {/* ── Main content ── */}
          <div className="flex-1 min-w-0">

            {/* Tag filter pills */}
            {tags.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-6">
                <button onClick={() => handleTag("")}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold transition-colors ${
                    !selectedTag ? "bg-rose-500 text-white" : "bg-white text-gray-600 border border-gray-200 hover:border-rose-300"
                  }`}>
                  All
                </button>
                {tags.map(t => (
                  <button key={t} onClick={() => handleTag(t)}
                    className={`flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold transition-colors ${
                      selectedTag === t ? "bg-rose-500 text-white" : "bg-white text-gray-600 border border-gray-200 hover:border-rose-300"
                    }`}>
                    <Tag className="w-3 h-3" /> {t}
                  </button>
                ))}
              </div>
            )}

            {/* Results count */}
            <p className="text-sm text-gray-500 font-medium mb-4">
              {loading ? "Loading…" : pagination ? `${pagination.total} article${pagination.total !== 1 ? "s" : ""}` : ""}
            </p>

            {loading && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-5">
                {Array.from({length: 6}).map((_,i) => <CardSkeleton key={i} />)}
              </div>
            )}

            {error && (
              <div className="text-center py-16">
                <BookOpen className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                <p className="font-semibold text-gray-600 mb-2">Failed to load articles</p>
                <button onClick={() => fetchBlogs(page, search, selectedTag)}
                  className="inline-flex items-center gap-2 px-5 py-2.5 bg-rose-500 hover:bg-rose-600 text-white font-semibold text-sm rounded-xl transition-colors">
                  <RefreshCw className="w-4 h-4" /> Retry
                </button>
              </div>
            )}

            {!loading && !error && blogs.length === 0 && (
              <div className="text-center py-16">
                <Search className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                <p className="font-semibold text-gray-600 mb-1">No articles found</p>
                <p className="text-sm text-gray-400">Try a different search or tag</p>
              </div>
            )}

            {!loading && !error && blogs.length > 0 && (
              <>
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                  {blogs.map(blog => {
                    const imageUrl = getImageUrl(blog.featured_image);
                    const excerpt = blog.excerpt ?? (blog.content ? truncate(blog.content, 90) : "");
                    const date = blog.published_at ?? blog.created_at;

                    return (
                      <Link key={blog.id} href={`/trending/${blog.slug}`}
                        className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 hover:shadow-md transition-all duration-200 hover:-translate-y-0.5 group block">
                        <div className="h-48 bg-brand-50 overflow-hidden flex items-center justify-center">
                          {imageUrl
                            ? <img src={imageUrl} alt={blog.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                            : <BookOpen className="w-10 h-10 text-brand-200" />}
                        </div>
                        <div className="p-4">
                          {blog.is_trending && (
                            <div className="flex items-center gap-1 mb-2">
                              <Flame className="w-3 h-3 text-rose-500" />
                              <span className="text-xs font-bold text-rose-500">Trending</span>
                            </div>
                          )}

                          {Array.isArray(blog.tags) && blog.tags.length > 0 && (
                            <div className="flex flex-wrap gap-1 mb-2">
                              {blog.tags.slice(0, 2).map(t => (
                                <span key={t} className="text-xs text-brand-500 bg-brand-50 px-2 py-0.5 rounded-full">{t}</span>
                              ))}
                            </div>
                          )}

                          <h3 className="font-semibold text-gray-900 leading-snug group-hover:text-brand-500 transition-colors line-clamp-2 text-sm">
                            {blog.title}
                          </h3>

                          {excerpt && (
                            <p className="text-xs text-gray-500 mt-1.5 line-clamp-2 leading-relaxed">{excerpt}</p>
                          )}

                          <div className="flex items-center justify-between mt-3 text-xs text-gray-400">
                            <span className="font-medium text-gray-600 truncate max-w-[60%]">
                              {blog.author_name ?? "MediSasa Team"}
                            </span>
                            <div className="flex items-center gap-1 flex-shrink-0">
                              <Clock className="w-3 h-3" />
                              {date ? formatDate(date) : ""}
                            </div>
                          </div>
                        </div>
                      </Link>
                    );
                  })}
                </div>

                {/* Pagination */}
                {pagination && pagination.last_page > 1 && (
                  <div className="flex items-center justify-center gap-2 mt-8">
                    <button
                      disabled={page === 1}
                      onClick={() => setPage(p => p - 1)}
                      className="px-4 py-2 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
                      ← Prev
                    </button>
                    <span className="text-sm text-gray-500">Page {pagination.current_page} of {pagination.last_page}</span>
                    <button
                      disabled={page === pagination.last_page}
                      onClick={() => setPage(p => p + 1)}
                      className="px-4 py-2 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
                      Next →
                    </button>
                  </div>
                )}
              </>
            )}
          </div>

          {/* ── Sidebar ── */}
          <aside className="w-full lg:w-72 flex-shrink-0 space-y-6">
            {/* Trending now */}
            {trendingBlogs.length > 0 && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <div className="flex items-center gap-2 mb-4">
                  <Flame className="w-4 h-4 text-rose-500" />
                  <h3 className="font-bold text-gray-900 text-sm">Trending Now</h3>
                </div>
                <div className="space-y-3">
                  {trendingBlogs.map((blog, idx) => (
                    <Link key={blog.id} href={`/trending/${blog.slug}`}
                      className="flex items-start gap-3 group">
                      <span className="text-2xl font-black text-gray-100 leading-none w-7 flex-shrink-0">
                        {String(idx + 1).padStart(2, "0")}
                      </span>
                      <p className="text-xs font-semibold text-gray-700 leading-snug group-hover:text-rose-500 transition-colors line-clamp-2">
                        {blog.title}
                      </p>
                    </Link>
                  ))}
                </div>
              </div>
            )}

            {/* Tags cloud */}
            {tags.length > 0 && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                <h3 className="font-bold text-gray-900 text-sm mb-3">Browse by Topic</h3>
                <div className="flex flex-wrap gap-2">
                  {tags.map(t => (
                    <button key={t} onClick={() => handleTag(t)}
                      className={`text-xs font-semibold px-3 py-1.5 rounded-full transition-colors ${
                        selectedTag === t
                          ? "bg-rose-500 text-white"
                          : "bg-gray-100 text-gray-600 hover:bg-rose-50 hover:text-rose-600"
                      }`}>
                      {t}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </aside>
        </div>
      </div>

      <Footer />
    </main>
  );
}
