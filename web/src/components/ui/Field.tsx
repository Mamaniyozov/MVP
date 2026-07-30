"use client";

import { type InputHTMLAttributes, forwardRef, useId } from "react";

interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
}

export const Field = forwardRef<HTMLInputElement, FieldProps>(function Field(
  { label, error, id, className = "", ...props },
  ref,
) {
  // Every input needs a label association. Callers often pass neither `id` nor
  // `name`, so fall back to a generated id that is stable across SSR/hydration.
  const generatedId = useId();
  const inputId = id ?? props.name ?? generatedId;
  const errorId = `${inputId}-error`;

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={inputId} className="text-sm font-medium text-ink dark:text-ink-dark">
        {label}
      </label>
      <input
        ref={ref}
        id={inputId}
        className={`input ${error ? "border-expense focus-visible:border-expense" : ""} ${className}`}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? errorId : undefined}
        {...props}
      />
      {error ? (
        <p id={errorId} className="text-xs text-expense">
          {error}
        </p>
      ) : null}
    </div>
  );
});
