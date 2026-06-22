import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Cookie } from "lucide-react";

export const metadata: Metadata = {
  title: "Cookie Policy | MediSasa",
  description:
    "How and why MediSasa uses cookies and similar technologies on our website.",
};

const sections = [
  {
    title: "What are cookies?",
    body: "Cookies are small text files that a website stores in your browser. They help the site remember things like whether you're signed in and what you've added to your cart.",
  },
  {
    title: "How we use cookies",
    body: "We use essential cookies to keep you signed in, remember your cart, and keep MediSasa secure. We also use a small number of analytics cookies to understand how the site is used so we can improve it.",
  },
  {
    title: "Third-party cookies",
    body: "Some pages may include content from trusted third parties (for example, payment processors). Those services may set their own cookies, governed by their own privacy policies.",
  },
  {
    title: "Managing cookies",
    body: "You can clear or block cookies through your browser settings. Note that blocking essential cookies may break things like signing in or completing a purchase.",
  },
];

export default function CookiesPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-16 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <Cookie className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
              Cookie Policy
            </h1>
            <p className="text-sm text-gray-500">Last updated: June 2026</p>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-4 py-12">
          <p className="text-gray-600 leading-relaxed mb-10">
            This policy explains how MediSasa uses cookies and similar
            technologies when you visit our website.
          </p>

          <div className="space-y-8">
            {sections.map((s) => (
              <div key={s.title}>
                <h2 className="text-lg font-bold text-gray-900 mb-2">
                  {s.title}
                </h2>
                <p className="text-gray-600 leading-relaxed">{s.body}</p>
              </div>
            ))}

            <div className="border-t border-gray-100 pt-8">
              <h2 className="text-lg font-bold text-gray-900 mb-2">Questions?</h2>
              <p className="text-gray-600 leading-relaxed">
                Reach us at{" "}
                <a
                  href="mailto:support@medisasa.co.ke"
                  className="text-brand-500 hover:text-brand-600 font-semibold"
                >
                  support@medisasa.co.ke
                </a>
                .
              </p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
