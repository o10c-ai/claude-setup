# Notices

This repository is MIT licensed (see `LICENSE`). It vendors and derives from
the following projects; each keeps its own license in its `vendor/` checkout.

| Project | Upstream | License found | How it is used |
|---|---|---|---|
| pstack-claude | [michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude) | MIT (`vendor/pstack-claude/LICENSE`) | `show-me-your-work`, `figure-it-out`, `principle-never-block-on-the-human` symlinked from the checkout; `autonomous-run` distilled from its playbooks; `/review` and `to-prd` borrow its verification and decomposition rules |
| mattpocock/skills | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT (`vendor/mattpocock-skills/LICENSE`) | engineering skills symlinked from the checkout; `grill-with-docs`, `to-prd`, `to-issues` are overrides of its originals and bundle its `CONTEXT-FORMAT.md` / `ADR-FORMAT.md` |
| cmux-skills | [manaflow-ai/cmux-skills](https://github.com/manaflow-ai/cmux-skills) | MIT (`vendor/cmux-skills/LICENSE`) | reference for the `cmux-browser` and `show-in-pane` skills; not symlinked |
| rtk | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | see upstream repository | `hooks/rtk-rewrite.sh` is vendored verbatim from the rtk repo (`rtk-hook-version: 3`) |

Attribution notices above are required by the MIT license of each upstream;
their copyright lines are in the respective `LICENSE` files.
