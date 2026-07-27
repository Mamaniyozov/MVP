"use client";

import { Bar, BarChart, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { CATEGORICAL_PALETTE, CHART_GRID_COLOR, OTHER_SLOT_COLOR } from "@/lib/chartPalette";
import { formatSum } from "@/lib/format";
import type { CategoryBreakdownRow } from "@/lib/types";

const MAX_SLOTS = 8;

function foldIntoOther(rows: CategoryBreakdownRow[]): CategoryBreakdownRow[] {
  if (rows.length <= MAX_SLOTS) return rows;
  const head = rows.slice(0, MAX_SLOTS - 1);
  const tail = rows.slice(MAX_SLOTS - 1);
  const otherTotal = tail.reduce((sum, r) => sum + Number(r.total), 0);
  const otherPercent = tail.reduce((sum, r) => sum + r.percent, 0);
  return [...head, { category: "Boshqa", total: String(otherTotal), percent: Math.round(otherPercent * 100) / 100 }];
}

function CustomTooltip({ active, payload }: { active?: boolean; payload?: { payload: CategoryBreakdownRow }[] }) {
  if (!active || !payload?.length) return null;
  const row = payload[0]!.payload;
  return (
    <div className="card px-3 py-2 text-xs shadow-card">
      <p className="font-medium text-ink dark:text-ink-dark">{row.category}</p>
      <p className="amount mt-0.5 text-ink-muted">
        {formatSum(row.total)} so&apos;m · {row.percent}%
      </p>
    </div>
  );
}

export function CategoryBreakdownChart({ rows }: { rows: CategoryBreakdownRow[] }) {
  const data = foldIntoOther(rows);
  const height = Math.max(180, data.length * 40);

  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={data} layout="vertical" margin={{ top: 4, right: 48, bottom: 4, left: 4 }} barCategoryGap="28%">
        <XAxis type="number" hide />
        <YAxis
          type="category"
          dataKey="category"
          width={112}
          tickLine={false}
          axisLine={false}
          tick={{ fill: "currentColor", fontSize: 12.5 }}
          className="text-ink-muted"
        />
        <Tooltip content={<CustomTooltip />} cursor={{ fill: CHART_GRID_COLOR, opacity: 0.35 }} />
        <Bar dataKey="total" radius={[0, 6, 6, 0]} maxBarSize={22} isAnimationActive={false}>
          {data.map((row, index) => (
            <Cell
              key={row.category}
              fill={row.category === "Boshqa" ? OTHER_SLOT_COLOR : CATEGORICAL_PALETTE[index % CATEGORICAL_PALETTE.length]}
            />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
