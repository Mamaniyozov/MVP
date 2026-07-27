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
      <div className="mt-2.5 h-2 overflow-hidden rounded-full bg-line dark:bg-line-dark">
        <div
          className="h-full rounded-full bg-accent transition-[width]"
          style={{ width: `${pct}%` }}
        />
      </div>
      <p className="mt-1.5 amount text-xs text-ink-muted">
        {formatSum(goal.current_amount)} / {formatSum(goal.target_amount)}
      </p>
    </div>
  );
}
