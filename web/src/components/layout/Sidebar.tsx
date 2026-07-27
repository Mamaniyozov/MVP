"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Logo } from "@/components/Logo";
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

  return (
    <aside className="flex h-screen w-64 shrink-0 flex-col border-r border-line bg-surface px-4 py-6 dark:border-line-dark dark:bg-surface-dark">
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
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                active
                  ? "bg-brand-soft text-brand-strong dark:bg-brand/20 dark:text-white"
                  : "text-ink-muted hover:bg-paper hover:text-ink dark:hover:bg-white/5 dark:hover:text-ink-dark"
              }`}
            >
              <Icon className="h-[18px] w-[18px] shrink-0" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-4 flex items-center justify-between gap-2 border-t border-line px-2 pt-4 dark:border-line-dark">
        <span className="truncate text-xs text-ink-muted" title={email ?? undefined}>
          {email}
        </span>
        <button
          type="button"
          onClick={logout}
          className="rounded-md p-1.5 text-ink-muted transition-colors hover:bg-expense/10 hover:text-expense"
          aria-label="Chiqish"
          title="Chiqish"
        >
          <IconLogout className="h-[18px] w-[18px]" />
        </button>
      </div>
    </aside>
  );
}
