"use client";

import Link from "next/link";
import { useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { requestPasswordReset, type PasswordResetResponse } from "@/lib/api/auth";
import { apiErrorMessage } from "@/lib/api/client";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [result, setResult] = useState<PasswordResetResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setResult(null);
    setIsSubmitting(true);
    try {
      const res = await requestPasswordReset(email);
      setResult(res);
    } catch (err) {
      setError(apiErrorMessage(err, "Parolni tiklash so'rovi yuborishda xatolik yuz berdi."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        Parolni tiklash
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">
        E-pochta manzilingizni kiriting. Biz parolni yangilash uchun maxsus havola va ko'rsatmalarni yuboramiz.
      </p>

      {result ? (
        <div className="mt-6 flex flex-col gap-4 rounded-xl border border-line bg-paper p-5 dark:border-line-dark dark:bg-paper-dark">
          <p className="text-sm font-medium text-income">
            ✓ {result.detail}
          </p>
          {result.uid && result.token ? (
            <div className="mt-2 rounded-lg border border-brand/20 bg-brand/5 p-3.5 text-xs text-ink dark:text-ink-dark">
              <p className="font-semibold text-brand dark:text-income">Simulyatsiya (Demo Rejimi):</p>
              <p className="mt-1 text-ink-muted">Yangi parol o'rnatish uchun quyidagi havolaga o'ting:</p>
              <Link
                href={`/reset-password?uid=${result.uid}&token=${result.token}`}
                className="mt-2 inline-block font-mono text-brand underline break-all dark:text-income"
              >
                /reset-password?uid={result.uid}&token={result.token}
              </Link>
            </div>
          ) : null}
          <Link href="/login" className="btn-secondary mt-2 text-center text-xs">
            Loginga qaytish
          </Link>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-4" noValidate>
          <Field
            label="Email"
            type="email"
            name="email"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          {error ? (
            <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
              {error}
            </p>
          ) : null}

          <button type="submit" className="btn-primary mt-2" aria-busy={isSubmitting}>
            {isSubmitting ? (
              <>
                <span
                  aria-hidden
                  className="h-3.5 w-3.5 shrink-0 animate-spin rounded-full border-2 border-white/35 border-t-white"
                />
                Yuborilmoqda…
              </>
            ) : (
              "Tiklash havolasini yuborish"
            )}
          </button>
        </form>
      )}

      <p className="mt-6 text-sm text-ink-muted">
        Parolingiz yodingizdami?{" "}
        <Link href="/login" className="font-medium text-brand hover:underline dark:text-income">
          Tizimga kiring
        </Link>
      </p>
    </div>
  );
}
