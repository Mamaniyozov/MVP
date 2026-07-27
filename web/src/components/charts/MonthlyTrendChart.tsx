"use client";

import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { CHART_AXIS_COLOR, CHART_GRID_COLOR, EXPENSE_COLOR, INCOME_COLOR } from "@/lib/chartPalette";
import { formatSum, monthLabel } from "@/lib/format";
import type { MonthlyTrendRow } from "@/lib/types";

function CustomTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: { value: number; dataKey: string; color: string }[];
  label?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="card px-3 py-2 text-xs shadow-card">
      <p className="font-medium text-ink dark:text-ink-dark">{monthLabel(label ?? "")}</p>
      {payload.map((entry) => (
        <p key={entry.dataKey} className="amount mt-0.5" style={{ color: entry.color }}>
          {entry.dataKey === "income" ? "Daromad" : "Xarajat"}: {formatSum(entry.value)}
        </p>
      ))}
    </div>
  );
}

export function MonthlyTrendChart({ rows }: { rows: MonthlyTrendRow[] }) {
  const data = rows.map((r) => ({ ...r, income: Number(r.income), expense: Number(r.expense) }));

  return (
    <ResponsiveContainer width="100%" height={280}>
      <LineChart data={data} margin={{ top: 8, right: 12, bottom: 0, left: 0 }}>
        <CartesianGrid vertical={false} stroke={CHART_GRID_COLOR} />
        <XAxis
          dataKey="month"
          tickFormatter={monthLabel}
          tickLine={false}
          axisLine={{ stroke: CHART_GRID_COLOR }}
          tick={{ fill: CHART_AXIS_COLOR, fontSize: 12.5 }}
        />
        <YAxis tickLine={false} axisLine={false} tick={{ fill: CHART_AXIS_COLOR, fontSize: 12.5 }} width={56} />
        <Tooltip content={<CustomTooltip />} cursor={{ stroke: CHART_GRID_COLOR }} />
        <Legend
          verticalAlign="top"
          height={32}
          formatter={(value) => (
            <span className="text-xs text-ink-muted">{value === "income" ? "Daromad" : "Xarajat"}</span>
          )}
        />
        <Line
          type="monotone"
          dataKey="income"
          name="income"
          stroke={INCOME_COLOR}
          strokeWidth={2}
          dot={{ r: 4, strokeWidth: 0, fill: INCOME_COLOR }}
          activeDot={{ r: 5 }}
          isAnimationActive={false}
        />
        <Line
          type="monotone"
          dataKey="expense"
          name="expense"
          stroke={EXPENSE_COLOR}
          strokeWidth={2}
          dot={{ r: 4, strokeWidth: 0, fill: EXPENSE_COLOR }}
          activeDot={{ r: 5 }}
          isAnimationActive={false}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
