import { apiClient } from "./client";
import type {
  Card,
  Category,
  CategoryBreakdownRow,
  Goal,
  MonthlyReport,
  MonthlyTrendRow,
  Paginated,
  Transaction,
} from "../types";

// ---- Categories ----
export const categoriesApi = {
  list: () => apiClient.get<Category[] | Paginated<Category>>("/categories/").then((r) => r.data),
  create: (payload: Pick<Category, "name" | "type" | "icon">) =>
    apiClient.post<Category>("/categories/", payload).then((r) => r.data),
  update: (id: number, payload: Partial<Pick<Category, "name" | "type" | "icon">>) =>
    apiClient.patch<Category>(`/categories/${id}/`, payload).then((r) => r.data),
  remove: (id: number) => apiClient.delete(`/categories/${id}/`),
};

// ---- Cards ----
export const cardsApi = {
  list: () => apiClient.get<Card[] | Paginated<Card>>("/cards/").then((r) => r.data),
  create: (payload: Pick<Card, "name" | "last4">) =>
    apiClient.post<Card>("/cards/", payload).then((r) => r.data),
  update: (id: number, payload: Partial<Pick<Card, "name" | "last4">>) =>
    apiClient.patch<Card>(`/cards/${id}/`, payload).then((r) => r.data),
  remove: (id: number) => apiClient.delete(`/cards/${id}/`),
};

// ---- Transactions ----
export interface TransactionFilters {
  category?: number;
  type?: "income" | "expense";
  card?: number;
  date_from?: string;
  date_to?: string;
  page?: number;
  ordering?: string;
}

export const transactionsApi = {
  list: (filters: TransactionFilters = {}) =>
    apiClient
      .get<Paginated<Transaction>>("/transactions/", { params: filters })
      .then((r) => r.data),
  create: (payload: Omit<Transaction, "id" | "created_at">) =>
    apiClient.post<Transaction>("/transactions/", payload).then((r) => r.data),
  update: (id: number, payload: Partial<Omit<Transaction, "id" | "created_at">>) =>
    apiClient.patch<Transaction>(`/transactions/${id}/`, payload).then((r) => r.data),
  remove: (id: number) => apiClient.delete(`/transactions/${id}/`),
};

// ---- Goals ----
export const goalsApi = {
  list: () => apiClient.get<Goal[] | Paginated<Goal>>("/goals/").then((r) => r.data),
  get: (id: number) => apiClient.get<Goal>(`/goals/${id}/`).then((r) => r.data),
  create: (payload: Pick<Goal, "name" | "target_amount" | "deadline">) =>
    apiClient.post<Goal>("/goals/", payload).then((r) => r.data),
  update: (id: number, payload: Partial<Pick<Goal, "name" | "target_amount" | "deadline">>) =>
    apiClient.patch<Goal>(`/goals/${id}/`, payload).then((r) => r.data),
  remove: (id: number) => apiClient.delete(`/goals/${id}/`),
  addProgress: (id: number, amount: string) =>
    apiClient.post<Goal>(`/goals/${id}/add-progress/`, { amount }).then((r) => r.data),
};

// ---- Analytics ----
export const analyticsApi = {
  categoryBreakdown: (month: number, year: number) =>
    apiClient
      .get<CategoryBreakdownRow[]>("/analytics/category-breakdown/", { params: { month, year } })
      .then((r) => r.data),
  monthlyTrend: (months = 6) =>
    apiClient
      .get<MonthlyTrendRow[]>("/analytics/monthly-trend/", { params: { months } })
      .then((r) => r.data),
  monthlyReport: (month: number, year: number) =>
    apiClient
      .get<MonthlyReport>("/analytics/monthly-report/", { params: { month, year } })
      .then((r) => r.data),
};

/** DRF pagination can be toggled off per view; normalize either shape to an array. */
export function unwrapList<T>(data: T[] | Paginated<T>): T[] {
  return Array.isArray(data) ? data : data.results;
}
