# Security Policy

> Pulsar is pre-1.0 and a work in progress. It is **not intended for production
> use** yet, and there is no formal supported-version policy — only the latest
> `main` is maintained.

## Reporting a vulnerability

Please report security issues **privately** through GitHub's security advisory
feature rather than opening a public issue:

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Fill in the details — what you found, how to reproduce it, and the potential
   impact.

This keeps the report confidential until a fix is available. We'll acknowledge
your report and work with you on a resolution and disclosure timeline.

Please **do not** open a public GitHub issue, pull request, or discussion for
security-sensitive reports.

## Scope

Pulsar is a generator-first component library: its code is copied into user
applications. Reports about XSS, injection, or unsafe output handling in the
generated components are especially relevant.
