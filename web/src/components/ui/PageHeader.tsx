export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-8 flex flex-wrap items-start justify-between gap-4 animate-fade-up">
      <div>
        <h1 className="font-display text-[1.75rem] font-semibold tracking-tight text-ink dark:text-ink-dark">
          {title}
        </h1>
        {subtitle ? (
          <p className="mt-1 text-sm text-ink-muted dark:text-ink-dark-muted">{subtitle}</p>
        ) : null}
      </div>
      {action}
    </div>
  );
}
