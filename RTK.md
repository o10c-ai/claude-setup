# RTK — token-efficient command output

`rtk` filters and compresses dev-command output (60-90% fewer tokens, <10ms
overhead) before it enters context. A PreToolUse:Bash hook auto-rewrites
eligible commands to `rtk <cmd>` for you, so you normally don't type `rtk`
yourself. The hook only covers the **Bash** tool — for the `Read`/`Grep`/`Glob`
built-ins it does nothing, so when you want compact output there, prefer shell
commands or call `rtk` explicitly:

- `rtk read <file>`, `rtk grep "<pat>" <path>`, `rtk find "<glob>" <path>`,
  `rtk ls <path>` — compact file/search/listing output.

Commands rtk compresses (non-exhaustive; `rtk` knows 100+):

| Area | Examples |
|---|---|
| git | `git status`, `git log`, `git diff`, `git add/commit/push/pull` |
| rust | `cargo test`, `cargo build`, `cargo clippy` |
| test | `pytest`, `go test`, `golangci-lint run` |
| docker | `docker ps`, `docker images`, `docker logs`, `docker compose ps` |
| k8s | `kubectl pods`, `kubectl logs`, `kubectl services` |
| python | `pip list`, `pip outdated` (auto-detects uv) |
| files | `ls`, `find`, `grep`, `cat`/`head`/`tail` |

Mutating commands (e.g. `git push`) are still surfaced for confirmation by
rtk's own permission rules — the hook does not silently auto-run them.

Set `RTK_HOOK_AUDIT=1` to log every rewrite decision to
`~/.local/share/rtk/hook-audit.log`. See `rtk gain` for cumulative savings.
