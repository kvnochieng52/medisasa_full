import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { ShieldCheck } from "lucide-react";

export const metadata: Metadata = {
  title: "Privacy Policy | MediSasa",
  description:
    "Learn how MediSasa collects, uses, and protects your personal and health information.",
};

const sections = [
  {
    title: "Information we collect",
    body: "We collect information you provide directly — such as your name, email, phone, and the details you submit when booking appointments, ordering medicine, or contacting providers. We also collect basic device and usage data to keep the service secure and improve it over time.",
  },
  {
    title: "How we use your information",
    body: "We use your information to deliver the services you request: helping you find providers, manage appointments, complete orders, and stay in touch with the care teams you connect with. We also use it to keep MediSasa safe, fix problems, and notify you of important updates.",
  },
  {
    title: "Sharing your information",
    body: "We only share your information with the providers and pharmacies you choose to interact with, with payment processors needed to complete transactions, and where required by law. We do not sell your personal data.",
  },
  {
    title: "Data security",
    body: "We use industry-standard security practices to protect your data, including encryption in transit and access controls for sensitive information. No system is perfectly secure, so we encourage you to use a strong password and keep your account details private.",
  },
  {
    title: "Your rights",
    body: "You can request access to, correction of, or deletion of your personal information at any time by contacting support@medisasa.co.ke. You can also update most details directly from your profile.",
  },
  {
    title: "Changes to this policy",
    body: "We may update this policy from time to time. If we make significant changes, we will notify you in the app or by email before they take effect.",
  },
];

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-16 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <ShieldCheck className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
              Privacy Policy
            </h1>
            <p className="text-sm text-gray-500">Last updated: June 2026</p>
          </div>
        </section>

        <section className="max-w-3xl mx-auto px-4 py-12">
          <p className="text-gray-600 leading-relaxed mb-10">
            Your privacy matters to us. This policy explains what information we
            collect when you use MediSasa, how we use it, and the choices you
            have. By using MediSasa, you agree to the practices described below.
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
              <h2 className="text-lg font-bold text-gray-900 mb-2">Contact us</h2>
              <p className="text-gray-600 leading-relaxed">
                Questions about this policy? Email{" "}
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
