---
name: web-performance-optimization
description: Guidelines and tools for measuring and optimizing web vitals, dynamic bundle imports, and client rendering speed in Next.js applications.
---

# Web Performance Optimization Skill

This skill provides patterns for optimizing Next.js web applications.

## Key Checklist
1. **Dynamic Imports**: Use `next/dynamic` for heavy client components (charts, modal dialogs) to reduce initial bundle size.
2. **Font & Image Optimization**: Always use `next/font` for web fonts and `next/image` with explicit width/height and quality settings.
3. **Core Web Vitals**: Target LCP < 2.5s, INP < 200ms, and CLS < 0.1.
4. **Cache Control**: Set appropriate `Cache-Control` headers for API routes and static assets.
