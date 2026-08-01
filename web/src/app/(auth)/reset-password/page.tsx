"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { confirmPasswordReset } from "@/lib/api/auth";
import { apiErrorMessage } from "@/lib/api/client";

function ResetPasswordForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const uid = searchParams.get("uid") || "";
  const token = searchParams.get("token") || "";

  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isSuccess, setIsSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;

    if (newPassword !== confirmPassword) {
      setError("Yangi parollar mos kelmadi.");
      return;
    }

    if (!uid || !token) {
      setError("Tiklash kaliti yoki foydalanuvchi identifikatori yetishmaydi.");
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      await confirmPasswordReset(uid, token, newPassword);
      setIsSuccess(true);
      setTimeout(() => {
        router.push("/login");
      }, 2500);
    } catch (err) {
      setError(apiErrorMessage(err, "Parolni yangilashda xatolik yuz berdi. Kalit eskirgan bo'lishi mumkin."));
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isSuccess) {
    return (
      <div className="rounded-xl border border-income/30 bg-income/10 p-5 text-center">
        <h2 className="font-display text-lg font-semibold text-income">Parol muvaffaqiyatli o&apos;zgartirildi!</h2>
        <p className="mt-1.5 text-xs text-ink dark:text-ink-dark">
          Tizimga kirish sahifasiga yo&apos;naltirilmoqdasiz…
        </p>
        <Link href="/login" className="btn-primary mt-4 text-xs">
          Hozir kirish
        </Link>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-4" noValidate>
      <Field
        label="Yangi parol"
        type="password"
        name="newPassword"
        autoComplete="new-password"
        required
        value={newPassword}
        onChange={(e) => setNewPassword(e.target.value)}
      />

      <Field
        label="Yangi parolni tasdiqlang"
        type="password"
        name="confirmPassword"
        autoComplete="new-password"
        required
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
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
            O&apos;zgartirilmoqda…
          </>
        ) : (
          "Parolni yangilash"
        )}
      </button>
    </form>
  );
}

export default function ResetPasswordPage() {
  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        Yangi parol o&apos;rnating
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">
        Hisobingiz uchun kuchli yangi parol kiriting.
      </p>

      <Suspense fallback={<div className="mt-8 text-sm text-ink-muted">Yuklanmoqda…</div>}>
        <ResetPasswordForm />
      </Suspense>

      <p className="mt-6 text-sm text-ink-muted">
        <Link href="/login" className="font-medium text-brand hover:underline dark:text-income">
          Tizimga kirish sahifasiga qaytish
        </Link>
      </p>
    </div>
  );
}
