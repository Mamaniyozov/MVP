import { formatSum } from "@/lib/format";

type Tone = "income" | "expense" | "brand";

const TONE: Record<
  Tone,
  { text: string; chipBg: string; bar: string }
> = {
  income: {
    text: "text-income",
    chipBg: "bg-income/10 text-income",
    bar: "from-income/60 to-income/0",
  },
  expense: {
    text: "text-expense",
    chipBg: "bg-expense/10 text-expense",
    bar: "from-expense/60 to-expense/0",
  },
  brand: {
    text: "text-brand dark:text-income",
    chipBg: "bg-brand/10 text-brand dark:bg-income/10 dark:text-income",
    bar: "from-brand/60 to-brand/0",
  },
};

const TONE_ICON: Record<Tone, React.ReactNode> = {
  income: (
    <path d="M12 19V5m0 0l-6 6m6-6l6 6" strokeLinecap="round" strokeLinejoin="round" />
  ),
  expense: (
    <path d="M12 5v14m0 0l-6-6m6 6l6-6" strokeLinecap="round" strokeLinejoin="round" />
  ),
  brand: (
    <path
      d="M4 12a8 8 0 1116 0 8 8 0 01-16 0zm8-4v4l2.5 2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
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
  return (
    <div className="card card-lift relative overflow-hidden px-5 py-5">
      <div
        aria-hidden
        className={`absolute inset-x-0 top-0 h-[3px] bg-gradient-to-r ${t.bar}`}
      />
      <div className="flex items-center justify-between">
        <p className="text-sm font-medium text-ink-muted dark:text-ink-dark-muted">{label}</p>
        <span
          aria-hidden
          className={`inline-flex h-8 w-8 items-center justify-center rounded-lg ${t.chipBg}`}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
            {TONE_ICON[tone]}
          </svg>
        </span>
      </div>
      <p className={`amount mt-2 text-[1.75rem] font-semibold leading-tight tracking-tight ${t.text}`}>
        {formatSum(value)}
      </p>
      {typeof changePercent === "number" ? (
        <p
          className={`mt-2 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${
            changePercent >= 0 ? "bg-income/10 text-income" : "bg-expense/10 text-expense"
          }`}
        >
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden>
            {changePercent >= 0 ? (
              <path d="M4 15l8-8 8 8" strokeLinecap="round" strokeLinejoin="round" />
            ) : (
              <path d="M4 9l8 8 8-8" strokeLinecap="round" strokeLinejoin="round" />
            )}
          </svg>
          {Math.abs(changePercent).toFixed(1)}% o&apos;tgan oyga nisbatan
        </p>
      ) : (
        <p className="mt-2 text-xs text-ink-muted dark:text-ink-dark-muted">
          o&apos;tgan oy ma&apos;lumoti yo&apos;q
        </p>
      )}
    </div>
  );
}
