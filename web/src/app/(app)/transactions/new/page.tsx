"use client";

import { useRouter } from "next/navigation";
import { useMemo, useState, type FormEvent } from "react";
import { transactionsApi } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { useLookups } from "@/lib/hooks/useLookups";
import { PageHeader } from "@/components/ui/PageHeader";
import { Field } from "@/components/ui/Field";
import { Select } from "@/components/ui/Select";
import { todayIso } from "@/lib/format";
import type { TxType } from "@/lib/types";

export default function NewTransactionPage() {
  const router = useRouter();
  const { categories, cards, isLoading } = useLookups();

  const [type, setType] = useState<TxType>("expense");
  const [amount, setAmount] = useState("");
  const [date, setDate] = useState(todayIso());
  const [categoryId, setCategoryId] = useState("");
  const [cardId, setCardId] = useState("");
  const [note, setNote] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const filteredCategories = useMemo(() => categories.filter((c) => c.type === type), [categories, type]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await transactionsApi.create({
        type,
        amount,
        date,
        note,
        category: categoryId ? Number(categoryId) : null,
        card: cardId ? Number(cardId) : null,
      });
      router.push("/transactions");
    } catch (err) {
      setError(apiErrorMessage(err, "Tranzaksiyani saqlab bo'lmadi."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="max-w-lg">
      <PageHeader title="Yangi tranzaksiya" subtitle="Xarajat yoki daromadingizni reestrga yozing." />

      <form onSubmit={handleSubmit} className="card flex flex-col gap-4 p-6" noValidate>
        <div
          role="radiogroup"
          aria-label="Tranzaksiya turi"
          className="grid grid-cols-2 gap-2 rounded-lg bg-paper p-1 dark:bg-paper-dark"
        >
          {(["expense", "income"] as const).map((option) => (
            <button
              key={option}
              type="button"
              role="radio"
              aria-checked={type === option}
              onClick={() => {
                setType(option);
                setCategoryId("");
              }}
              className={`rounded-md py-2 text-sm font-medium transition-colors ${
                type === option
                  ? option === "income"
                    ? "bg-income text-white"
                    : "bg-expense text-white"
                  : "text-ink-muted hover:text-ink"
              }`}
            >
              {option === "income" ? "Daromad" : "Xarajat"}
            </button>
          ))}
        </div>

        <Field
          label="Summa"
          type="number"
          inputMode="decimal"
          min="0.01"
          step="0.01"
          required
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />

        <Field label="Sana" type="date" required value={date} onChange={(e) => setDate(e.target.value)} />

        <Select label="Kategoriya" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} disabled={isLoading}>
          <option value="">Kategoriyasiz</option>
          {filteredCategories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </Select>

        <Select label="Karta (ixtiyoriy)" value={cardId} onChange={(e) => setCardId(e.target.value)} disabled={isLoading}>
          <option value="">Tanlanmagan</option>
          {cards.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name} · {c.last4}
            </option>
          ))}
        </Select>

        <Field label="Izoh (ixtiyoriy)" value={note} onChange={(e) => setNote(e.target.value)} />

        {error ? (
          <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
            {error}
          </p>
        ) : null}

        <div className="mt-2 flex gap-3">
          <button type="submit" className="btn-primary flex-1" aria-busy={isSubmitting}>
            {isSubmitting ? "Saqlanmoqda…" : "Saqlash"}
          </button>
          <button type="button" className="btn-secondary" onClick={() => router.back()}>
            Bekor qilish
          </button>
        </div>
      </form>
    </div>
  );
}
