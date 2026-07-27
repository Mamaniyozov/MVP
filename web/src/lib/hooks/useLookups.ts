"use client";

import { useMemo } from "react";
import { cardsApi, categoriesApi, unwrapList } from "@/lib/api/resources";
import { useAsync } from "./useAsync";

export function useLookups() {
  const categories = useAsync(() => categoriesApi.list().then(unwrapList), []);
  const cards = useAsync(() => cardsApi.list().then(unwrapList), []);

  const categoryName = useMemo(() => {
    const map = new Map((categories.data ?? []).map((c) => [c.id, c.name]));
    return (id: number | null) => (id !== null ? map.get(id) ?? "Kategoriyasiz" : "Kategoriyasiz");
  }, [categories.data]);

  const cardName = useMemo(() => {
    const map = new Map((cards.data ?? []).map((c) => [c.id, c.name]));
    return (id: number | null) => (id !== null ? map.get(id) ?? null : null);
  }, [cards.data]);

  return {
    categories: categories.data ?? [],
    cards: cards.data ?? [],
    categoryName,
    cardName,
    isLoading: categories.isLoading || cards.isLoading,
    reloadCategories: categories.reload,
    reloadCards: cards.reload,
  };
}
