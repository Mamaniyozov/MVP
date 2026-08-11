# Security Audit & Vulnerability Detection Rules

Rule source: Agentpedia Codes (https://agentpedia.codes/rules/agentic-ai/security-audit-agent)

## Core Principles
1. **Input Sanitization**: Validate all incoming parameters against strict schemas before database or business logic processing.
2. **Output Encoding**: Prevent XSS by encoding dynamic HTML outputs and using parameterized queries for database interactions.
3. **CORS & Security Headers**: Configure strict CORS origins (`CORS_ALLOWED_ORIGINS`) and set security headers (X-Frame-Options, X-Content-Type-Options, HSTS).
4. **Secret Management**: Never commit credentials, JWT secrets, or `.env` files. Access secrets strictly via environment variables.
5. **Rate Limiting**: Enforce rate limiting on auth endpoints (`/login`, `/reset-password`, `/refresh`) to mitigate brute force attacks.
