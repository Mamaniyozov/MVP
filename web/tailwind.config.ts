import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "media",
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
        card: "14px",
      },
      boxShadow: {
        card: "0 1px 2px rgba(18, 35, 28, 0.04), 0 8px 24px -12px rgba(18, 35, 28, 0.12)",
      },
    },
  },
  plugins: [],
};

export default config;
