"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { AnimatedBackground } from "@/components/AnimatedBackground";
import { useAuth } from "@/lib/auth/AuthContext";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) router.replace("/login");
  }, [isLoading, isAuthenticated, router]);

  if (isLoading || !isAuthenticated) {
    return <div className="flex min-h-screen items-center justify-center bg-paper dark:bg-paper-dark" />;
  }

  return (
    <div className="flex min-h-screen bg-paper dark:bg-paper-dark">
      <AnimatedBackground />
      <a href="#main" className="skip-link">
        Asosiy qismga o&apos;tish
      </a>
      <Sidebar />
      {/* pt-20 clears the fixed mobile bar; on lg the bar is gone. */}
      <main id="main" className="min-w-0 flex-1 overflow-y-auto px-4 pb-8 pt-20 sm:px-8 lg:px-12 lg:pt-8">
        <div className="mx-auto w-full max-w-5xl">{children}</div>
      </main>
    </div>
  );
}
