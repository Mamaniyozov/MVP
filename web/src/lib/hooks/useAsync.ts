"use client";

import { useCallback, useEffect, useState } from "react";
import { apiErrorMessage } from "@/lib/api/client";

interface AsyncState<T> {
  data: T | null;
  isLoading: boolean;
  error: string | null;
}

/** Fetches `fn()` on mount and whenever `deps` change; exposes `reload` for
 * manual refetch after a mutation (create/update/delete). */
export function useAsync<T>(fn: () => Promise<T>, deps: unknown[] = []) {
  const [state, setState] = useState<AsyncState<T>>({ data: null, isLoading: true, error: null });

  const load = useCallback(() => {
    let cancelled = false;
    setState((prev) => ({ ...prev, isLoading: true, error: null }));

    fn()
      .then((data) => {
        if (!cancelled) setState({ data, isLoading: false, error: null });
      })
      .catch((err) => {
        if (!cancelled) setState({ data: null, isLoading: false, error: apiErrorMessage(err) });
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => load(), [load]);

  return { ...state, reload: load };
}
