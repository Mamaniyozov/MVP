const currencyFormatter = new Intl.NumberFormat("uz-UZ", {
  maximumFractionDigits: 0,
});

export function formatSum(value: string | number): string {
  return currencyFormatter.format(Number(value));
}

export function formatSigned(value: string | number, type: "income" | "expense"): string {
  const sign = type === "income" ? "+" : "−";
  return `${sign}${formatSum(Math.abs(Number(value)))}`;
}

const dateFormatter = new Intl.DateTimeFormat("uz-UZ", { day: "2-digit", month: "short" });
const fullDateFormatter = new Intl.DateTimeFormat("uz-UZ", {
  day: "2-digit",
  month: "long",
  year: "numeric",
});

export function formatDate(value: string): string {
  return dateFormatter.format(new Date(value));
}

export function formatFullDate(value: string): string {
  return fullDateFormatter.format(new Date(value));
}

const MONTH_NAMES = [
  "Yanvar",
  "Fevral",
  "Mart",
  "Aprel",
  "May",
  "Iyun",
  "Iyul",
  "Avgust",
  "Sentabr",
  "Oktabr",
  "Noyabr",
  "Dekabr",
];

export function monthLabel(yyyyMm: string): string {
  const [, m] = yyyyMm.split("-");
  const index = Number(m) - 1;
  return MONTH_NAMES[index]?.slice(0, 3) ?? yyyyMm;
}

export function monthName(month: number): string {
  return MONTH_NAMES[month - 1] ?? String(month);
}
