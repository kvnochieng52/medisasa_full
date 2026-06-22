import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Briefcase, Mail } from "lucide-react";

export const metadata: Metadata = {
  title: "Careers | MediSasa",
  description:
    "Join MediSasa and help make healthcare more accessible across Kenya and beyond.",
};

const perks = [
  "Mission-driven team building products that improve health outcomes.",
  "Remote-friendly culture with flexible working hours.",
  "Health cover for you and your immediate family.",
  "Learning budget to grow your craft.",
];

export default function CareersPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-20 px-4">
          <div className="max-w-4xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <Briefcase className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-5">
              Careers at MediSasa
            </h1>
            <p className="text-lg text-gray-600 leading-relaxed">
              We&apos;re building the digital backbone of healthcare in the
              region. If you care about making care more accessible — and want
              to do the best work of your life — we&apos;d love to hear from you.
            </p>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-4 py-16">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Why work with us</h2>
          <ul className="space-y-3 mb-12">
            {perks.map((p) => (
              <li key={p} className="flex gap-3 text-gray-700">
                <span className="w-2 h-2 rounded-full bg-brand-500 mt-2 flex-shrink-0" />
                <span>{p}</span>
              </li>
            ))}
          </ul>

          <div className="bg-gray-50 border border-gray-100 rounded-2xl p-8 text-center">
            <h3 className="text-xl font-bold text-gray-900 mb-2">
              Open roles
            </h3>
            <p className="text-gray-600 mb-6 leading-relaxed">
              We don&apos;t have any open roles listed right now. If you think
              you&apos;d be a great fit, send your CV and a short note about
              what excites you.
            </p>
            <a
              href="mailto:careers@medisasa.co.ke"
              className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors"
            >
              <Mail className="w-4 h-4" />
              careers@medisasa.co.ke
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
