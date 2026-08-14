import axios, { AxiosError, type InternalAxiosRequestConfig } from "axios";
import { forceLogoutBus, tokenStore } from "./tokenStore";

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";

export const apiClient = axios.create({ 
  baseURL: API_BASE_URL,
  withCredentials: true // Important for sending/receiving HttpOnly cookies
});

async function refreshAccessToken(): Promise<boolean> {
  try {
    // The browser will automatically send the refresh_token cookie
    await axios.post(`${API_BASE_URL}/auth/refresh/`, {}, { withCredentials: true });
    return true;
  } catch {
    return false;
  }
}

interface RetriableConfig extends InternalAxiosRequestConfig {
  _retried?: boolean;
}

let refreshPromise: Promise<boolean> | null = null;
let activeRequests = 0;

const updateLoadingState = () => {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new CustomEvent("api_loading", { detail: { isLoading: activeRequests > 0 } }));
  }
};

apiClient.interceptors.request.use((config) => {
  activeRequests++;
  updateLoadingState();
  return config;
});

apiClient.interceptors.response.use(
  (response) => {
    activeRequests = Math.max(0, activeRequests - 1);
    updateLoadingState();
    return response;
  },
  async (error: AxiosError) => {
    activeRequests = Math.max(0, activeRequests - 1);
    updateLoadingState();

    const original = error.config as RetriableConfig | undefined;
    const isAuthEndpoint = original?.url?.includes("/auth/");

    if (error.response?.status === 401 && original && !original._retried && !isAuthEndpoint) {
      original._retried = true;

      refreshPromise ??= refreshAccessToken().finally(() => {
        refreshPromise = null;
      });
      const success = await refreshPromise;

      if (success) {
        // Cookies were set by the refresh endpoint, just retry the request
        return apiClient(original);
      }

      tokenStore.clear();
      forceLogoutBus.emit();
    } else if (error.response?.status !== 401 && typeof window !== "undefined") {
      // Dispatch a generic error event for global toast/notification handling
      window.dispatchEvent(new CustomEvent("api_error", { 
        detail: { message: apiErrorMessage(error) } 
      }));
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
