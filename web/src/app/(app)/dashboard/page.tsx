"use client";

import Link from "next/link";
import { Lightbulb } from "lucide-react";
import { analyticsApi, goalsApi, transactionsApi, unwrapList } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { useLookups } from "@/lib/hooks/useLookups";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { StatCard } from "@/components/StatCard";
import { TransactionRow } from "@/components/TransactionRow";
import { GoalProgress } from "@/components/GoalProgress";
import { formatSum, monthName } from "@/lib/format";

const today = new Date();

export default function DashboardPage() {
  const report = useAsync(() => analyticsApi.monthlyReport(today.getMonth() + 1, today.getFullYear()), []);
  const breakdown = useAsync(() => analyticsApi.categoryBreakdown(today.getMonth() + 1, today.getFullYear()), []);
  const recent = useAsync(() => transactionsApi.list({ page: 1 }), []);
  const goals = useAsync(() => goalsApi.list().then(unwrapList), []);
  const { categoryName, cardName } = useLookups();

  const income = report.data ? Number(report.data.current_month.income) : 0;
  const expense = report.data ? Number(report.data.current_month.expense) : 0;
  const savingsRate = income > 0 ? ((income - expense) / income) * 100 : null;
  const biggestCategory = breakdown.data?.[0] ?? null;
  const avgDailySpend = expense > 0 ? expense / today.getDate() : 0;

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
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          <div className="card card-lift relative col-span-2 overflow-hidden px-6 py-6">
            <div
              aria-hidden
              className="pointer-events-none absolute inset-0 bg-gradient-to-br from-brand/[0.03] via-transparent to-transparent dark:from-income/5"
            />
            <p className="relative text-sm font-medium text-ink-muted dark:text-ink-dark-muted">
              Bu oy jamg&apos;arma
            </p>
            <p className="amount relative mt-2 font-display text-4xl font-semibold leading-none tracking-tight text-brand dark:text-income sm:text-[2.75rem]">
              {formatSum(report.data.current_month.savings)}
            </p>
            {typeof report.data.change_percent?.savings === "number" ? (
              <p
                className={`relative mt-3 inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${
                  report.data.change_percent.savings >= 0
                    ? "bg-income/10 text-income"
                    : "bg-expense/10 text-expense"
                }`}
              >
                {report.data.change_percent.savings >= 0 ? "↑" : "↓"}{" "}
                {Math.abs(report.data.change_percent.savings).toFixed(1)}% o&apos;tgan oyga nisbatan
              </p>
            ) : null}
            {report.data.insights.length ? (
              <div className="relative mt-5 flex items-start gap-2.5 border-t border-line pt-4 text-sm text-ink-muted dark:border-line-dark dark:text-ink-dark-muted">
                <Lightbulb size={16} strokeWidth={1.5} className="mt-0.5 shrink-0 text-accent" aria-hidden />
                <span>{report.data.insights.join(" ")}</span>
              </div>
            ) : null}
          </div>

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
        </div>
      )}

      {report.data ? (
        <div className="mt-4 grid grid-cols-3 gap-3">
          <div className="card px-4 py-3.5">
            <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Jamg&apos;arma foizi</p>
            <p className="amount mt-1 text-lg font-semibold text-ink dark:text-ink-dark">
              {savingsRate === null ? "—" : `${savingsRate.toFixed(0)}%`}
            </p>
          </div>
          <div className="card px-4 py-3.5">
            <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Eng katta kategoriya</p>
            <p className="mt-1 truncate text-sm font-semibold text-ink dark:text-ink-dark">
              {breakdown.isLoading ? "…" : biggestCategory ? biggestCategory.category : "—"}
            </p>
            {biggestCategory ? (
              <p className="amount text-xs text-ink-muted">{formatSum(biggestCategory.total)}</p>
            ) : null}
          </div>
          <div className="card px-4 py-3.5">
            <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Kunlik o&apos;rtacha xarajat</p>
            <p className="amount mt-1 text-lg font-semibold text-ink dark:text-ink-dark">{formatSum(avgDailySpend)}</p>
          </div>
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
