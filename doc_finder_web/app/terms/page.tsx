import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { FileText } from "lucide-react";

export const metadata: Metadata = {
  title: "Terms of Service | MediSasa",
  description:
    "The terms that govern your use of MediSasa, our website, and our services.",
};

const sections = [
  {
    title: "1. Acceptance of terms",
    body: "By creating an account or using MediSasa, you agree to be bound by these terms. If you do not agree, please do not use the service.",
  },
  {
    title: "2. Who can use MediSasa",
    body: "You must be at least 18 years old to create an account. If you are accessing the service on behalf of a minor, you confirm that you are their legal guardian.",
  },
  {
    title: "3. The service",
    body: "MediSasa is a platform that connects patients with healthcare providers, pharmacies, and related services. We facilitate connections — we are not a healthcare provider and we do not deliver medical advice ourselves. Any decisions about your health remain between you and your provider.",
  },
  {
    title: "4. Your account",
    body: "You are responsible for the information in your account and for keeping your password secure. Notify us immediately of any unauthorised access.",
  },
  {
    title: "5. Payments and refunds",
    body: "Some services on MediSasa require payment. Charges, applicable taxes, and refund eligibility are shown before you complete a transaction. Disputes about a specific provider, pharmacy, or order should be raised through our support team.",
  },
  {
    title: "6. Acceptable use",
    body: "You agree not to misuse the service — including by attempting to disrupt it, accessing data you don't have rights to, or using it to harass others. We may suspend or terminate accounts that violate these rules.",
  },
  {
    title: "7. Provider and pharmacy listings",
    body: "We work to verify the providers and pharmacies listed on MediSasa, but we cannot guarantee outcomes. Ratings and reviews reflect the opinions of users, not MediSasa.",
  },
  {
    title: "8. Limitation of liability",
    body: "To the maximum extent permitted by law, MediSasa is not liable for indirect, incidental, or consequential damages arising out of your use of the service.",
  },
  {
    title: "9. Changes to these terms",
    body: "We may update these terms occasionally. We'll notify you of meaningful changes — continued use after changes means you accept the updated terms.",
  },
  {
    title: "10. Governing law",
    body: "These terms are governed by the laws of Kenya. Any disputes will be resolved in the courts of Kenya unless otherwise required by applicable law.",
  },
];

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-16 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <FileText className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
              Terms of Service
            </h1>
            <p className="text-sm text-gray-500">Last updated: June 2026</p>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-4 py-12">
          <p className="text-gray-600 leading-relaxed mb-10">
            These Terms of Service govern your use of MediSasa. Please read them
            carefully — they describe what you can expect from us, and what we
            expect from you.
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
              <h2 className="text-lg font-bold text-gray-900 mb-2">Contact</h2>
              <p className="text-gray-600 leading-relaxed">
                Questions about these terms? Email{" "}
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
