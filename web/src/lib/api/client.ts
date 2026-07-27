import axios, { AxiosError, type InternalAxiosRequestConfig } from "axios";
import { forceLogoutBus, tokenStore } from "./tokenStore";

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";

export const apiClient = axios.create({ baseURL: API_BASE_URL });

apiClient.interceptors.request.use((config) => {
  const access = tokenStore.getAccess();
  if (access) {
    config.headers.set("Authorization", `Bearer ${access}`);
  }
  return config;
});

let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  const refresh = tokenStore.getRefresh();
  if (!refresh) return null;

  try {
    const { data } = await axios.post<{ access: string }>(`${API_BASE_URL}/auth/refresh/`, {
      refresh,
    });
    tokenStore.setAccess(data.access);
    return data.access;
  } catch {
    return null;
  }
}

interface RetriableConfig extends InternalAxiosRequestConfig {
  _retried?: boolean;
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetriableConfig | undefined;
    const isAuthEndpoint = original?.url?.includes("/auth/");

    if (error.response?.status === 401 && original && !original._retried && !isAuthEndpoint) {
      original._retried = true;

      refreshPromise ??= refreshAccessToken().finally(() => {
        refreshPromise = null;
      });
      const newAccess = await refreshPromise;

      if (newAccess) {
        original.headers.set("Authorization", `Bearer ${newAccess}`);
        return apiClient(original);
      }

      tokenStore.clear();
      forceLogoutBus.emit();
    }

    return Promise.reject(error);
  },
);

export function apiErrorMessage(error: unknown, fallback = "Xatolik yuz berdi. Qayta urinib ko'ring."): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;
    if (typeof data === "string") return data;
    if (data && typeof data === "object") {
      const firstValue = Object.values(data as Record<string, unknown>)[0];
      if (Array.isArray(firstValue)) return String(firstValue[0]);
      if (typeof firstValue === "string") return firstValue;
    }
  }
  return fallback;
}
