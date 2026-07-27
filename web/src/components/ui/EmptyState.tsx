export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="card flex flex-col items-center gap-2 px-6 py-14 text-center">
      <p className="font-display text-base font-semibold text-ink dark:text-ink-dark">{title}</p>
      {description ? <p className="max-w-sm text-sm text-ink-muted">{description}</p> : null}
      {action ? <div className="mt-2">{action}</div> : null}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="card flex flex-col items-center gap-3 px-6 py-14 text-center">
      <p className="text-sm text-expense">{message}</p>
      {onRetry ? (
        <button type="button" onClick={onRetry} className="btn-secondary">
          Qayta urinish
        </button>
      ) : null}
    </div>
  );
}

export function Spinner() {
  return (
    <div className="flex justify-center py-14">
      <div
        className="h-6 w-6 animate-spin rounded-full border-2 border-line border-t-brand"
        role="status"
        aria-label="Yuklanmoqda"
      />
    </div>
  );
}
