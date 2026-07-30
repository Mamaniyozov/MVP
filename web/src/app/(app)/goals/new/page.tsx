"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { goalsApi } from "@/lib/api/resources";
import { apiErrorMessage } from "@/lib/api/client";
import { PageHeader } from "@/components/ui/PageHeader";
import { Field } from "@/components/ui/Field";

export default function NewGoalPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [targetAmount, setTargetAmount] = useState("");
  const [deadline, setDeadline] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const goal = await goalsApi.create({
        name,
        target_amount: targetAmount,
        deadline: deadline || null,
      });
      router.push(`/goals/${goal.id}`);
    } catch (err) {
      setError(apiErrorMessage(err, "Maqsadni saqlab bo'lmadi."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="max-w-lg">
      <PageHeader title="Yangi maqsad" subtitle="Nimaga jamg'arayotganingizni belgilang." />

      <form onSubmit={handleSubmit} className="card flex flex-col gap-4 p-6" noValidate>
        <Field label="Nomi" required value={name} onChange={(e) => setName(e.target.value)} placeholder="Masalan: Zaxira fond" />
        <Field
          label="Maqsad summasi"
          type="number"
          inputMode="decimal"
          min="0.01"
          step="0.01"
          required
          value={targetAmount}
          onChange={(e) => setTargetAmount(e.target.value)}
        />
        <Field label="Muddat (ixtiyoriy)" type="date" value={deadline} onChange={(e) => setDeadline(e.target.value)} />

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
