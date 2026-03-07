---
name: security-awareness
description: Basic security review checklist for code changes. Covers OWASP top 10, secrets detection, and common vulnerability patterns. Use when reviewing implementation code for security issues, auditing for vulnerabilities, or checking for hardcoded secrets.
version: 1.0.0
---

# Security Awareness

This skill provides a lightweight security checklist for code review. It covers the most common vulnerability patterns without requiring deep security expertise.

## When to Use

- Reviewing implementation code for security issues
- Checking for hardcoded secrets or credentials
- Auditing authentication and authorization logic
- Validating input handling and output encoding
- Assessing data exposure risks

## Quick Security Checklist

For every code change, check each category:

### Injection

- [ ] User input sanitized before SQL/NoSQL queries
- [ ] User input escaped in HTML output (XSS prevention)
- [ ] User input validated before shell commands (command injection)
- [ ] Parameterized queries used (not string concatenation)
- [ ] No use of `eval()`, `exec()`, or equivalent with user input
- [ ] No template literal injection in queries or commands

| Pattern | Risk | Fix |
|---------|------|-----|
| `query("SELECT * FROM users WHERE id=" + userId)` | SQL injection | Use parameterized query |
| `element.innerHTML = userInput` | XSS | Use `textContent` or sanitize |
| `exec("cmd " + userArg)` | Command injection | Whitelist allowed values |
| `eval(userCode)` | Code injection | Remove or sandbox |
| `new Function(userInput)` | Code injection | Remove entirely |

### Authentication & Authorization

- [ ] Auth checks on all protected endpoints/routes
- [ ] Passwords hashed with strong algorithm (bcrypt/argon2, NOT MD5/SHA)
- [ ] Session tokens are cryptographically random
- [ ] No auth bypass in error paths or fallback logic
- [ ] Rate limiting on login/auth endpoints
- [ ] Token expiry enforced
- [ ] No privilege escalation paths (user accessing admin resources)

| Pattern | Risk | Fix |
|---------|------|-----|
| `if (user.isAdmin) // only check` | Missing auth middleware | Use route-level middleware |
| `md5(password)` | Weak hash | Use bcrypt with cost >= 12 |
| `Math.random()` for tokens | Predictable tokens | Use `crypto.randomBytes()` |
| `catch { return defaultUser }` | Auth bypass on error | Return 401 in catch |

### Secrets & Credentials

- [ ] No hardcoded passwords, API keys, or tokens in source code
- [ ] No secrets in log output or error messages
- [ ] `.env` files listed in `.gitignore`
- [ ] Secrets loaded from environment variables, not config files committed to git
- [ ] No secrets in URL query parameters (logged by proxies/servers)

| Pattern | Risk | Fix |
|---------|------|-----|
| `const API_KEY = "sk-abc123..."` | Exposed secret | Use `process.env.API_KEY` |
| `console.log("Auth token:", token)` | Secret in logs | Remove or mask |
| `fetch(url + "?key=" + apiKey)` | Secret in URL | Use headers |
| Committed `.env` file | Secret in git history | Add to `.gitignore`, rotate keys |

### Data Exposure

- [ ] Sensitive data not included in error messages or stack traces
- [ ] API responses don't leak internal IDs, paths, or implementation details
- [ ] Stack traces disabled in production responses
- [ ] PII follows data minimization (don't collect/store what you don't need)
- [ ] Sensitive fields excluded from serialization/logging

| Pattern | Risk | Fix |
|---------|------|-----|
| `res.json({ error: err.stack })` | Stack trace leak | Return generic message |
| `SELECT * FROM users` | Over-fetching PII | Select only needed columns |
| `console.log(request.body)` | PII in logs | Redact sensitive fields |

### Input Validation

- [ ] All external input validated at system boundary
- [ ] File uploads restricted by type and size
- [ ] Path traversal prevented (`../` in file paths)
- [ ] Redirect URLs validated against allowlist
- [ ] JSON/XML parsing wrapped in try/catch (DoS via malformed input)

| Pattern | Risk | Fix |
|---------|------|-----|
| `fs.readFile(req.params.path)` | Path traversal | Validate and resolve path |
| `res.redirect(req.query.next)` | Open redirect | Validate against allowlist |
| `JSON.parse(untrustedInput)` without catch | DoS crash | Wrap in try/catch |
| No file size limit | DoS via large upload | Set max size in config |

### Dependency Risk

- [ ] No known-vulnerable packages introduced (check package.json changes)
- [ ] No wildcard or unpinned dependency versions added
- [ ] No unnecessary new dependencies with broad permissions

## Severity Guidelines

| Finding | Severity | Action |
|---------|----------|--------|
| SQL/command injection | CRITICAL | Must fix before proceeding |
| Hardcoded secret | CRITICAL | Must fix, rotate credential |
| Auth bypass | CRITICAL | Must fix before proceeding |
| Missing input validation | WARNING | Fix if at system boundary |
| Weak hash algorithm | WARNING | Fix before production |
| Verbose error messages | WARNING | Fix before production |
| Missing rate limiting | INFO | Note for future improvement |
| Missing CSP headers | INFO | Note for future improvement |

## Review Output Format

When reporting security findings:

    ### Security Review
    | Check | Status | Details |
    |-------|--------|---------|
    | Injection | PASS/FAIL | <specifics> |
    | Auth | PASS/FAIL/N/A | <specifics> |
    | Secrets | PASS/FAIL | <specifics> |
    | Data exposure | PASS/FAIL | <specifics> |
    | Input validation | PASS/FAIL | <specifics> |

    ### Security Issues Found: <count>
    - [CRITICAL] <file:line> <description>
    - [WARNING] <file:line> <description>
    - [INFO] <description>
