import type { Metadata } from "next";
import "./globals.css";
import { Toaster } from "react-hot-toast";
import Providers from "./providers";

export const metadata: Metadata = {
  title: "MediSasa | Find Doctors, Hospitals & Pharmacies",
  description:
    "Find qualified doctors, hospitals, pharmacies, and support groups near you. Book appointments and get healthcare delivered.",
  keywords: "medisasa, doctor finder, healthcare, hospital, pharmacy, appointments, telemedicine",
  applicationName: "MediSasa",
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased">
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              borderRadius: "12px",
              background: "#1a202c",
              color: "#fff",
            },
            success: {
              iconTheme: { primary: "#008faf", secondary: "#fff" },
            },
          }}
        />
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
