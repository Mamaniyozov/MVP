import axios from "axios";
import { API_BASE_URL } from "./client";
import type { User } from "../types";

interface TokenPair {
  access: string;
  refresh: string;
}

export async function login(email: string, password: string): Promise<TokenPair> {
  const { data } = await axios.post<TokenPair>(`${API_BASE_URL}/auth/login/`, { email, password });
  return data;
}

export async function register(email: string, password: string, password2: string): Promise<User> {
  const { data } = await axios.post<User>(`${API_BASE_URL}/auth/register/`, {
    email,
    password,
    password2,
  });
  return data;
}

export interface PasswordResetResponse {
  detail: string;
  uid?: string;
  token?: string;
}

export async function requestPasswordReset(email: string): Promise<PasswordResetResponse> {
  const { data } = await axios.post<PasswordResetResponse>(`${API_BASE_URL}/auth/password-reset/`, { email });
  return data;
}

export async function confirmPasswordReset(
  uid: string,
  token: string,
  new_password: string
): Promise<{ detail: string }> {
  const { data } = await axios.post<{ detail: string }>(`${API_BASE_URL}/auth/password-reset/confirm/`, {
    uid,
    token,
    new_password,
  });
  return data;
}

