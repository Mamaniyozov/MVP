export type TxType = "income" | "expense";

export interface User {
  id: number;
  email: string;
}

export interface Category {
  id: number;
  name: string;
  type: TxType;
  icon: string;
  is_default: boolean;
}

export interface Card {
  id: number;
  name: string;
  last4: string;
}

export interface Transaction {
  id: number;
  category: number | null;
  card: number | null;
  amount: string;
  type: TxType;
  date: string;
  note: string;
  created_at: string;
}

export interface Paginated<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

export interface Goal {
  id: number;
  name: string;
  target_amount: string;
  current_amount: string;
  deadline: string | null;
  created_at: string;
  progress_percent: number;
}

export interface CategoryBreakdownRow {
  category: string;
  total: string;
  percent: number;
}

export interface MonthlyTrendRow {
  month: string;
  income: string;
  expense: string;
}

export interface MonthTotals {
  income: string;
  expense: string;
  savings: string;
}

export interface MonthlyReport {
  current_month: MonthTotals;
  previous_month: MonthTotals | null;
  change_percent: { income: number | null; expense: number | null; savings: number | null } | null;
  top_category_increase: { name: string; percent: number } | null;
  insights: string[];
}
