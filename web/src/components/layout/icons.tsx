type IconProps = { className?: string };

const base = "1.6" as const;

export function IconGrid({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <rect x="2.5" y="2.5" width="6" height="6" rx="1.4" stroke="currentColor" strokeWidth={base} />
      <rect x="11.5" y="2.5" width="6" height="6" rx="1.4" stroke="currentColor" strokeWidth={base} />
      <rect x="2.5" y="11.5" width="6" height="6" rx="1.4" stroke="currentColor" strokeWidth={base} />
      <rect x="11.5" y="11.5" width="6" height="6" rx="1.4" stroke="currentColor" strokeWidth={base} />
    </svg>
  );
}

export function IconLedger({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <rect x="3" y="2.5" width="14" height="15" rx="1.6" stroke="currentColor" strokeWidth={base} />
      <path d="M6 7h8M6 10.3h8M6 13.6h5" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
    </svg>
  );
}

export function IconTag({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path
        d="M10.6 3H4.6C3.7 3 3 3.7 3 4.6v6c0 .4.2.8.5 1.1l7.8 7.8c.6.6 1.5.6 2.1 0l6-6c.6-.6.6-1.5 0-2.1L11.6 3.5c-.3-.3-.7-.5-1-.5Z"
        stroke="currentColor"
        strokeWidth={base}
        strokeLinejoin="round"
      />
      <circle cx="7.2" cy="7.2" r="1.2" stroke="currentColor" strokeWidth={base} />
    </svg>
  );
}

export function IconCard({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <rect x="2.5" y="4.5" width="15" height="11" rx="1.8" stroke="currentColor" strokeWidth={base} />
      <path d="M2.5 8h15" stroke="currentColor" strokeWidth={base} />
      <path d="M5.5 12h4" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
    </svg>
  );
}

export function IconFlag({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path d="M5 17.5V3" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
      <path
        d="M5 4h9.3c.9 0 1.3 1.1.6 1.7l-2.4 2.1 2.4 2.1c.7.6.3 1.7-.6 1.7H5"
        stroke="currentColor"
        strokeWidth={base}
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function IconChart({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path d="M3 17V3" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
      <path d="M3 17h14" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
      <path d="M6.5 14v-4M10.5 14V7M14.5 14v-6.5" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
    </svg>
  );
}

export function IconLogout({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path
        d="M8 17H4.8c-.7 0-1.3-.6-1.3-1.3V4.3C3.5 3.6 4.1 3 4.8 3H8"
        stroke="currentColor"
        strokeWidth={base}
        strokeLinecap="round"
      />
      <path d="M13 13.5 17 10l-4-3.5" stroke="currentColor" strokeWidth={base} strokeLinecap="round" strokeLinejoin="round" />
      <path d="M17 10H8" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
    </svg>
  );
}

export function IconPlus({ className }: IconProps) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path d="M10 4v12M4 10h12" stroke="currentColor" strokeWidth={base} strokeLinecap="round" />
    </svg>
  );
}
