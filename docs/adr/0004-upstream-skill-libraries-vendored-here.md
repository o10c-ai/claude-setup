---
status: accepted
date: 2026-09-09
---

# Upstream skill libraries are submodules of this repo, not of the consuming nix config

`mattpocock/skills`, `michael-denyer/pstack-claude`, and `manaflow-ai/cmux-skills`
live under `vendor/` as submodules of this repo, and override skills reference
them by path relative to the repo root. The private nix config consumes this
repo as one recursive submodule and points its `vendoredSkill` helper at
`services/claude-setup/vendor/<repo>/<path>`. Before this, the three lived in
the nix repo's `services/` and overrides used absolute `~/.config/nix/services/`
paths, which made the skills unusable from any other checkout and kept two pin
sets. `symphony-claude` stays private in the nix repo.
