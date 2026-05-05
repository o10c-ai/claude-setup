#!/usr/bin/env bash
# Redact known secret patterns from stdin → stdout.
#
# Used by Claude Code's PreToolUse hook on the Bash tool: the hook wraps
# every command in `( ... ) 2>&1 | redact-secrets.sh` so secrets that show
# up in command output (e.g. `op read`, `gh auth status` with GH_TOKEN env,
# `env | grep`, accidental `echo $GH_TOKEN`) never reach Claude's context.
#
# Defense in depth — the model could also be exposed to secrets via:
#   - file reads of credential files (Read tool)
#   - other tools that surface secret-shaped strings
# Those paths aren't covered here. This hook closes the most common leak
# vector (Bash output capture) and reduces blast radius from a class of
# operator mistakes (wrong shell-expansion fallback operator, etc.).
#
# Compatibility note: BSD sed (macOS default) does NOT support \b word
# boundaries. We rely on the distinctive prefixes themselves being unique
# enough to avoid false positives. Length minimums on the suffixes help.

set -u

exec sed -E '
  # Anthropic API keys / OAuth tokens (sk-ant-api03-..., sk-ant-oat-...).
  # Match first since `sk-ant-` is more specific than `sk-`.
  s/sk-ant-[A-Za-z0-9_-]{40,}/[REDACTED:anthropic]/g

  # GitHub fine-grained PATs (~80+ chars after prefix).
  s/github_pat_[A-Za-z0-9_]{40,}/[REDACTED:github-pat-fine]/g
  # GitHub classic PATs and other token types (36+ chars after prefix).
  s/ghp_[A-Za-z0-9]{30,}/[REDACTED:github-pat-classic]/g
  s/ghs_[A-Za-z0-9]{30,}/[REDACTED:github-server]/g
  s/gho_[A-Za-z0-9]{30,}/[REDACTED:github-oauth]/g
  s/ghu_[A-Za-z0-9]{30,}/[REDACTED:github-user-to-server]/g
  s/ghr_[A-Za-z0-9]{30,}/[REDACTED:github-refresh]/g

  # Linear API + OAuth.
  s/lin_api_[A-Za-z0-9]{30,}/[REDACTED:linear-api]/g
  s/lin_oauth_[A-Za-z0-9]{30,}/[REDACTED:linear-oauth]/g

  # Stripe.
  s/sk_live_[A-Za-z0-9]{20,}/[REDACTED:stripe-live]/g
  s/sk_test_[A-Za-z0-9]{20,}/[REDACTED:stripe-test]/g

  # Slack.
  s/xoxb-[A-Za-z0-9-]{20,}/[REDACTED:slack-bot]/g
  s/xoxp-[A-Za-z0-9-]{20,}/[REDACTED:slack-user]/g
  s/xoxa-[A-Za-z0-9-]{20,}/[REDACTED:slack-app]/g

  # AWS access keys (very specific format: AKIA + 16 uppercase alphanumerics).
  s/AKIA[A-Z0-9]{16}/[REDACTED:aws-access-key]/g
  s/ASIA[A-Z0-9]{16}/[REDACTED:aws-temp-key]/g

  # 1Password session tokens (op signin output).
  s/ops_[A-Za-z0-9]{40,}/[REDACTED:1password-session]/g

  # Generic OpenAI-shaped keys (sk- followed by long alphanumeric).
  # MUST come after sk-ant- pattern above (sed processes in order).
  s/sk-[A-Za-z0-9]{40,}/[REDACTED:openai]/g
'
