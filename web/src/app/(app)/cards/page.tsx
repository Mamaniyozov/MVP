"use client";

import { useState, type FormEvent } from "react";
import { cardsApi, unwrapList } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { Field } from "@/components/ui/Field";
import { ErrorState, Spinner } from "@/components/ui/EmptyState";
import type { Card } from "@/lib/types";

export default function CardsPage() {
  const list = useAsync(() => cardsApi.list().then(unwrapList), []);
  const [editing, setEditing] = useState<Card | null>(null);
  const [name, setName] = useState("");
  const [last4, setLast4] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function reset() {
    setEditing(null);
    setName("");
    setLast4("");
    setError(null);
  }

  function startEdit(card: Card) {
    setEditing(card);
    setName(card.name);
    setLast4(card.last4);
    setError(null);
  }

  async function handleDelete(card: Card) {
    if (!confirm(`"${card.name}" kartasini o'chirasizmi?`)) return;
    try {
      await cardsApi.remove(card.id);
      list.reload();
    } catch (err) {
      setError(apiErrorMessage(err));
    }
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      if (editing) {
        await cardsApi.update(editing.id, { name, last4 });
      } else {
        await cardsApi.create({ name, last4 });
      }
      reset();
      list.reload();
    } catch (err) {
      setError(apiErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div>
      <PageHeader title="Kartalar" subtitle="Tranzaksiyalarni bog'lash uchun to'lov kartalaringiz." />

      <form onSubmit={handleSubmit} className="card mb-8 grid grid-cols-1 gap-3 p-4 sm:grid-cols-[1fr_120px_auto]">
        <Field id="card-name-field" label="Nomi" required value={name} onChange={(e) => setName(e.target.value)} placeholder="Masalan: Uzcard" />
        <Field
          label="Oxirgi 4 raqam"
          name="card-last4"
          inputMode="numeric"
          autoComplete="off"
          spellCheck={false}
          value={last4}
          onChange={(e) => setLast4(e.target.value.replace(/\D/g, "").slice(0, 4))}
          placeholder="1234"
          maxLength={4}
        />
        <div className="flex items-end gap-2">
          <button type="submit" className="btn-primary" aria-busy={isSubmitting}>
            {isSubmitting ? "Saqlanmoqda…" : editing ? "Saqlash" : "Qo'shish"}
          </button>
          {editing ? (
            <button type="button" className="btn-secondary" onClick={reset}>
              Bekor qilish
            </button>
          ) : null}
        </div>
        {error ? (
          <p role="alert" className="col-span-full rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
            {error}
          </p>
        ) : null}
      </form>

      {list.isLoading ? (
        <Spinner />
      ) : list.error ? (
        <ErrorState message={list.error} onRetry={list.reload} />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {(list.data ?? []).map((card, i) => (
            <div
              key={card.id}
              className="group relative flex aspect-[1.586/1] flex-col justify-between overflow-hidden rounded-card p-5 text-white shadow-card transition-transform duration-300 hover:-translate-y-0.5"
              style={{
                background:
                  i % 2 === 0
                    ? "linear-gradient(135deg, #12946a 0%, #0a4e38 62%, #063324 100%)"
                    : "linear-gradient(135deg, #0e7a56 0%, #0a4e38 55%, #08301f 100%)",
              }}
            >
              <div
                aria-hidden
                className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_82%_12%,rgba(255,255,255,0.22),transparent_55%)]"
              />
              <div className="relative flex items-start justify-between text-xs uppercase tracking-wider text-white/70">
                <span>Hisob</span>
                <span>{card.last4 ? "•••• •••• •••• " + card.last4 : "raqamsiz"}</span>
              </div>
              <div className="relative">
                <p className="amount text-lg tracking-[0.18em]">
                  {card.last4 ? `•••• ${card.last4}` : "•••• ••••"}
                </p>
                <p className="mt-2 truncate text-sm font-medium text-white/90">{card.name}</p>
              </div>
              <div className="relative flex justify-end gap-1 opacity-0 transition-opacity duration-200 group-hover:opacity-100 focus-within:opacity-100">
                <button
                  type="button"
                  onClick={() => startEdit(card)}
                  className="cursor-pointer rounded-md bg-white/15 px-2.5 py-1 text-xs font-medium backdrop-blur-sm transition-colors hover:bg-white/25"
                >
                  Tahrirlash
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(card)}
                  className="cursor-pointer rounded-md bg-white/15 px-2.5 py-1 text-xs font-medium backdrop-blur-sm transition-colors hover:bg-expense/80"
                >
                  O&apos;chirish
                </button>
              </div>
            </div>
          ))}

          <button
            type="button"
            onClick={() => document.getElementById("card-name-field")?.focus()}
            className="flex aspect-[1.586/1] cursor-pointer flex-col items-center justify-center gap-2 rounded-card border-2 border-dashed border-line text-sm font-medium text-ink-muted transition-colors duration-200 hover:border-brand/40 hover:text-brand dark:border-line-dark dark:hover:border-income/40 dark:hover:text-income"
          >
            <span className="text-2xl leading-none">+</span>
            Karta qo&apos;shish
          </button>
        </div>
      )}
    </div>
  );
}
