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
    setError(null);
    setIsSubmitting(true);
    try {
      await login(email, password);
      router.push("/dashboard");
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
        <Field
          label="Parol"
          type="password"
          name="password"
          autoComplete="current-password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        {error ? (
          <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
            {error}
          </p>
        ) : null}

        <button type="submit" className="btn-primary mt-2" disabled={isSubmitting}>
          {isSubmitting ? "Kirilmoqda…" : "Kirish"}
        </button>
      </form>

      <p className="mt-6 text-sm text-ink-muted">
        Hisobingiz yo&apos;qmi?{" "}
        <Link href="/register" className="font-medium text-brand hover:underline">
          Ro&apos;yxatdan o&apos;ting
        </Link>
      </p>
    </div>
  );
}
