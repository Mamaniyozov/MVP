import { formatSum } from "@/lib/format";
import { ArrowUpRight, ArrowDownRight, Clock, TrendingUp, TrendingDown } from "lucide-react";

type Tone = "income" | "expense" | "brand";

const TONE: Record<
  Tone,
  { text: string; chipBg: string; bar: string; icon: React.ElementType }
> = {
  income: {
    text: "text-income",
    chipBg: "bg-income/10 text-income",
    bar: "from-income/60 to-income/0",
    icon: ArrowUpRight,
  },
  expense: {
    text: "text-expense",
    chipBg: "bg-expense/10 text-expense",
    bar: "from-expense/60 to-expense/0",
    icon: ArrowDownRight,
  },
  brand: {
    text: "text-brand dark:text-income",
    chipBg: "bg-brand/10 text-brand dark:bg-income/10 dark:text-income",
    bar: "from-brand/60 to-brand/0",
    icon: Clock,
  },
};

export function StatCard({
  label,
  value,
  tone = "brand",
  changePercent,
}: {
  label: string;
  value: string | number;
  tone?: Tone;
  changePercent?: number | null;
}) {
  const t = TONE[tone];
  const glowClass = tone === "income" ? "glow-income" : tone === "expense" ? "glow-expense" : "glow-brand";
  const Icon = t.icon;

  return (
    <div className={`card card-lift relative overflow-hidden px-5 py-5 ${glowClass}`}>
      <div
        aria-hidden
        className={`absolute inset-x-0 top-0 h-[3px] bg-gradient-to-r ${t.bar}`}
      />
      <div className="flex items-center justify-between">
        <p className="text-sm font-medium text-ink-muted dark:text-ink-dark-muted">{label}</p>
        <span
          aria-hidden
          className={`inline-flex h-9 w-9 items-center justify-center rounded-xl shadow-sm transition-transform duration-200 hover:scale-105 ${t.chipBg}`}
        >
          <Icon size={18} strokeWidth={1.5} />
        </span>
      </div>
      <p className={`amount mt-2 text-[1.75rem] font-semibold leading-tight tracking-tight ${t.text}`}>
        {formatSum(value)}
      </p>
      {typeof changePercent === "number" ? (
        <p
          className={`mt-2.5 inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors ${
            changePercent >= 0 ? "bg-income/10 text-income" : "bg-expense/10 text-expense"
          }`}
        >
          {changePercent >= 0 ? (
            <TrendingUp size={14} strokeWidth={2} aria-hidden />
          ) : (
            <TrendingDown size={14} strokeWidth={2} aria-hidden />
          )}
          {Math.abs(changePercent).toFixed(1)}% o&apos;tgan oyga nisbatan
        </p>
      ) : (
        <p className="mt-2.5 text-xs text-ink-muted dark:text-ink-dark-muted">
          o&apos;tgan oy ma&apos;lumoti yo&apos;q
        </p>
      )}
    </div>
  );
}

