# Next.js 15 App Router & React 19 Best Practices

Rule source: Agentpedia Codes (https://agentpedia.codes/rules/nextjs/nextjs-app-router-best-practices)

## Core Principles
1. **Server Components First**: Use React Server Components (RSC) by default for data fetching and layout rendering. Use `'use client'` only when state, effects, or browser event listeners are required.
2. **Server Actions for Mutations**: Use Server Actions for data modifications with proper input validation (using Zod or standard schemas).
3. **Optimized Asset Loading**: Utilize `next/image`, `next/font`, and `next/link` for Core Web Vitals optimization (LCP, CLS, INP).
4. **Streaming & Suspense**: Wrap async server components in `<Suspense>` boundaries with granular loading fallbacks.
5. **Error Boundaries**: Place `error.tsx` and `global-error.tsx` in route segments to handle runtime errors gracefully.
6. **Network & State Resilience**: Always handle offline/reconnection states gracefully on the client side.
