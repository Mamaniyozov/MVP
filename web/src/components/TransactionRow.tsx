import { formatDate, formatSigned } from "@/lib/format";
import type { Transaction } from "@/lib/types";

const CATEGORY_RULE_COLORS = ["#0F6B4C", "#E8A33D", "#C4573B", "#2F6FB0", "#7A5FC7", "#0E9AA7"];

function ruleColorFor(categoryId: number | null): string {
  if (categoryId === null) return "#DFE6E1";
  return CATEGORY_RULE_COLORS[categoryId % CATEGORY_RULE_COLORS.length] ?? "#DFE6E1";
}

export function TransactionRow({
  transaction,
  categoryName,
  cardName,
  onClick,
}: {
  transaction: Transaction;
  categoryName: string;
  cardName?: string | null;
  onClick?: () => void;
}) {
  const isIncome = transaction.type === "income";

  return (
    <div
      className="ledger-row cursor-default"
      style={{ borderLeftColor: ruleColorFor(transaction.category) }}
      onClick={onClick}
      role={onClick ? "button" : undefined}
    >
      <span aria-hidden className="hidden" />
      <div className="min-w-0">
        <p className="truncate text-sm font-medium text-ink dark:text-ink-dark">
          {categoryName}
          {transaction.note ? <span className="font-normal text-ink-muted"> · {transaction.note}</span> : null}
        </p>
        <p className="mt-0.5 text-xs text-ink-muted">
          {formatDate(transaction.date)}
          {cardName ? ` · ${cardName}` : ""}
        </p>
      </div>
      <p className={`amount text-sm font-semibold ${isIncome ? "text-income" : "text-expense"}`}>
        {formatSigned(transaction.amount, transaction.type)}
      </p>
    </div>
  );
}
