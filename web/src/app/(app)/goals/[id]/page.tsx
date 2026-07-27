"use client";

import { useParams, useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { goalsApi } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { useAsync } from "@/lib/hooks/useAsync";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState, Spinner } from "@/components/ui/EmptyState";
import { Field } from "@/components/ui/Field";
import { GoalProgress } from "@/components/GoalProgress";

export default function GoalDetailPage() {
  const params = useParams<{ id: string }>();
  const goalId = Number(params.id);
  const router = useRouter();

  const goal = useAsync(() => goalsApi.get(goalId), [goalId]);
  const [amount, setAmount] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleAddProgress(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await goalsApi.addProgress(goalId, amount);
      setAmount("");
      goal.reload();
    } catch (err) {
      setError(apiErrorMessage(err, "Progressni qo'shib bo'lmadi."));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDelete() {
    if (!goal.data || !confirm(`"${goal.data.name}" maqsadini o'chirasizmi?`)) return;
    await goalsApi.remove(goalId);
    router.push("/goals");
  }

  if (goal.isLoading) return <Spinner />;
  if (goal.error || !goal.data) return <ErrorState message={goal.error ?? "Maqsad topilmadi"} onRetry={goal.reload} />;

  const isComplete = goal.data.progress_percent >= 100;

  return (
    <div className="max-w-lg">
      <PageHeader title={goal.data.name} subtitle={goal.data.deadline ? `Muddat: ${goal.data.deadline}` : undefined} />

      <div className="card p-6">
        <GoalProgress goal={goal.data} linkToDetail={false} />
      </div>

      {isComplete ? (
        <p className="mt-4 rounded-lg bg-brand-soft px-4 py-3 text-sm text-brand-strong dark:bg-brand/20 dark:text-white">
          Tabriklaymiz — maqsadga erishdingiz! 🎉
        </p>
      ) : (
        <form onSubmit={handleAddProgress} className="card mt-6 flex flex-col gap-4 p-6" noValidate>
          <h2 className="font-display text-base font-semibold text-ink dark:text-ink-dark">Progress qo&apos;shish</h2>
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
          {error ? (
            <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
              {error}
            </p>
          ) : null}
          <button type="submit" className="btn-primary" disabled={isSubmitting}>
            {isSubmitting ? "Qo'shilmoqda…" : "Qo'shish"}
          </button>
        </form>
      )}

      <button type="button" onClick={handleDelete} className="btn-danger mt-6">
        Maqsadni o&apos;chirish
      </button>
    </div>
  );
}
