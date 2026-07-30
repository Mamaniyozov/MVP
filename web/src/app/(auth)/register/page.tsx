"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { apiErrorMessage } from "@/lib/api/client";
import { useAuth } from "@/lib/auth/AuthContext";

export default function RegisterPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [password2, setPassword2] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);

    if (password !== password2) {
      setError("Parollar mos kelmadi.");
      return;
    }

    setIsSubmitting(true);
    try {
      await register(email, password, password2);
      router.push("/dashboard");
    } catch (err) {
      setError(apiErrorMessage(err, "Ro'yxatdan o'tishda xatolik yuz berdi."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        Hisob oching
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">
        Ro&apos;yxatdan o&apos;tsangiz, standart kategoriyalar avtomatik yaratiladi.
      </p>

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
        <Field
          label="Parol"
          type="password"
          name="password"
          autoComplete="new-password"
          required
          minLength={8}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <Field
          label="Parolni tasdiqlang"
          type="password"
          name="password2"
          autoComplete="new-password"
          required
          value={password2}
          onChange={(e) => setPassword2(e.target.value)}
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
              Yaratilmoqda…
            </>
          ) : (
            "Ro'yxatdan o'tish"
          )}
        </button>
      </form>

      <p className="mt-6 text-sm text-ink-muted">
        Allaqachon hisobingiz bormi?{" "}
        <Link href="/login" className="font-medium text-brand hover:underline dark:text-income">
          Kirish
        </Link>
      </p>
    </div>
  );
}
