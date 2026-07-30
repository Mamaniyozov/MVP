"use client";

import Link from "next/link";
import { Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { transactionsApi, type TransactionFilters } from "@/lib/api/resources";
import { useAsync } from "@/lib/hooks/useAsync";
import { useLookups } from "@/lib/hooks/useLookups";
import { PageHeader } from "@/components/ui/PageHeader";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { TransactionRow } from "@/components/TransactionRow";
import { Select } from "@/components/ui/Select";
import { Field } from "@/components/ui/Field";
import { dayGroupLabel, formatDate } from "@/lib/format";
import type { Transaction } from "@/lib/types";

const TYPE_CHIPS: { value: TransactionFilters["type"] | ""; label: string }[] = [
  { value: "", label: "Barchasi" },
  { value: "income", label: "Daromad" },
  { value: "expense", label: "Xarajat" },
];

function groupByDay(items: Transaction[]): { label: string; items: Transaction[] }[] {
  const groups: { label: string; items: Transaction[] }[] = [];
  for (const tx of items) {
    const label = dayGroupLabel(tx.date);
    const last = groups[groups.length - 1];
    if (last && last.label === label) {
      last.items.push(tx);
    } else {
      groups.push({ label, items: [tx] });
    }
  }
  return groups;
}

// Filters and page live in the URL, so a filtered view is shareable and the
// Back button steps through filter changes instead of leaving the page.
export default function TransactionsPage() {
  return (
    <Suspense fallback={<Spinner />}>
      <TransactionsContent />
    </Suspense>
  );
}

function TransactionsContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { categories, cards, categoryName, cardName } = useLookups();

  const numberParam = (key: string) => {
    const raw = Number(searchParams.get(key));
    return Number.isInteger(raw) && raw > 0 ? raw : undefined;
  };
  const typeParam = searchParams.get("type");

  const filters: TransactionFilters = {
    type: typeParam === "income" || typeParam === "expense" ? typeParam : undefined,
    category: numberParam("category"),
    card: numberParam("card"),
    date_from: searchParams.get("date_from") || undefined,
    date_to: searchParams.get("date_to") || undefined,
  };
  const page = numberParam("page") ?? 1;

  const list = useAsync(
    () => transactionsApi.list({ ...filters, page }),
    [filters.type, filters.category, filters.card, filters.date_from, filters.date_to, page],
  );

  function pushParams(next: Record<string, string | number | undefined>) {
    const params = new URLSearchParams(searchParams.toString());
    for (const [key, value] of Object.entries(next)) {
      if (value === undefined || value === "") params.delete(key);
      else params.set(key, String(value));
    }
    const query = params.toString();
    router.replace(query ? `/transactions?${query}` : "/transactions", { scroll: false });
  }

  function updateFilter<K extends keyof TransactionFilters>(key: K, value: TransactionFilters[K]) {
    // Any filter change invalidates the current page number.
    pushParams({ [key]: value as string | number | undefined, page: undefined });
  }

  function setPage(next: number) {
    pushParams({ page: next });
  }

  async function handleDelete(id: number) {
    if (!confirm("Tranzaksiyani o'chirasizmi?")) return;
    await transactionsApi.remove(id);
    list.reload();
  }

  const totalPages = list.data ? Math.max(1, Math.ceil(list.data.count / 20)) : 1;

  return (
    <div>
      <PageHeader
        title="Tranzaksiyalar"
        subtitle={list.data ? `Jami ${list.data.count} ta yozuv` : undefined}
        action={
          <Link href="/transactions/new" className="btn-primary">
            + Yangi tranzaksiya
          </Link>
        }
      />

      <div className="mb-4 flex flex-wrap gap-2">
        {TYPE_CHIPS.map((chip) => {
          const active = (filters.type ?? "") === chip.value;
          return (
            <button
              key={chip.label}
              type="button"
              onClick={() => updateFilter("type", (chip.value || undefined) as TransactionFilters["type"])}
              className={`cursor-pointer rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors duration-200 ${
                active
                  ? "bg-brand-soft text-brand-strong dark:bg-income/15 dark:text-income"
                  : "border border-line bg-surface text-ink-muted hover:border-brand/30 dark:border-line-dark dark:bg-surface-dark dark:hover:border-income/30"
              }`}
            >
              {chip.label}
            </button>
          );
        })}
      </div>

      <div className="card mb-6 grid grid-cols-2 gap-3 p-4 sm:grid-cols-3">
        <Select
          label="Kategoriya"
          value={filters.category ?? ""}
          onChange={(e) => updateFilter("category", e.target.value ? Number(e.target.value) : undefined)}
        >
          <option value="">Barchasi</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </Select>

        <Select
          label="Karta"
          value={filters.card ?? ""}
          onChange={(e) => updateFilter("card", e.target.value ? Number(e.target.value) : undefined)}
        >
          <option value="">Barchasi</option>
          {cards.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </Select>

        <div className="grid grid-cols-2 gap-2">
          <Field
            label="Dan"
            type="date"
            value={filters.date_from ?? ""}
            onChange={(e) => updateFilter("date_from", e.target.value || undefined)}
          />
          <Field
            label="Gacha"
            type="date"
            value={filters.date_to ?? ""}
            onChange={(e) => updateFilter("date_to", e.target.value || undefined)}
          />
        </div>
      </div>

      {list.isLoading ? (
        <Spinner />
      ) : list.error ? (
        <ErrorState message={list.error} onRetry={list.reload} />
      ) : list.data && list.data.results.length > 0 ? (
        <>
          <div className="flex flex-col gap-5">
            {groupByDay(list.data.results).map((group) => (
              <div key={group.label}>
                <h3 className="mb-1.5 text-xs font-medium uppercase tracking-wide text-ink-muted dark:text-ink-dark-muted">
                  {group.label}
                </h3>
                <div className="card divide-y divide-line px-3 dark:divide-line-dark">
                  {group.items.map((tx) => (
                    <div key={tx.id} className="group flex items-center">
                      <div className="min-w-0 flex-1">
                        <TransactionRow transaction={tx} categoryName={categoryName(tx.category)} cardName={cardName(tx.card)} />
                      </div>
                      <button
                        type="button"
                        onClick={() => handleDelete(tx.id)}
                        aria-label={`${categoryName(tx.category)} — ${formatDate(tx.date)} tranzaksiyasini o'chirish`}
                        className="mr-2 rounded-md px-2 py-1 text-xs font-medium text-ink-muted opacity-0 transition-opacity hover:bg-expense/10 hover:text-expense focus-visible:opacity-100 group-hover:opacity-100"
                      >
                        O&apos;chirish
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {totalPages > 1 ? (
            <div className="mt-4 flex items-center justify-center gap-3">
              <button
                type="button"
                className="btn-secondary px-3 py-1.5 text-xs"
                disabled={page <= 1}
                onClick={() => setPage(page - 1)}
              >
                Oldingi
              </button>
              <span className="text-xs text-ink-muted">
                {page} / {totalPages}
              </span>
              <button
                type="button"
                className="btn-secondary px-3 py-1.5 text-xs"
                disabled={page >= totalPages}
                onClick={() => setPage(page + 1)}
              >
                Keyingi
              </button>
            </div>
          ) : null}
        </>
      ) : (
        <EmptyState
          title="Hech narsa topilmadi"
          description="Filtrni o'zgartiring yoki yangi tranzaksiya qo'shing."
          action={
            <Link href="/transactions/new" className="btn-primary">
              Tranzaksiya qo&apos;shish
            </Link>
          }
        />
      )}
    </div>
  );
}
