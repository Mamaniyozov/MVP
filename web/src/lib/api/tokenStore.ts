const ACCESS_KEY = "hisob_access";
const REFRESH_KEY = "hisob_refresh";

/** Thin wrapper around tokens (now managed via HttpOnly cookies by backend).
 * We keep this file mainly for the forceLogoutBus pattern.
 */
export const tokenStore = {
  // Mobile app might still use this, but web relies on cookies.
  // We keep empty methods to satisfy existing typescript usages
  // that haven't been fully refactored, or to allow mobile-web shared code.
  getAccess(): string | null {
    if (typeof window !== "undefined") {
      return localStorage.getItem("hisob_is_auth") === "true" ? "cookie_auth" : null;
    }
    return null;
  },
  getRefresh(): string | null {
    return null;
  },
  set(_access?: string, _refresh?: string) {
    if (typeof window !== "undefined") {
      localStorage.setItem("hisob_is_auth", "true");
    }
  },
  setAccess(_access: string) {
    // No-op for web
  },
  clear() {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hisob_is_auth");
    }
  },
};

type Listener = () => void;
const forceLogoutListeners = new Set<Listener>();

/** Force-logout event bus — same pattern as the mobile app's interceptor:
 * when a refresh fails, every subscriber (the auth context) is notified so
 * the whole UI drops back to the login screen in one place. */
export const forceLogoutBus = {
  subscribe(listener: Listener) {
    forceLogoutListeners.add(listener);
    return () => {
      forceLogoutListeners.delete(listener);
    };
  },
  emit() {
    forceLogoutListeners.forEach((listener) => listener());
  },
};
