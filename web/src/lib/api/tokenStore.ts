const ACCESS_KEY = "hisob_access";
const REFRESH_KEY = "hisob_refresh";

/** Thin wrapper around localStorage so the rest of the app never touches
 * storage keys directly — mirrors the mobile client's secure-storage boundary. */
export const tokenStore = {
  getAccess(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem(ACCESS_KEY);
  },
  getRefresh(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem(REFRESH_KEY);
  },
  set(access: string, refresh: string) {
    localStorage.setItem(ACCESS_KEY, access);
    localStorage.setItem(REFRESH_KEY, refresh);
  },
  setAccess(access: string) {
    localStorage.setItem(ACCESS_KEY, access);
  },
  clear() {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
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
