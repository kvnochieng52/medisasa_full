"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookOpen, ChevronRight, Clock, Tag } from "lucide-react";
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
  author?: { name: string };
  created_at?: string;
  tags?: string[] | string | null;
  reading_time?: number;
  views_count?: number;
}

function BlogCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-card animate-pulse">
      <div className="h-44 bg-gray-200" />
      <div className="p-5 space-y-2">
        <div className="h-3 bg-gray-100 rounded w-1/3" />
        <div className="h-4 bg-gray-200 rounded w-full" />
        <div className="h-3 bg-gray-100 rounded w-4/5" />
        <div className="h-3 bg-gray-100 rounded w-2/3" />
      </div>
    </div>
  );
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-KE", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export default function LatestBlogs() {
  const [blogs, setBlogs] = useState<Blog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get("/blogs/latest-trends?per_page=3")
      .then((res) => {
        const data = res.data;
        const nested = data?.data;
        const list: Blog[] = Array.isArray(nested)
          ? nested
          : nested?.trending ?? nested?.recent ?? nested?.blogs ?? [];
        setBlogs(list.slice(0, 3));
      })
      .catch(() => {
        // fall through to show empty state
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <section className="py-12 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <div className="p-1.5 rounded-lg bg-teal-50">
                <BookOpen className="w-4 h-4 text-teal-500" />
              </div>
              <span className="text-sm font-medium text-teal-500 uppercase tracking-wide">
                Latest Trends
              </span>
            </div>
            <h2 className="section-title text-2xl">Health Insights & News</h2>
          </div>
          <Link
            href="/blogs"
            className="hidden sm:flex items-center gap-1 text-sm font-medium text-brand-500 hover:text-brand-600 transition-colors"
          >
            View All
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {loading
            ? Array.from({ length: 3 }).map((_, i) => <BlogCardSkeleton key={i} />)
            : blogs.length === 0
            ? (
              <div className="col-span-3 text-center py-12 text-gray-400">
                <BookOpen className="w-10 h-10 mx-auto mb-2 text-gray-200" />
                <p>No articles available right now.</p>
              </div>
            )
            : blogs.map((blog) => {
                const imageUrl = getImageUrl(blog.featured_image);
                const authorName =
                  blog.author_name ?? blog.author?.name ?? "Xyvra Team";
                const excerpt =
                  blog.excerpt ??
                  (blog.content ? truncate(blog.content, 100) : "");
                return (
                  <Link
                    key={blog.id}
                    href={`/blogs/${blog.slug}`}
                    className="bg-white rounded-2xl overflow-hidden shadow-card hover:shadow-card-hover transition-all duration-300 hover:-translate-y-0.5 group block"
                  >
                    {/* Image */}
                    <div className="h-44 bg-brand-50 overflow-hidden flex items-center justify-center">
                      {imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={imageUrl}
                          alt={blog.title}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        />
                      ) : (
                        <BookOpen className="w-10 h-10 text-brand-300" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="p-5">
                      {/* Tags */}
                      {Array.isArray(blog.tags) && blog.tags.length > 0 && (
                        <div className="flex items-center gap-1 mb-2 flex-wrap">
                          <Tag className="w-3 h-3 text-brand-400" />
                          {blog.tags.slice(0, 2).map((tag) => (
                            <span
                              key={tag}
                              className="text-xs text-brand-500 bg-brand-50 px-2 py-0.5 rounded-full"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>
                      )}

                      <h3 className="font-semibold text-gray-900 leading-snug group-hover:text-brand-500 transition-colors line-clamp-2">
                        {blog.title}
                      </h3>

                      {excerpt && (
                        <p className="text-sm text-gray-500 mt-2 line-clamp-2 leading-relaxed">
                          {excerpt}
                        </p>
                      )}

                      {/* Meta */}
                      <div className="flex items-center gap-3 mt-4 text-xs text-gray-400">
                        <span className="font-medium text-gray-600">{authorName}</span>
                        {blog.created_at && (
                          <>
                            <span>·</span>
                            <span className="flex items-center gap-1">
                              <Clock className="w-3 h-3" />
                              {formatDate(blog.created_at)}
                            </span>
                          </>
                        )}
                        {blog.reading_time && (
                          <>
                            <span>·</span>
                            <span>{blog.reading_time} min read</span>
                          </>
                        )}
                      </div>
                    </div>
                  </Link>
                );
              })}
        </div>

        {/* Mobile link */}
        <div className="sm:hidden mt-6 text-center">
          <Link href="/blogs" className="btn-outline text-sm inline-flex items-center gap-1">
            View All Articles
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}
