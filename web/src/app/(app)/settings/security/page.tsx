"use client";

import { useState, type FormEvent } from "react";
import { Field } from "@/components/ui/Field";
import { apiErrorMessage } from "@/lib/api/client";
import { setupMFA, verifyMFA, registerPhone } from "@/lib/api/auth";
import { tokenStore } from "@/lib/api/tokenStore";
import Image from "next/image";

export default function SecuritySettingsPage() {
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [mfaCode, setMfaCode] = useState("");
  const [mfaStatus, setMfaStatus] = useState<"idle" | "setup" | "success">("idle");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [phone, setPhone] = useState("+998");
  const [phoneStatus, setPhoneStatus] = useState<"idle" | "success">("idle");

  async function handleMfaSetup() {
    setError(null);
    setIsSubmitting(true);
    try {
      const access = tokenStore.getAccess();
      if (!access) throw new Error("Auth required");
      const res = await setupMFA(access);
      setQrCode(res.qr_code);
      setMfaStatus("setup");
    } catch (err) {
      setError(apiErrorMessage(err, "MFA o'rnatishda xatolik."));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleMfaVerify(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const access = tokenStore.getAccess();
      if (!access) throw new Error("Auth required");
      await verifyMFA(mfaCode, undefined, access);
      setMfaStatus("success");
    } catch (err) {
      setError(apiErrorMessage(err, "MFA kod noto'g'ri."));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handlePhoneSubmit(event: FormEvent) {
    event.preventDefault();
    if (isSubmitting) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const access = tokenStore.getAccess();
      if (!access) throw new Error("Auth required");
      await registerPhone(phone, access);
      setPhoneStatus("success");
    } catch (err) {
      setError(apiErrorMessage(err, "Telefon raqamni saqlashda xatolik."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="max-w-2xl mx-auto py-8">
      <h1 className="text-2xl font-semibold mb-6">Xavfsizlik Sozlamalari</h1>

      <div className="bg-white dark:bg-ink-darker shadow rounded-lg p-6 mb-8">
        <h2 className="text-lg font-medium mb-4">Telefon raqamni biriktirish (SMS OTP)</h2>
        <p className="text-sm text-ink-muted mb-4">
          Hisobingizga telefon raqam va SMS kod orqali kirish imkoniyatiga ega bo'lish uchun uni bog'lang.
        </p>

        {phoneStatus === "success" ? (
          <div className="rounded-lg bg-income/10 px-4 py-3 text-sm text-income border border-income/20">
            Telefon raqam muvaffaqiyatli saqlandi!
          </div>
        ) : (
          <form onSubmit={handlePhoneSubmit} className="flex gap-4 items-end">
            <div className="flex-1">
              <Field
                label="Telefon raqam"
                type="tel"
                name="phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                required
              />
            </div>
            <button type="submit" className="btn-primary mb-1" disabled={isSubmitting}>
              Saqlash
            </button>
          </form>
        )}
      </div>

      <div className="bg-white dark:bg-ink-darker shadow rounded-lg p-6">
        <h2 className="text-lg font-medium mb-4">Ikki bosqichli autentifikatsiya (MFA)</h2>
        
        {mfaStatus === "idle" && (
          <div>
            <p className="text-sm text-ink-muted mb-4">
              Google Authenticator yoki shunga o'xshash ilovalar orqali xavfsizlikni kuchaytiring.
            </p>
            <button 
              onClick={handleMfaSetup} 
              className="btn-primary" 
              disabled={isSubmitting}
            >
              MFA-ni yoqish
            </button>
          </div>
        )}

        {mfaStatus === "setup" && qrCode && (
          <div>
            <p className="text-sm text-ink-muted mb-4">
              1. Quyidagi QR kodni Authenticator ilovasida skanerlang.
            </p>
            <div className="bg-white inline-block p-2 border rounded-lg mb-4">
              <Image src={qrCode} alt="MFA QR Code" width={200} height={200} />
            </div>
            
            <p className="text-sm text-ink-muted mb-4">
              2. Ilovadagi 6 xonali kodni kiriting.
            </p>
            <form onSubmit={handleMfaVerify} className="flex gap-4 items-end">
              <div className="flex-1">
                <Field
                  label="MFA Kod"
                  type="text"
                  name="mfaCode"
                  value={mfaCode}
                  onChange={(e) => setMfaCode(e.target.value)}
                  required
                />
              </div>
              <button type="submit" className="btn-primary mb-1" disabled={isSubmitting}>
                Tasdiqlash
              </button>
            </form>
          </div>
        )}

        {mfaStatus === "success" && (
          <div className="rounded-lg bg-income/10 px-4 py-3 text-sm text-income border border-income/20">
            MFA muvaffaqiyatli yoqildi! Endi kirishda har doim ushbu kod so'raladi.
          </div>
        )}

        {error && (
          <p className="mt-4 rounded-lg bg-expense/10 px-3.5 py-2.5 text-sm text-expense">
            {error}
          </p>
        )}
      </div>
    </div>
  );
}
