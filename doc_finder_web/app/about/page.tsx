import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Heart, ShieldCheck, Users, Stethoscope } from "lucide-react";

export const metadata: Metadata = {
  title: "About Us | MediSasa",
  description:
    "MediSasa connects patients with trusted healthcare providers, pharmacies, and support groups across Kenya.",
};

const values = [
  {
    icon: Heart,
    title: "Patient-first",
    text: "Every feature we build starts with the question: does this help someone get better care, faster?",
  },
  {
    icon: ShieldCheck,
    title: "Trust & safety",
    text: "Verified providers, secure records, and clear pricing — no surprises along your care journey.",
  },
  {
    icon: Users,
    title: "Community",
    text: "From support groups to mental health resources, healing is better when nobody walks alone.",
  },
  {
    icon: Stethoscope,
    title: "Quality care",
    text: "We partner only with licensed doctors, facilities, and pharmacies that meet our standards.",
  },
];

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-20 px-4">
          <div className="max-w-4xl mx-auto text-center">
            <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-5">
              About <span className="text-brand-500">MediSasa</span>
            </h1>
            <p className="text-lg text-gray-600 leading-relaxed">
              MediSasa is a healthcare platform that helps people find doctors,
              hospitals, pharmacies, and support groups — and book appointments
              in just a few taps. We believe quality care should be accessible
              to everyone, wherever they are.
            </p>
          </div>
        </section>

        <section className="max-w-5xl mx-auto px-4 py-16">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-3">Our mission</h2>
              <p className="text-gray-600 leading-relaxed">
                To make finding and accessing healthcare simple, transparent,
                and trustworthy. Whether you&apos;re looking for a specialist,
                ordering medicine, or seeking mental health support, MediSasa
                brings the right help to your fingertips.
              </p>
            </div>
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-3">Our story</h2>
              <p className="text-gray-600 leading-relaxed">
                Born in Nairobi and built for the wider region, MediSasa exists
                because too many people struggle to find the right care at the
                right time. We&apos;re a team of healthcare workers, engineers,
                and designers working to change that.
              </p>
            </div>
          </div>
        </section>

        <section className="bg-gray-50 py-16 px-4">
          <div className="max-w-5xl mx-auto">
            <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">
              What we stand for
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {values.map(({ icon: Icon, title, text }) => (
                <div
                  key={title}
                  className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100"
                >
                  <div className="w-11 h-11 rounded-xl bg-brand-50 flex items-center justify-center mb-4">
                    <Icon className="w-5 h-5 text-brand-500" />
                  </div>
                  <h3 className="font-semibold text-gray-900 mb-1.5">{title}</h3>
                  <p className="text-sm text-gray-600 leading-relaxed">{text}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
