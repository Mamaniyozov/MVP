"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent, useEffect } from "react";
import { Field } from "@/components/ui/Field";
import { apiErrorMessage } from "@/lib/api/client";
import { verifyMFA } from "@/lib/api/auth";
import { useAuth } from "@/lib/auth/AuthContext";
import Link from "next/link";

export default function MFAPage() {
  const router = useRouter();
  const { completeLogin } = useAuth();
  const [token, setToken] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const [tempToken, setTempToken] = useState<string | null>(null);
  const [mfaEmail, setMfaEmail] = useState<string | null>(null);

  useEffect(() => {
    const storedToken = sessionStorage.getItem("mfa_temp_token");
    const storedEmail = sessionStorage.getItem("mfa_email");
    
    if (!storedToken) {
      router.replace("/login");
    } else {
      setTempToken(storedToken);
      setMfaEmail(storedEmail);
    }
  }, [router]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting || !tempToken) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await verifyMFA(token, tempToken);
      if ("access" in res && res.access && res.refresh) {
        completeLogin(mfaEmail || "", res.access, res.refresh);
        sessionStorage.removeItem("mfa_temp_token");
        sessionStorage.removeItem("mfa_email");
        router.push("/dashboard");
      } else {
        setError("Token kutilmoqda, xatolik yuz berdi.");
      }
    } catch (err) {
      setError(apiErrorMessage(err, "MFA kod noto'g'ri."));
    } finally {
      setIsSubmitting(false);
    }
  }

  if (!tempToken) return null; // Wait for redirect or state check

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        Ikki bosqichli autentifikatsiya
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">
        Hisobingizni himoya qilish uchun Authenticator ilovangizdagi 6 xonali kodni kiriting.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-4" noValidate>
        <Field
          label="MFA Kod"
          type="text"
          name="token"
          autoComplete="one-time-code"
          required
          value={token}
          onChange={(e) => setToken(e.target.value)}
        />

        {error ? (
          <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
            {error}
          </p>
        ) : null}

        <button type="submit" className="btn-primary mt-2" aria-busy={isSubmitting}>
          {isSubmitting ? "Tasdiqlanmoqda..." : "Tasdiqlash"}
        </button>
      </form>
      
      <div className="mt-6 text-sm text-ink-muted text-center">
        <Link href="/login" className="font-medium text-brand hover:underline dark:text-income">
          Orqaga qaytish
        </Link>
      </div>
    </div>
  );
}
