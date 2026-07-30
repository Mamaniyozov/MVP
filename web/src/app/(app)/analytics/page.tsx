"use client";

import { useState } from "react";
import { analyticsApi } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { StatCard } from "@/components/StatCard";
import { CategoryBreakdownChart } from "@/components/charts/CategoryBreakdownChart";
import { MonthlyTrendChart } from "@/components/charts/MonthlyTrendChart";
import { monthName } from "@/lib/format";

const now = new Date();

function shiftMonth(year: number, month: number, offset: number): [number, number] {
  const total = year * 12 + (month - 1) + offset;
  const y = Math.floor(total / 12);
  const m = (total % 12) + 1;
  return [y, m];
}

export default function AnalyticsPage() {
  const [[year, month], setPeriod] = useState<[number, number]>([now.getFullYear(), now.getMonth() + 1]);

  const breakdown = useAsync(() => analyticsApi.categoryBreakdown(month, year), [month, year]);
  const trend = useAsync(() => analyticsApi.monthlyTrend(6), []);
  const report = useAsync(() => analyticsApi.monthlyReport(month, year), [month, year]);

  return (
    <div>
      <PageHeader
        title="Tahlil"
        subtitle="Xarajat va daromadlaringiz bo'yicha oylik hisobot."
        action={
          <div className="flex items-center gap-2">
            <button
              type="button"
              className="btn-secondary px-3 py-1.5 text-sm"
              onClick={() => setPeriod(shiftMonth(year, month, -1))}
            >
              ←
            </button>
            <span className="min-w-[9rem] text-center text-sm font-medium text-ink dark:text-ink-dark">
              {monthName(month)} {year}
            </span>
            <button
              type="button"
              className="btn-secondary px-3 py-1.5 text-sm"
              onClick={() => setPeriod(shiftMonth(year, month, 1))}
            >
              →
            </button>
          </div>
        }
      />

      {report.data ? (
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
      ) : null}

      {report.data?.insights.length ? (
        <div className="mt-4 rounded-lg border border-accent/40 bg-accent-soft px-4 py-3 text-sm text-ink">
          {report.data.insights.join(" ")}
        </div>
      ) : null}

      {(breakdown.data?.[0] || report.data?.top_category_increase) ? (
        <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {breakdown.data?.[0] ? (
            <div className="card px-4 py-3.5">
              <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Eng katta xarajat kategoriyasi</p>
              <p className="mt-1 text-sm font-semibold text-ink dark:text-ink-dark">
                {breakdown.data[0].category} <span className="amount text-ink-muted">· {breakdown.data[0].percent}%</span>
              </p>
            </div>
          ) : null}
          {report.data?.top_category_increase ? (
            <div className="card px-4 py-3.5">
              <p className="text-xs text-ink-muted dark:text-ink-dark-muted">Eng ko&apos;p o&apos;sgan kategoriya</p>
              <p className="mt-1 text-sm font-semibold text-expense">
                {report.data.top_category_increase.name}{" "}
                <span className="amount">↑ {report.data.top_category_increase.percent.toFixed(0)}%</span>
              </p>
            </div>
          ) : null}
        </div>
      ) : null}

      <div className="mt-10 card p-6">
        <h2 className="font-display text-lg font-semibold text-ink dark:text-ink-dark">
          Kategoriya bo&apos;yicha xarajat
        </h2>
        <p className="mt-1 text-sm text-ink-muted">{monthName(month)} oyidagi xarajatlar taqsimoti.</p>

        <div className="mt-6">
          {breakdown.isLoading ? (
            <Spinner />
          ) : breakdown.error ? (
            <ErrorState message={breakdown.error} onRetry={breakdown.reload} />
          ) : breakdown.data && breakdown.data.length > 0 ? (
            <CategoryBreakdownChart rows={breakdown.data} />
          ) : (
            <EmptyState title="Bu oy uchun xarajat yo'q" />
          )}
        </div>
      </div>

      <div className="mt-6 card p-6">
        <h2 className="font-display text-lg font-semibold text-ink dark:text-ink-dark">6 oylik dinamika</h2>
        <p className="mt-1 text-sm text-ink-muted">Daromad va xarajatlaringiz oxirgi 6 oy davomida.</p>

        <div className="mt-4">
          {trend.isLoading ? (
            <Spinner />
          ) : trend.error ? (
            <ErrorState message={trend.error} onRetry={trend.reload} />
          ) : trend.data && trend.data.length > 0 ? (
            <MonthlyTrendChart rows={trend.data} />
          ) : (
            <EmptyState title="Ma'lumot yo'q" />
          )}
        </div>
      </div>
    </div>
  );
}
