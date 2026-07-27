import { formatSum } from "@/lib/format";

type Tone = "income" | "expense" | "brand";

const TONE_TEXT: Record<Tone, string> = {
  income: "text-income",
  expense: "text-expense",
  brand: "text-brand",
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
  return (
    <div className="card px-5 py-5">
      <p className="text-sm text-ink-muted">{label}</p>
      <p className={`amount mt-2 text-2xl font-semibold ${TONE_TEXT[tone]}`}>{formatSum(value)}</p>
      {typeof changePercent === "number" ? (
        <p className={`mt-1.5 text-xs font-medium ${changePercent >= 0 ? "text-income" : "text-expense"}`}>
          {changePercent >= 0 ? "▲" : "▼"} {Math.abs(changePercent).toFixed(1)}% o&apos;tgan oyga nisbatan
        </p>
      ) : (
        <p className="mt-1.5 text-xs text-ink-muted">o&apos;tgan oy ma&apos;lumoti yo&apos;q</p>
      )}
    </div>
  );
}
