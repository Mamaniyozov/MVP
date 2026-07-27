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
  login: (email: string, password: string) => Promise<void>;
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

  const login = useCallback(async (email: string, password: string) => {
    const tokens = await authApi.login(email, password);
    tokenStore.set(tokens.access, tokens.refresh);
    localStorage.setItem(EMAIL_KEY, email);
    setState({ isAuthenticated: true, isLoading: false, email });
  }, []);

  const register = useCallback(
    async (email: string, password: string, password2: string) => {
      await authApi.register(email, password, password2);
      await login(email, password);
    },
    [login],
  );

  const value = useMemo(
    () => ({ ...state, login, register, logout }),
    [state, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
