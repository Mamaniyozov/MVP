import type { Metadata, Viewport } from "next";
import { Space_Grotesk, Inter, IBM_Plex_Mono } from "next/font/google";
import { AuthProvider } from "@/lib/auth/AuthContext";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import "./globals.css";


const display = Space_Grotesk({
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  variable: "--font-display",
});

const body = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-body",
});

const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: "Hisob — shaxsiy moliya",
  description: "Xarajat, daromad, byudjet va jamg'armalarni bir joyda boshqaring.",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#F3F6F4" },
    { media: "(prefers-color-scheme: dark)", color: "#0E1712" },
  ],
};

// Runs before paint so the stored/OS theme applies with no flash of the
// wrong mode. Dark is the default look for Hisob; light is the opt-out.
const THEME_INIT_SCRIPT = `
  (function () {
    try {
      var stored = localStorage.getItem('hisob-theme');
      var theme = stored === 'light' || stored === 'dark' ? stored : 'dark';
      document.documentElement.classList.toggle('dark', theme === 'dark');
    } catch (e) {
      document.documentElement.classList.add('dark');
    }
  })();
`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz" className={`${display.variable} ${body.variable} ${mono.variable}`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
      </head>
      <body>
        <ErrorBoundary>
          <AuthProvider>{children}</AuthProvider>
        </ErrorBoundary>
      </body>

    </html>
  );
}
