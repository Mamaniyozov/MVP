"use client";

import { useState, type FormEvent } from "react";
import { cardsApi, unwrapList } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { Field } from "@/components/ui/Field";
import { EmptyState, ErrorState, Spinner } from "@/components/ui/EmptyState";
import { IconCard } from "@/components/layout/icons";
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
      alert(apiErrorMessage(err));
    }
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
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
        <Field label="Nomi" required value={name} onChange={(e) => setName(e.target.value)} placeholder="Masalan: Uzcard" />
        <Field
          label="Oxirgi 4 raqam"
          value={last4}
          onChange={(e) => setLast4(e.target.value.replace(/\D/g, "").slice(0, 4))}
          placeholder="1234"
          maxLength={4}
        />
        <div className="flex items-end gap-2">
          <button type="submit" className="btn-primary" disabled={isSubmitting}>
            {editing ? "Saqlash" : "Qo'shish"}
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
      ) : list.data && list.data.length > 0 ? (
        <div className="card divide-y divide-line dark:divide-line-dark">
          {list.data.map((card) => (
            <div key={card.id} className="flex items-center justify-between gap-3 px-4 py-3.5">
              <div className="flex items-center gap-3">
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-soft text-brand-strong dark:bg-brand/20 dark:text-white">
                  <IconCard className="h-[18px] w-[18px]" />
                </span>
                <div>
                  <p className="text-sm font-medium text-ink dark:text-ink-dark">{card.name}</p>
                  {card.last4 ? <p className="amount text-xs text-ink-muted">•••• {card.last4}</p> : null}
                </div>
              </div>
              <div className="flex gap-1">
                <button type="button" onClick={() => startEdit(card)} className="btn-secondary px-2.5 py-1 text-xs">
                  Tahrirlash
                </button>
                <button type="button" onClick={() => handleDelete(card)} className="btn-danger px-2.5 py-1 text-xs">
                  O&apos;chirish
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <EmptyState title="Karta qo'shilmagan" description="Birinchi kartangizni qo'shing." />
      )}
    </div>
  );
}
