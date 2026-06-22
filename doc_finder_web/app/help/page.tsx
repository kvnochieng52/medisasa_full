import type { Metadata } from "next";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import {
  LifeBuoy, Search, Calendar, ShoppingBag, UserCircle, Mail, Phone,
} from "lucide-react";

export const metadata: Metadata = {
  title: "Help Center | MediSasa",
  description:
    "Find answers to common questions about MediSasa — booking appointments, ordering medicine, managing your account, and more.",
};

const topics = [
  {
    icon: Search,
    title: "Finding care",
    body: "Search for doctors, hospitals, pharmacies, and support groups. Filter by specialty, location, or insurance to find the right fit.",
  },
  {
    icon: Calendar,
    title: "Booking appointments",
    body: "Pick a doctor, choose an available slot, and confirm. You'll receive a reminder before your visit.",
  },
  {
    icon: ShoppingBag,
    title: "Pharmacy orders",
    body: "Add medicines to your cart, complete checkout, and track delivery to your door.",
  },
  {
    icon: UserCircle,
    title: "Managing your account",
    body: "Update your profile, change your password, or switch account type from your profile page.",
  },
];

const faqs = [
  {
    q: "How do I reset my password?",
    a: "Click 'Forgot Password?' on the login page, enter your email, and follow the 4-digit code we send you to set a new password.",
  },
  {
    q: "Can I cancel an appointment?",
    a: "Yes. Go to Appointments in your dashboard, open the appointment, and tap Cancel. Cancellations made well ahead of time are easiest on providers.",
  },
  {
    q: "How are providers verified?",
    a: "Every doctor and facility submits credentials that our team reviews before they can appear on MediSasa.",
  },
  {
    q: "Is my health information private?",
    a: "Yes. We use encryption and strict access controls. See our Privacy Policy for details.",
  },
];

export default function HelpPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-16 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <LifeBuoy className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
              Help Center
            </h1>
            <p className="text-gray-600 leading-relaxed">
              Find quick answers to common questions. Can&apos;t find what
              you&apos;re looking for? Get in touch.
            </p>
          </div>
        </section>

        <section className="max-w-5xl mx-auto px-4 py-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Browse topics</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 mb-16">
            {topics.map(({ icon: Icon, title, body }) => (
              <div
                key={title}
                className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100"
              >
                <div className="w-11 h-11 rounded-xl bg-brand-50 flex items-center justify-center mb-4">
                  <Icon className="w-5 h-5 text-brand-500" />
                </div>
                <h3 className="font-semibold text-gray-900 mb-1.5">{title}</h3>
                <p className="text-sm text-gray-600 leading-relaxed">{body}</p>
              </div>
            ))}
          </div>

          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Frequently asked questions
          </h2>
          <div className="space-y-4 mb-16">
            {faqs.map((f) => (
              <details
                key={f.q}
                className="group bg-white p-5 rounded-xl border border-gray-100 shadow-sm"
              >
                <summary className="cursor-pointer font-semibold text-gray-900 list-none flex items-center justify-between">
                  {f.q}
                  <span className="text-brand-500 group-open:rotate-45 transition-transform text-xl leading-none">
                    +
                  </span>
                </summary>
                <p className="text-sm text-gray-600 leading-relaxed mt-3">
                  {f.a}
                </p>
              </details>
            ))}
          </div>

          <div className="bg-gray-50 border border-gray-100 rounded-2xl p-8 text-center">
            <h3 className="text-xl font-bold text-gray-900 mb-2">
              Still need help?
            </h3>
            <p className="text-gray-600 mb-6">
              Our support team is here for you.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <Link
                href="/contact"
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-sm transition-colors"
              >
                <Mail className="w-4 h-4" />
                Contact Support
              </Link>
              <a
                href="tel:+254700000000"
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-white border border-gray-200 hover:border-brand-400 text-gray-700 font-semibold text-sm transition-colors"
              >
                <Phone className="w-4 h-4" />
                +254 700 000 000
              </a>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
