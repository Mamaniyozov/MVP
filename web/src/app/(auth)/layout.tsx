import { Logo } from "@/components/Logo";

const STATS = [
  { value: "6", label: "moliyaviy modul: xarajat, daromad, karta, kategoriya, maqsad, tahlil" },
  { value: "1 joy", label: "telefon va brauzerdagi bitta hisobingiz doim sinxron" },
  { value: "0 so'm", label: "yashirin to'lov — shaxsiy loyiha, ochiq API" },
];

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid min-h-screen lg:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
      <section className="relative hidden flex-col justify-between overflow-hidden bg-brand px-12 py-10 text-white lg:flex">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[0.14]"
          style={{
            backgroundImage:
              "repeating-linear-gradient(transparent, transparent 47px, rgba(255,255,255,0.5) 47px, rgba(255,255,255,0.5) 48px)",
          }}
        />
        <Logo tone="light" />

        <div className="relative max-w-md">
          <p className="font-display text-[2.75rem] leading-[1.05] font-semibold tracking-tight">
            Har bir so&apos;m — o&apos;z qatorida.
          </p>
          <p className="mt-4 text-[15px] leading-relaxed text-white/75">
            Hisob xarajat va daromadingizni bitta reestrga yozadi: kategoriya, karta,
            maqsad va tahlil — hammasi bir joyda, mobil ilova bilan sinxron.
          </p>
        </div>

        <dl className="relative grid grid-cols-1 gap-5 border-t border-white/15 pt-6">
          {STATS.map((stat) => (
            <div key={stat.label} className="flex items-baseline gap-3">
              <dt className="font-mono text-lg font-semibold tabular-nums">{stat.value}</dt>
              <dd className="text-sm text-white/70">{stat.label}</dd>
            </div>
          ))}
        </dl>
      </section>

      <section className="flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 lg:hidden">
            <Logo />
          </div>
          {children}
        </div>
      </section>
    </div>
  );
}
