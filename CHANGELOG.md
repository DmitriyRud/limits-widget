# Changelog

All notable changes to **Limits Widget** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-20

### Added
- **Desktop-level macOS widget** (`NSPanel` above desktop icons, below regular windows) with frosted dark/light styling, dragging, and persistent screen position.
- **Claude Code provider** — tracks 5-hour, weekly, and optional Opus/Sonnet weekly limits (read-only Keychain / fallback credentials).
- **Codex CLI provider** — tracks 5-hour and weekly limits via `chatgpt.com/backend-api/wham/usage` with automatic fallback to local `~/.codex/sessions` logs.
- **Antigravity provider** — tracks all 5 quota pools (`Gemini · 5h`, `Gemini · Weekly`, `Claude & GPT · 5h`, `Claude & GPT · Weekly`, `Gemini 4 Argon · Weekly`) via local `agy --hub` loopback RPC (`RetrieveUserQuotaSummary`, fallback `GetUserStatus`) with zero internet calls.
- **Color-coded progress bars & live countdowns** — green (> 30% left), orange (10–30%), red (≤ 10%); 1-minute offline countdown updates and hover tooltips with exact reset times.
- **Stale data handling** — displays data freshness timestamp (`as of HH:mm` / date) and keeps last valid snapshot marked `stale` when a refresh fails.
- **Menu bar & Settings window** — manual refresh, per-agent toggles, configurable refresh interval (60s–3600s), and Launch at login (`.app` bundle).
- **11 UI languages** — English (default), German, Spanish, French, Italian, Norwegian, Icelandic, Finnish, Chinese (Simplified), Japanese, and Russian with instant live switching.
- **Security & test suite** — strict per-provider host allowlists with redirects disabled, redacted credential models, and 171 Swift Testing unit tests.
