"use client";

import Link from "next/link";
import { goalsApi, unwrapList } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { GoalProgress } from "@/components/GoalProgress";
import { formatSum } from "@/lib/format";

export default function GoalsPage() {
  const list = useAsync(() => goalsApi.list().then(unwrapList), []);
  const totalSaved = (list.data ?? []).reduce((sum, g) => sum + Number(g.current_amount), 0);

  return (
    <div>
      <PageHeader
        title="Maqsadlar"
        subtitle="Jamg'arma maqsadlaringiz va ularga erishish jarayoni."
        action={
          <Link href="/goals/new" className="btn-primary">
            + Yangi maqsad
          </Link>
        }
      />

      {list.data && list.data.length > 0 ? (
        <div className="mb-6 grid grid-cols-2 gap-3 sm:max-w-sm">
          <div className="card px-4 py-3.5">
            <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Jami jamg&apos;arildi</p>
            <p className="amount mt-1 text-lg font-semibold text-brand dark:text-income">{formatSum(totalSaved)}</p>
          </div>
          <div className="card px-4 py-3.5">
            <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Faol maqsadlar</p>
            <p className="amount mt-1 text-lg font-semibold text-ink dark:text-ink-dark">{list.data.length} ta</p>
          </div>
        </div>
      ) : null}

      {list.isLoading ? (
        <Spinner />
      ) : list.error ? (
        <ErrorState message={list.error} onRetry={list.reload} />
      ) : list.data && list.data.length > 0 ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {list.data.map((goal) => (
            <div key={goal.id} className="card p-5">
              <GoalProgress goal={goal} />
              {goal.deadline ? (
                <p className="mt-3 text-xs text-ink-muted">Muddat: {goal.deadline}</p>
              ) : null}
            </div>
          ))}
        </div>
      ) : (
        <EmptyState
          title="Maqsad qo'shilmagan"
          description="Masalan: 'Mashina uchun jamg'arma' yoki 'Zaxira fond'."
          action={
            <Link href="/goals/new" className="btn-primary">
              Maqsad qo&apos;shish
            </Link>
          }
        />
      )}
    </div>
  );
}
