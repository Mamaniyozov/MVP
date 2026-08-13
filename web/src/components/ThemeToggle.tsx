"use client";

import { useEffect, useState } from "react";
import { Sun, Moon } from "lucide-react";

function applyTheme(theme: "dark" | "light") {
  document.documentElement.classList.toggle("dark", theme === "dark");
  localStorage.setItem("hisob-theme", theme);
}

export function ThemeToggle() {
  const [theme, setTheme] = useState<"dark" | "light" | null>(null);

  useEffect(() => {
    setTheme(document.documentElement.classList.contains("dark") ? "dark" : "light");
  }, []);

  if (!theme) {
    // Avoid a mismatched icon flash before hydration reads the real state.
    return <span className="h-8 w-8 shrink-0" aria-hidden />;
  }

  const next = theme === "dark" ? "light" : "dark";

  return (
    <button
      type="button"
      onClick={() => {
        applyTheme(next);
        setTheme(next);
      }}
      className="flex h-8 w-8 shrink-0 cursor-pointer items-center justify-center rounded-full text-ink-muted transition-colors duration-200 hover:bg-paper hover:text-ink dark:hover:bg-white/5 dark:hover:text-ink-dark"
      aria-label={theme === "dark" ? "Yorug' rejimga o'tish" : "Qorong'i rejimga o'tish"}
      title={theme === "dark" ? "Yorug' rejim" : "Qorong'i rejim"}
    >
      {theme === "dark" ? (
        <Sun size={16} strokeWidth={1.5} aria-hidden />
      ) : (
        <Moon size={16} strokeWidth={1.5} aria-hidden />
      )}
    </button>
  );
}
