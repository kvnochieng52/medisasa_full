"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Link from "next/link";
import {
  ArrowLeft, Clock, Tag, TrendingUp, BookOpen,
  Flame, Eye, Loader2, AlertCircle,
} from "lucide-react";
import api, { getImageUrl } from "@/lib/api";

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

function formatDate(dateStr?: string): string {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-KE", {
    weekday: "long", day: "numeric", month: "long", year: "numeric",
  });
}

export default function BlogDetailPage() {
  const { slug } = useParams<{ slug: string }>();
  const router = useRouter();

  const [blog, setBlog] = useState<Blog | null>(null);
  const [related, setRelated] = useState<Blog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    api.get<{ success: boolean; data: { blog: Blog; related_blogs: Blog[] } }>(`/blogs/${slug}`)
      .then(res => {
        setBlog(res.data?.data?.blog ?? null);
        setRelated(res.data?.data?.related_blogs ?? []);
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }, [slug]);

  if (loading) return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="w-8 h-8 animate-spin text-rose-400" />
      </div>
    </main>
  );

  if (error || !blog) return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="flex items-center justify-center min-h-screen px-4">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="font-semibold text-gray-600 mb-4">Article not found</p>
          <Link href="/trending" className="inline-flex items-center gap-2 px-5 py-2.5 bg-rose-500 hover:bg-rose-600 text-white font-semibold text-sm rounded-xl transition-colors">
            ← Back to Trending
          </Link>
        </div>
      </div>
    </main>
  );

  const imageUrl = getImageUrl(blog.featured_image);
  const date = blog.published_at ?? blog.created_at;

  return (
    <main className="min-h-screen bg-gray-50">
      <Navbar />

      {/* Hero image */}
      <div className="relative bg-gray-900 pt-16">
        {imageUrl && (
          <img src={imageUrl} alt={blog.title} className="w-full h-64 sm:h-80 lg:h-96 object-cover opacity-70" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-gray-900/80 to-transparent" />

        <button onClick={() => router.back()}
          className="absolute top-20 left-4 w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors z-10">
          <ArrowLeft className="w-5 h-5 text-white" />
        </button>

        <div className="absolute bottom-0 left-0 right-0 px-4 pb-6 max-w-4xl mx-auto">
          {blog.is_trending && (
            <div className="flex items-center gap-1 mb-3">
              <Flame className="w-4 h-4 text-rose-400" />
              <span className="text-xs font-bold text-rose-400 uppercase tracking-wide">Trending</span>
            </div>
          )}
          <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white leading-tight">{blog.title}</h1>
        </div>
      </div>

      {/* Meta bar */}
      <div className="bg-white border-b border-gray-100 px-4 py-3">
        <div className="max-w-4xl mx-auto flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
          <span className="font-semibold text-gray-700">{blog.author_name ?? "Xyvra Team"}</span>
          {date && (
            <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> {formatDate(date)}</span>
          )}
          {blog.views_count !== undefined && blog.views_count > 0 && (
            <span className="flex items-center gap-1"><Eye className="w-3 h-3" /> {blog.views_count.toLocaleString()} views</span>
          )}
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-8 pb-16">
        <div className="flex flex-col lg:flex-row gap-8">

          {/* Article body */}
          <article className="flex-1 min-w-0">
            {/* Tags */}
            {Array.isArray(blog.tags) && blog.tags.length > 0 && (
              <div className="flex flex-wrap items-center gap-2 mb-6">
                <Tag className="w-3.5 h-3.5 text-gray-400" />
                {blog.tags.map(t => (
                  <Link key={t} href={`/trending?tag=${encodeURIComponent(t)}`}
                    className="text-xs font-semibold text-rose-600 bg-rose-50 px-2.5 py-1 rounded-full hover:bg-rose-100 transition-colors">
                    {t}
                  </Link>
                ))}
              </div>
            )}

            {/* Excerpt */}
            {blog.excerpt && (
              <p className="text-base text-gray-600 font-medium leading-relaxed mb-6 border-l-4 border-rose-300 pl-4 italic">
                {blog.excerpt}
              </p>
            )}

            {/* Content */}
            {blog.content && (
              <div
                className="prose prose-gray prose-sm sm:prose max-w-none"
                dangerouslySetInnerHTML={{ __html: blog.content }}
              />
            )}

            {/* Back link */}
            <div className="mt-10 pt-6 border-t border-gray-100">
              <Link href="/trending"
                className="inline-flex items-center gap-2 text-sm font-semibold text-rose-500 hover:text-rose-600 transition-colors">
                <ArrowLeft className="w-4 h-4" /> Back to Trending
              </Link>
            </div>
          </article>

          {/* Sidebar: related */}
          {related.length > 0 && (
            <aside className="w-full lg:w-64 flex-shrink-0">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sticky top-24">
                <div className="flex items-center gap-2 mb-4">
                  <TrendingUp className="w-4 h-4 text-rose-500" />
                  <h3 className="font-bold text-gray-900 text-sm">Related Articles</h3>
                </div>
                <div className="space-y-4">
                  {related.map(r => {
                    const img = getImageUrl(r.featured_image);
                    return (
                      <Link key={r.id} href={`/trending/${r.slug}`} className="flex gap-3 group">
                        <div className="w-14 h-14 rounded-xl flex-shrink-0 overflow-hidden bg-gray-100">
                          {img
                            ? <img src={img} alt={r.title} className="w-full h-full object-cover" />
                            : <BookOpen className="w-5 h-5 text-gray-300 m-auto mt-4" />}
                        </div>
                        <p className="text-xs font-semibold text-gray-700 leading-snug group-hover:text-rose-500 transition-colors line-clamp-3">
                          {r.title}
                        </p>
                      </Link>
                    );
                  })}
                </div>
              </div>
            </aside>
          )}
        </div>
      </div>

      <Footer />
    </main>
  );
}
