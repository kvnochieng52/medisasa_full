import type { Config } from "tailwindcss";
import typography from "@tailwindcss/typography";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  "#e6f7fa",
          100: "#cceff5",
          200: "#99dfeb",
          300: "#66cfe1",
          400: "#33bfd7",
          500: "#008faf",
          600: "#00728c",
          700: "#005669",
          800: "#003946",
          900: "#001d23",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      backgroundImage: {
        "hero-gradient":
          "linear-gradient(135deg, #e6f7fa 0%, #b3e8f0 40%, #ffffff 100%)",
        "hero-gradient-dark":
          "linear-gradient(135deg, #0f0f23 0%, #16213e 50%, #1a1a2e 100%)",
      },
      boxShadow: {
        card: "0 4px 20px rgba(0, 0, 0, 0.08)",
        "card-hover": "0 8px 30px rgba(0, 143, 175, 0.2)",
      },
    },
  },
  plugins: [typography],
};

export default config;
