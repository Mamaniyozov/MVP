---
name: code-review-security
description: Protocols and checklists for evaluating code quality, security posture, JWT rotation, and user data isolation across fullstack repositories.
---

# Code Review & Security Audit Skill

This skill enforces quality and security standards across fullstack components.

## Audit Checklist
1. **User Isolation**: Verify all database queries filter by authenticated user `filter(user=request.user)`.
2. **Secrets Protection**: Confirm no secrets or `.env` variables exist in committed code.
3. **Type Safety**: Enforce `npx tsc --noEmit` clean build for Web and `flutter analyze` for Mobile.
4. **Test Coverage**: Run `pytest` for backend API suites and ensure all assertions pass.
