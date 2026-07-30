import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        paper: { DEFAULT: "#F3F6F4", dark: "#0E1712" },
        surface: { DEFAULT: "#FFFFFF", dark: "#16211B" },
        line: { DEFAULT: "#DFE6E1", dark: "#263229" },
        ink: {
          DEFAULT: "#12231C",
          muted: "#5C6B63",
          dark: "#E9F1EC",
          "dark-muted": "#93A69B",
        },
        brand: {
          DEFAULT: "#0F6B4C",
          strong: "#0A4E38",
          soft: "#DCEEE4",
        },
        income: "#1E9C6B",
        expense: "#C4573B",
        accent: { DEFAULT: "#E8A33D", soft: "#FBEBD2" },
      },
      fontFamily: {
        display: ["var(--font-display)", "sans-serif"],
        body: ["var(--font-body)", "sans-serif"],
        mono: ["var(--font-mono)", "monospace"],
      },
      borderRadius: {
        card: "16px",
      },
      boxShadow: {
        card: "0 1px 2px rgba(18, 35, 28, 0.04), 0 8px 24px -12px rgba(18, 35, 28, 0.10)",
        "card-hover":
          "0 2px 4px rgba(18, 35, 28, 0.05), 0 16px 40px -12px rgba(18, 35, 28, 0.18)",
        "btn-brand":
          "0 1px 2px rgba(10, 78, 56, 0.3), 0 6px 16px -6px rgba(15, 107, 76, 0.45)",
        glow: "0 0 0 1px rgba(15, 107, 76, 0.08), 0 12px 32px -8px rgba(15, 107, 76, 0.25)",
      },
      backgroundImage: {
        "grad-brand": "linear-gradient(135deg, #0F6B4C 0%, #0A4E38 100%)",
        "grad-accent": "linear-gradient(90deg, #E8A33D 0%, #D98A1F 100%)",
      },
      keyframes: {
        "fade-up": {
          from: { opacity: "0", transform: "translateY(8px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        "fade-up": "fade-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) both",
      },
    },
  },
  plugins: [],
};

export default config;
