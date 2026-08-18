"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import * as authApi from "@/lib/api/auth";
import { forceLogoutBus, tokenStore } from "@/lib/api/tokenStore";

const EMAIL_KEY = "hisob_user_email";

interface AuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  email: string | null;
}

interface AuthContextValue extends AuthState {
  login: (email: string, password: string) => Promise<authApi.LoginResponse>;
  completeLogin: (email: string, access?: string, refresh?: string) => void;
  register: (email: string, password: string, password2: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [state, setState] = useState<AuthState>({
    isAuthenticated: false,
    isLoading: true,
    email: null,
  });

  useEffect(() => {
    setState({
      isAuthenticated: Boolean(tokenStore.getAccess()),
      isLoading: false,
      email: localStorage.getItem(EMAIL_KEY),
    });
  }, []);

  const logout = useCallback(() => {
    tokenStore.clear();
    localStorage.removeItem(EMAIL_KEY);
    setState({ isAuthenticated: false, isLoading: false, email: null });
    router.replace("/login");
  }, [router]);

  useEffect(() => forceLogoutBus.subscribe(logout), [logout]);

  const completeLogin = useCallback((email: string, access?: string, refresh?: string) => {
    tokenStore.set(access, refresh);
    localStorage.setItem(EMAIL_KEY, email);
    setState({ isAuthenticated: true, isLoading: false, email });
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const res = await authApi.login(email, password);
    if (!res.mfa_required) {
      completeLogin(email, res.access, res.refresh);
    }
    return res;
  }, [completeLogin]);

  const register = useCallback(
    async (email: string, password: string, password2: string) => {
      await authApi.register(email, password, password2);
      await login(email, password);
    },
    [login],
  );

  const value = useMemo(
    () => ({ ...state, login, completeLogin, register, logout }),
    [state, login, completeLogin, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
