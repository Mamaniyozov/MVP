import { type InputHTMLAttributes, forwardRef } from "react";

interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
}

export const Field = forwardRef<HTMLInputElement, FieldProps>(function Field(
  { label, error, id, className = "", ...props },
  ref,
) {
  const inputId = id ?? props.name;
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={inputId} className="text-sm font-medium text-ink dark:text-ink-dark">
        {label}
      </label>
      <input
        ref={ref}
        id={inputId}
        className={`input ${error ? "border-expense focus-visible:border-expense" : ""} ${className}`}
        aria-invalid={Boolean(error)}
        {...props}
      />
      {error ? <p className="text-xs text-expense">{error}</p> : null}
    </div>
  );
});
