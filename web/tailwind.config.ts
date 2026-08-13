import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        paper: { DEFAULT: "#F0F3F6", dark: "#0F172A" },
        surface: { DEFAULT: "#F0F3F6", dark: "#1E293B" },
        line: { DEFAULT: "#F1F5F9", dark: "#334155" },
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
        panel: "24px",
      },
      boxShadow: {
        card: "9px 9px 16px rgba(163,177,198,0.6), -9px -9px 16px rgba(255,255,255, 0.6)",
        "card-hover": "12px 12px 20px rgba(163,177,198,0.7), -12px -12px 20px rgba(255,255,255, 0.8)",
        "btn-brand": "9px 9px 16px rgba(163,177,198,0.6), -9px -9px 16px rgba(255,255,255, 0.6)",
        glow: "0 0 0 1px rgba(15, 107, 76, 0.08), 0 12px 32px -8px rgba(15, 107, 76, 0.25)",
        panel: "9px 9px 16px rgba(163,177,198,0.6), -9px -9px 16px rgba(255,255,255, 0.6)",
        "panel-inset": "inset 5px 5px 10px rgba(163,177,198, 0.5), inset -5px -5px 10px rgba(255,255,255, 0.8)",
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
