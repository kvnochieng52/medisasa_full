import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Mail, Phone, MapPin, MessageSquare } from "lucide-react";

export const metadata: Metadata = {
  title: "Contact Us | MediSasa",
  description:
    "Get in touch with the MediSasa team — by email, phone, or in person at our Nairobi office.",
};

const channels = [
  {
    icon: Mail,
    title: "Email",
    value: "support@medisasa.co.ke",
    href: "mailto:support@medisasa.co.ke",
    sub: "We typically reply within one business day.",
  },
  {
    icon: Phone,
    title: "Phone",
    value: "+254 759 000 652",
    href: "tel:+254759000652",
    sub: "Mon–Fri, 8:00 AM – 6:00 PM EAT.",
  },
  {
    icon: MapPin,
    title: "Office",
    value: "Nairobi, Kenya",
    href: null,
    sub: "Visits by appointment only.",
  },
];

export default function ContactPage() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <Navbar />
      <main className="flex-1">
        <section className="bg-gradient-to-br from-[#e6f7fa] via-[#b3e8f0] to-white py-16 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-5">
              <MessageSquare className="w-6 h-6 text-brand-500" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-3">
              Contact Us
            </h1>
            <p className="text-gray-600 leading-relaxed">
              Have a question, a partnership idea, or feedback to share?
              We&apos;d love to hear from you.
            </p>
          </div>
        </section>

        <section className="max-w-5xl mx-auto px-4 py-12">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-12">
            {channels.map(({ icon: Icon, title, value, href, sub }) => (
              <div
                key={title}
                className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100"
              >
                <div className="w-11 h-11 rounded-xl bg-brand-50 flex items-center justify-center mb-4">
                  <Icon className="w-5 h-5 text-brand-500" />
                </div>
                <h3 className="font-semibold text-gray-900 mb-1">{title}</h3>
                {href ? (
                  <a
                    href={href}
                    className="text-brand-500 hover:text-brand-600 font-semibold text-sm break-words"
                  >
                    {value}
                  </a>
                ) : (
                  <p className="text-gray-700 font-semibold text-sm">{value}</p>
                )}
                <p className="text-xs text-gray-500 mt-2">{sub}</p>
              </div>
            ))}
          </div>

          <div className="bg-gray-50 border border-gray-100 rounded-2xl p-8 text-center">
            <h3 className="text-xl font-bold text-gray-900 mb-2">
              For healthcare providers
            </h3>
            <p className="text-gray-600 mb-6 leading-relaxed">
              Want to list your practice, hospital, or pharmacy on MediSasa?
              Email us at{" "}
              <a
                href="mailto:partners@medisasa.co.ke"
                className="text-brand-500 hover:text-brand-600 font-semibold"
              >
                partners@medisasa.co.ke
              </a>
              {" "}and our team will reach out.
            </p>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
