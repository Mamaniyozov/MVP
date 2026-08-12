import axios from "axios";
import { API_BASE_URL } from "./client";
import type { User } from "../types";

interface TokenPair {
  access: string;
  refresh: string;
}

export interface LoginResponse {
  access?: string;
  refresh?: string;
  mfa_required?: boolean;
  temp_token?: string;
}

export async function login(email: string, password: string): Promise<LoginResponse> {
  const { data } = await axios.post<LoginResponse>(`${API_BASE_URL}/auth/login/`, { email, password });
  return data;
}

export async function requestOTP(phone_number: string): Promise<{ detail: string, otp?: string }> {
  const { data } = await axios.post(`${API_BASE_URL}/auth/otp/request/`, { phone_number });
  return data;
}

export async function verifyOTP(phone_number: string, otp: string): Promise<LoginResponse> {
  const { data } = await axios.post<LoginResponse>(`${API_BASE_URL}/auth/otp/verify/`, { phone_number, otp });
  return data;
}

export async function setupMFA(accessToken: string): Promise<{ detail: string, qr_code: string }> {
  const { data } = await axios.post(`${API_BASE_URL}/auth/mfa/setup/`, {}, {
    headers: { Authorization: `Bearer ${accessToken}` }
  });
  return data;
}

export async function verifyMFA(token: string, tempToken?: string, accessToken?: string): Promise<LoginResponse | { detail: string }> {
  const headers = accessToken ? { Authorization: `Bearer ${accessToken}` } : undefined;
  const payload: any = { token };
  if (tempToken) payload.temp_token = tempToken;
  
  const { data } = await axios.post(`${API_BASE_URL}/auth/mfa/verify/`, payload, { headers });
  return data;
}

export async function registerPhone(phone_number: string, accessToken: string): Promise<{ detail: string, phone_number: string }> {
  const { data } = await axios.post(`${API_BASE_URL}/auth/phone/register/`, { phone_number }, {
    headers: { Authorization: `Bearer ${accessToken}` }
  });
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

