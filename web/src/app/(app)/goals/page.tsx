"use client";

import Link from "next/link";
import { goalsApi, unwrapList } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { GoalProgress } from "@/components/GoalProgress";

export default function GoalsPage() {
  const list = useAsync(() => goalsApi.list().then(unwrapList), []);

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
