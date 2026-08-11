---
name: mobile-offline-first
description: Strategy and implementation rules for building offline-first mobile applications using Flutter, Hive local storage, optimistic UI updates, and background sync queues.
---

# Mobile Offline-First Skill

This skill details offline-first mobile app patterns using Hive local storage.

## Key Checklist
1. **Local Box Storage**: Initialize Hive boxes (`HiveService.init()`) before rendering main app views.
2. **Read Path**: Fetch from Hive local box first, render cached data, then trigger background HTTP fetch to update local cache.
3. **Write Path**: Update Hive local box immediately, enqueue offline mutation payload in `offline_mutations_box`, and attempt background HTTP sync.
4. **Network Reconnection Listener**: Listen to connectivity state change events. When connectivity is restored, process queued mutations sequentially (`getPendingMutations()`).
