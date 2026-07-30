"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
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
  const initial = (email?.[0] ?? "?").toUpperCase();

  return (
    <aside className="flex h-screen w-64 shrink-0 flex-col border-r border-line bg-surface/80 px-4 py-6 backdrop-blur-sm dark:border-line-dark dark:bg-surface-dark/80">
      <div className="px-2">
        <Logo />
      </div>

      <nav className="mt-8 flex flex-1 flex-col gap-1">
        {NAV.map((item) => {
          const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200 ${
                active
                  ? "bg-brand-soft text-brand-strong shadow-[inset_0_1px_0_rgba(255,255,255,0.6)] dark:bg-brand/20 dark:text-white dark:shadow-none"
                  : "text-ink-muted hover:translate-x-0.5 hover:bg-paper hover:text-ink dark:hover:bg-white/5 dark:hover:text-ink-dark"
              }`}
            >
              <span
                aria-hidden
                className={`absolute left-0 top-1/2 h-5 w-[3px] -translate-y-1/2 rounded-r-full bg-brand transition-all duration-200 dark:bg-income ${
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
    </aside>
  );
}
