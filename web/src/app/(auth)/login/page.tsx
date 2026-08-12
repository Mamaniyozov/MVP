"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { apiErrorMessage } from "@/lib/api/client";
import { useAuth } from "@/lib/auth/AuthContext";

export default function LoginPage() {
  const { login } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await login(email, password);
      if (res.mfa_required && res.temp_token) {
        sessionStorage.setItem("mfa_temp_token", res.temp_token);
        sessionStorage.setItem("mfa_email", email);
        router.push("/mfa");
      } else {
        router.push("/dashboard");
      }
    } catch (err) {
      setError(apiErrorMessage(err, "Email yoki parol noto'g'ri."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        Xush kelibsiz
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">Hisobingizga kiring va reestrni davom ettiring.</p>

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
        <div>
          <Field
            label="Parol"
            type="password"
            name="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <div className="mt-1.5 text-right">
            <Link href="/forgot-password" className="text-xs font-medium text-brand hover:underline dark:text-income">
              Parolni unutdingizmi?
            </Link>
          </div>
        </div>


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
              Kirilmoqda…
            </>
          ) : (
            "Kirish"
          )}
        </button>
      </form>

      <div className="mt-6 flex flex-col gap-2 text-sm text-ink-muted">
        <p>
          Hisobingiz yo&apos;qmi?{" "}
          <Link href="/register" className="font-medium text-brand hover:underline dark:text-income">
            Ro&apos;yxatdan o&apos;ting
          </Link>
        </p>
        <p>
          Telefon orqali kirishni xohlaysizmi?{" "}
          <Link href="/login/phone" className="font-medium text-brand hover:underline dark:text-income">
            Telefon orqali kirish
          </Link>
        </p>
      </div>
    </div>
  );
}
