"use client";

import { useState, type FormEvent } from "react";
import { categoriesApi, unwrapList } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { Field } from "@/components/ui/Field";
import { Select } from "@/components/ui/Select";
import { ErrorState, Spinner } from "@/components/ui/EmptyState";
import type { Category, TxType } from "@/lib/types";

function CategoryGroup({
  title,
  items,
  onEdit,
  onDelete,
}: {
  title: string;
  items: Category[];
  onEdit: (c: Category) => void;
  onDelete: (c: Category) => void;
}) {
  if (items.length === 0) return null;
  return (
    <div>
      <h2 className="mb-3 font-display text-sm font-semibold uppercase tracking-wide text-ink-muted">{title}</h2>
      <div className="flex flex-wrap gap-2.5">
        {items.map((c) => (
          <div
            key={c.id}
            className="group flex items-center gap-2 rounded-full border border-line bg-surface py-1.5 pl-3 pr-1.5 shadow-[0_1px_2px_rgba(18,35,28,0.04)] transition-colors duration-200 hover:border-brand/30 dark:border-line-dark dark:bg-surface-dark dark:hover:border-income/30"
          >
            <span className="text-base leading-none">{c.icon || "•"}</span>
            <span className="text-sm font-medium text-ink dark:text-ink-dark">{c.name}</span>
            {c.is_default ? (
              <span className="rounded-full bg-paper px-2 py-0.5 text-[10px] text-ink-muted dark:bg-white/5">
                standart
              </span>
            ) : (
              <span className="flex items-center gap-0.5 opacity-0 transition-opacity duration-200 group-hover:opacity-100 group-focus-within:opacity-100">
                <button
                  type="button"
                  onClick={() => onEdit(c)}
                  className="cursor-pointer rounded-full px-2 py-1 text-[11px] font-medium text-ink-muted transition-colors hover:bg-brand/10 hover:text-brand dark:hover:bg-income/10 dark:hover:text-income"
                  aria-label={`${c.name} tahrirlash`}
                >
                  Tahrirlash
                </button>
                <button
                  type="button"
                  onClick={() => onDelete(c)}
                  className="cursor-pointer rounded-full px-2 py-1 text-[11px] font-medium text-ink-muted transition-colors hover:bg-expense/10 hover:text-expense"
                  aria-label={`${c.name} o'chirish`}
                >
                  O&apos;chirish
                </button>
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default function CategoriesPage() {
  const list = useAsync(() => categoriesApi.list().then(unwrapList), []);
  const [editing, setEditing] = useState<Category | null>(null);
  const [name, setName] = useState("");
  const [type, setType] = useState<TxType>("expense");
  const [icon, setIcon] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function startCreate() {
    setEditing(null);
    setName("");
    setType("expense");
    setIcon("");
    setError(null);
  }

  function startEdit(category: Category) {
    setEditing(category);
    setName(category.name);
    setType(category.type);
    setIcon(category.icon);
    setError(null);
  }

  async function handleDelete(category: Category) {
    if (!confirm(`"${category.name}" kategoriyasini o'chirasizmi?`)) return;
    try {
      await categoriesApi.remove(category.id);
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
        await categoriesApi.update(editing.id, { name, type, icon });
      } else {
        await categoriesApi.create({ name, type, icon });
      }
      startCreate();
      list.reload();
    } catch (err) {
      setError(apiErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  }

  const income = (list.data ?? []).filter((c) => c.type === "income");
  const expense = (list.data ?? []).filter((c) => c.type === "expense");

  return (
    <div>
      <PageHeader title="Kategoriyalar" subtitle="Xarajat va daromadlaringizni tartiblash uchun kategoriyalar." />

      <form onSubmit={handleSubmit} className="card mb-8 grid grid-cols-1 gap-3 p-4 sm:grid-cols-[1fr_1fr_100px_auto]">
        <Field label="Nomi" required value={name} onChange={(e) => setName(e.target.value)} placeholder="Masalan: Transport" />
        <Select label="Turi" value={type} onChange={(e) => setType(e.target.value as TxType)}>
          <option value="expense">Xarajat</option>
          <option value="income">Daromad</option>
        </Select>
        <Field label="Belgi" value={icon} onChange={(e) => setIcon(e.target.value)} placeholder="🚌" maxLength={4} />
        <div className="flex items-end gap-2">
          <button type="submit" className="btn-primary" disabled={isSubmitting}>
            {editing ? "Saqlash" : "Qo'shish"}
          </button>
          {editing ? (
            <button type="button" className="btn-secondary" onClick={startCreate}>
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
        <div className="flex flex-col gap-8">
          <CategoryGroup title="Xarajat" items={expense} onEdit={startEdit} onDelete={handleDelete} />
          <CategoryGroup title="Daromad" items={income} onEdit={startEdit} onDelete={handleDelete} />
        </div>
      )}
    </div>
  );
}
