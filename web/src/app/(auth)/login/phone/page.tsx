"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { apiErrorMessage } from "@/lib/api/client";
import { requestOTP, verifyOTP } from "@/lib/api/auth";
import { useAuth } from "@/lib/auth/AuthContext";

export default function PhoneLoginPage() {
  const router = useRouter();
  const { completeLogin } = useAuth();
  const [phone, setPhone] = useState("+998");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState<"request" | "verify">("request");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleRequestSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await requestOTP(phone);
      setStep("verify");
    } catch (err) {
      setError(apiErrorMessage(err, "Telefon raqam noto'g'ri yoki ro'yxatdan o'tmagan."));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleVerifySubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await verifyOTP(phone, otp);
      completeLogin(phone, res.access, res.refresh);
      router.push("/dashboard");
    } catch (err) {
      setError(apiErrorMessage(err, "OTP kod noto'g'ri."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-ink dark:text-ink-dark">
        {step === "request" ? "Telefon orqali kirish" : "Kodni tasdiqlash"}
      </h1>
      <p className="mt-1.5 text-sm text-ink-muted">
        {step === "request"
          ? "Ro'yxatdan o'tgan telefon raqamingizni kiriting."
          : `Kodni ${phone} raqamiga yubordik.`}
      </p>

      {step === "request" ? (
        <form onSubmit={handleRequestSubmit} className="mt-8 flex flex-col gap-4" noValidate>
          <Field
            label="Telefon raqam"
            type="tel"
            name="phone"
            autoComplete="tel"
            required
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
          />

          {error ? (
            <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
              {error}
            </p>
          ) : null}

          <button type="submit" className="btn-primary mt-2" aria-busy={isSubmitting}>
            {isSubmitting ? "Yuborilmoqda..." : "Kodni olish"}
          </button>
        </form>
      ) : (
        <form onSubmit={handleVerifySubmit} className="mt-8 flex flex-col gap-4" noValidate>
          <Field
            label="OTP Kod"
            type="text"
            name="otp"
            autoComplete="one-time-code"
            required
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
          />

          {error ? (
            <p role="alert" className="rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
              {error}
            </p>
          ) : null}

          <button type="submit" className="btn-primary mt-2" aria-busy={isSubmitting}>
            {isSubmitting ? "Tasdiqlanmoqda..." : "Kirish"}
          </button>
          
          <button 
            type="button" 
            onClick={() => setStep("request")}
            className="mt-2 text-sm text-brand hover:underline dark:text-income"
          >
            Raqamni o'zgartirish
          </button>
        </form>
      )}

      <div className="mt-6 flex flex-col gap-2 text-sm text-ink-muted">
        <p>
          Email orqali kirishni xohlaysizmi?{" "}
          <Link href="/login" className="font-medium text-brand hover:underline dark:text-income">
            Email orqali kirish
          </Link>
        </p>
      </div>
    </div>
  );
}
