export function Logo({ className = "", tone = "brand" }: { className?: string; tone?: "brand" | "light" }) {
  const stroke = tone === "light" ? "#F3F6F4" : "#0F6B4C";
  return (
    <span className={`inline-flex items-center gap-2 font-display font-semibold tracking-tight ${className}`}>
      <svg width="26" height="26" viewBox="0 0 26 26" fill="none" aria-hidden="true">
        <rect x="1" y="1" width="24" height="24" rx="7" stroke={stroke} strokeWidth="1.6" />
        <path d="M6.5 9H19.5" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" />
        <path d="M6.5 13H15" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" />
        <path d="M6.5 17H12.5" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" />
      </svg>
      Hisob
    </span>
  );
}
