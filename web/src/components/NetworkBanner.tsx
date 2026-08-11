'use client';

import React from 'react';
import { useNetworkStatus } from '@/lib/hooks/useNetworkStatus';

/**
 * Glassmorphic network status banner alerting users when working offline.
 */
export function NetworkBanner() {
  const { isOnline } = useNetworkStatus();

  if (isOnline) return null;

  return (
    <div
      id="network-offline-banner"
      role="alert"
      className="fixed bottom-4 right-4 z-50 flex items-center gap-3 px-4 py-3 bg-amber-950/90 text-amber-200 border border-amber-500/30 rounded-xl shadow-2xl backdrop-blur-md transition-all duration-300 animate-bounce"
    >
      <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping" />
      <div className="text-sm font-medium">
        <span className="font-semibold">Oflayn rejim:</span> Internet aloqasi yo'q. O'zgarishlar mahalliy keshda saqlanmoqda.
      </div>
    </div>
  );
}
