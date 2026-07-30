"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { Logo } from "@/components/Logo";
import { ThemeToggle } from "@/components/ThemeToggle";
import { useAuth } from "@/lib/auth/AuthContext";
import {
  IconCard,
  IconChart,
  IconFlag,
  IconGrid,
  IconLedger,
  IconLogout,
  IconTag,
} from "./icons";

const NAV = [
  { href: "/dashboard", label: "Bosh sahifa", icon: IconGrid },
  { href: "/transactions", label: "Tranzaksiyalar", icon: IconLedger },
  { href: "/goals", label: "Maqsadlar", icon: IconFlag },
  { href: "/analytics", label: "Tahlil", icon: IconChart },
  { href: "/categories", label: "Kategoriyalar", icon: IconTag },
  { href: "/cards", label: "Kartalar", icon: IconCard },
];

export function Sidebar() {
  const pathname = usePathname();
  const { email, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const initial = (email?.[0] ?? "?").toUpperCase();

  // Navigating closes the drawer; on desktop it is always open and this is a no-op.
  useEffect(() => setIsOpen(false), [pathname]);

  useEffect(() => {
    if (!isOpen) return;
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") setIsOpen(false);
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [isOpen]);

  const panel = (
    <>
      <div className="px-2">
        <Logo />
      </div>

      <nav className="mt-8 flex flex-1 flex-col gap-1 overflow-y-auto">
        {NAV.map((item) => {
          const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-[background-color,color,transform] duration-200 ${
                active
                  ? "bg-brand-soft text-brand-strong shadow-[inset_0_1px_0_rgba(255,255,255,0.6)] dark:bg-brand/20 dark:text-white dark:shadow-none"
                  : "text-ink-muted hover:translate-x-0.5 hover:bg-paper hover:text-ink dark:hover:bg-white/5 dark:hover:text-ink-dark"
              }`}
            >
              <span
                aria-hidden
                className={`absolute left-0 top-1/2 h-5 w-[3px] -translate-y-1/2 rounded-r-full bg-brand transition-opacity duration-200 dark:bg-income ${
                  active ? "opacity-100" : "opacity-0 group-hover:opacity-40"
                }`}
              />
              <Icon
                className={`h-[18px] w-[18px] shrink-0 transition-colors duration-200 ${
                  active ? "text-brand dark:text-income" : "text-ink-muted group-hover:text-ink dark:group-hover:text-ink-dark"
                }`}
              />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-4 flex items-center gap-2.5 rounded-xl border border-line bg-paper/60 px-3 py-2.5 dark:border-line-dark dark:bg-white/[0.03]">
        <span
          aria-hidden
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-grad-brand text-xs font-semibold text-white"
        >
          {initial}
        </span>
        <span className="min-w-0 flex-1 truncate text-xs text-ink-muted" title={email ?? undefined}>
          {email}
        </span>
        <ThemeToggle />
        <button
          type="button"
          onClick={logout}
          className="cursor-pointer rounded-md p-1.5 text-ink-muted transition-colors duration-200 hover:bg-expense/10 hover:text-expense"
          aria-label="Chiqish"
          title="Chiqish"
        >
          <IconLogout className="h-[18px] w-[18px]" />
        </button>
      </div>
    </>
  );

  return (
    <>
      {/* Mobile: a compact bar; the nav itself lives in the drawer below. */}
      <header className="fixed inset-x-0 top-0 z-30 flex h-14 items-center justify-between border-b border-line bg-surface/90 px-4 backdrop-blur-sm dark:border-line-dark dark:bg-surface-dark/90 lg:hidden">
        <Logo />
        <button
          type="button"
          onClick={() => setIsOpen(true)}
          className="flex h-9 w-9 cursor-pointer items-center justify-center rounded-lg text-ink-muted transition-colors duration-200 hover:bg-paper hover:text-ink dark:hover:bg-white/5 dark:hover:text-ink-dark"
          aria-label="Menyuni ochish"
          aria-expanded={isOpen}
          aria-controls="app-nav"
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
            <path d="M3 6h14M3 10h14M3 14h14" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
        </button>
      </header>
      {isOpen ? (
        <button
          type="button"
          onClick={() => setIsOpen(false)}
          className="fixed inset-0 z-40 cursor-default bg-ink/40 backdrop-blur-[2px] lg:hidden"
          aria-label="Menyuni yopish"
        />
      ) : null}

      <aside
        id="app-nav"
        className={`fixed inset-y-0 left-0 z-50 flex h-screen w-64 shrink-0 flex-col overflow-hidden border-r border-line bg-surface px-4 py-6 transition-transform duration-300 dark:border-line-dark dark:bg-surface-dark lg:sticky lg:top-0 lg:z-auto lg:translate-x-0 lg:bg-surface/80 lg:backdrop-blur-sm lg:dark:bg-surface-dark/80 ${
          isOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {panel}
      </aside>
    </>
  );
}
