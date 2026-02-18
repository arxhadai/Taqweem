---
description: Git workflow rules for the Ramzan Companion Flutter project
---
// turbo-all

## Branch Strategy

- `main` → production-ready (never commit directly)
- `dev` → integration branch
- `feature/<name>` → new features
- `fix/<name>` → bug fixes
- `refactor/<area>` → internal improvements

## Commit Format

```
type(scope): short summary

Detailed explanation if needed
```

**Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `perf`

## After Every Code Change

1. Run `flutter analyze`
2. Run `flutter pub get` if dependencies changed
3. Stage only relevant files: `git add <files>`
4. Commit with structured message
5. Push to the current feature/fix branch
6. Merge into `dev` only after verification
7. Never commit directly to `main`

## Release Process

1. Merge `dev` → `main`
2. Create annotated tag: `git tag -a v<version> -m "<description>"`
3. Push tags: `git push origin --tags`

## Safety Rules

- Never force push to `main`
- Never commit debug logs, `.env`, or keystore files
- Keep `.gitignore` clean
