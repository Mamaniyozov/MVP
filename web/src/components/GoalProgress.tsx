import Link from "next/link";
import { formatSum } from "@/lib/format";
import type { Goal } from "@/lib/types";

export function GoalProgress({ goal, linkToDetail = true }: { goal: Goal; linkToDetail?: boolean }) {
  const pct = Math.min(100, goal.progress_percent);
  const title = linkToDetail ? (
    <Link href={`/goals/${goal.id}`} className="font-medium text-ink hover:text-brand dark:text-ink-dark">
      {goal.name}
    </Link>
  ) : (
    <span className="font-medium text-ink dark:text-ink-dark">{goal.name}</span>
  );

  return (
    <div>
      <div className="flex items-baseline justify-between gap-2 text-sm">
        {title}
        <span className="amount shrink-0 text-ink-muted">{goal.progress_percent.toFixed(0)}%</span>
      </div>
      <div
        className="mt-2.5 h-2 overflow-hidden rounded-full bg-line dark:bg-line-dark"
        role="progressbar"
        aria-valuenow={Math.round(pct)}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full bg-grad-accent shadow-[0_0_8px_rgba(232,163,61,0.4)] transition-[width] duration-500 ease-out"
          style={{ width: `${pct}%` }}
        />
      </div>
      <p className="mt-1.5 amount text-xs text-ink-muted">
        {formatSum(goal.current_amount)} / {formatSum(goal.target_amount)}
      </p>
      {pct >= 50 ? (
        <p className="mt-2 text-xs font-medium text-accent">
          {pct >= 100 ? `"${goal.name}" maqsadiga yetdingiz! 🎉` : `${pct.toFixed(0)}% — maqsadga yaqinlashyapsiz!`}
        </p>
      ) : null}
    </div>
  );
}
