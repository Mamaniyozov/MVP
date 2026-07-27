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
