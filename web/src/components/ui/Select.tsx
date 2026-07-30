"use client";

import { type SelectHTMLAttributes, forwardRef, useId } from "react";

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label: string;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { label, id, className = "", children, ...props },
  ref,
) {
  const generatedId = useId();
  const selectId = id ?? props.name ?? generatedId;

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={selectId} className="text-sm font-medium text-ink dark:text-ink-dark">
        {label}
      </label>
      {/* `select-native` pins the option-list colors; without it the popup
          inherits OS colors and goes unreadable in dark mode. */}
      <select ref={ref} id={selectId} className={`input select-native ${className}`} {...props}>
        {children}
      </select>
    </div>
  );
});
