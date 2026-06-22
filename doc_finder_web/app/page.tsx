import Navbar from "@/components/Navbar";
import HeroSection from "@/components/home/HeroSection";
import FeaturedDoctors from "@/components/home/FeaturedDoctors";
import LatestMedicines from "@/components/home/LatestMedicines";
import MentalHealthSection from "@/components/home/MentalHealthSection";
import Trending from "@/components/home/Trending";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="min-h-screen">
      <Navbar />
      <HeroSection />
      <FeaturedDoctors />
      <LatestMedicines />
      <MentalHealthSection />
      <Trending />
      <Footer />
    </main>
  );
}
