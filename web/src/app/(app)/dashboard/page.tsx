"use client";

import Link from "next/link";
import { analyticsApi, goalsApi, transactionsApi, unwrapList } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { useLookups } from "@/lib/hooks/useLookups";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { StatCard } from "@/components/StatCard";
import { TransactionRow } from "@/components/TransactionRow";
import { GoalProgress } from "@/components/GoalProgress";
import { monthName } from "@/lib/format";

const today = new Date();

export default function DashboardPage() {
  const report = useAsync(() => analyticsApi.monthlyReport(today.getMonth() + 1, today.getFullYear()), []);
  const recent = useAsync(() => transactionsApi.list({ page: 1 }), []);
  const goals = useAsync(() => goalsApi.list().then(unwrapList), []);
  const { categoryName, cardName } = useLookups();

  return (
    <div>
      <PageHeader
        title="Bosh sahifa"
        subtitle={`${monthName(today.getMonth() + 1)} ${today.getFullYear()} holati`}
        action={
          <Link href="/transactions/new" className="btn-primary">
            + Yangi tranzaksiya
          </Link>
        }
      />

      {report.isLoading ? (
        <Spinner />
      ) : report.error || !report.data ? (
        <ErrorState message={report.error ?? "Ma'lumot topilmadi"} onRetry={report.reload} />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <StatCard
            label="Daromad"
            value={report.data.current_month.income}
            tone="income"
            changePercent={report.data.change_percent?.income ?? null}
          />
          <StatCard
            label="Xarajat"
            value={report.data.current_month.expense}
            tone="expense"
            changePercent={report.data.change_percent?.expense ?? null}
          />
          <StatCard
            label="Jamg'arma"
            value={report.data.current_month.savings}
            tone="brand"
            changePercent={report.data.change_percent?.savings ?? null}
          />
        </div>
      )}

      {report.data?.insights.length ? (
        <div className="mt-4 rounded-lg border border-accent/40 bg-accent-soft px-4 py-3 text-sm text-ink">
          {report.data.insights.join(" ")}
        </div>
      ) : null}

      <div className="mt-10 grid grid-cols-1 gap-8 lg:grid-cols-[1.4fr_1fr]">
        <section>
          <div className="mb-3 flex items-center justify-between">
            <h2 className="font-display text-lg font-semibold text-ink dark:text-ink-dark">
              So&apos;nggi tranzaksiyalar
            </h2>
            <Link href="/transactions" className="text-sm font-medium text-brand hover:underline">
              Barchasi
            </Link>
          </div>

          {recent.isLoading ? (
            <Spinner />
          ) : recent.error ? (
            <ErrorState message={recent.error} onRetry={recent.reload} />
          ) : recent.data && recent.data.results.length > 0 ? (
            <div className="card divide-y divide-line px-3 dark:divide-line-dark">
              {recent.data.results.slice(0, 6).map((tx) => (
                <TransactionRow
                  key={tx.id}
                  transaction={tx}
                  categoryName={categoryName(tx.category)}
                  cardName={cardName(tx.card)}
                />
              ))}
            </div>
          ) : (
            <EmptyState
              title="Hali tranzaksiya yo'q"
              description="Birinchi xarajat yoki daromadingizni qo'shing."
              action={
                <Link href="/transactions/new" className="btn-primary">
                  Tranzaksiya qo&apos;shish
                </Link>
              }
            />
          )}
        </section>

        <section>
          <div className="mb-3 flex items-center justify-between">
            <h2 className="font-display text-lg font-semibold text-ink dark:text-ink-dark">Maqsadlar</h2>
            <Link href="/goals" className="text-sm font-medium text-brand hover:underline">
              Barchasi
            </Link>
          </div>

          {goals.isLoading ? (
            <Spinner />
          ) : goals.error ? (
            <ErrorState message={goals.error} onRetry={goals.reload} />
          ) : goals.data && goals.data.length > 0 ? (
            <div className="flex flex-col gap-3">
              {goals.data.slice(0, 3).map((goal) => (
                <div key={goal.id} className="card px-4 py-4">
                  <GoalProgress goal={goal} />
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              title="Maqsad qo'shilmagan"
              description="Jamg'arma maqsadingizni belgilang."
              action={
                <Link href="/goals/new" className="btn-primary">
                  Maqsad qo&apos;shish
                </Link>
              }
            />
          )}
        </section>
      </div>
    </div>
  );
}
