# Seat — Server-side authorization

> One seat per file: read **only this file** when adjudicating this seat.
> Profile: [`../../../review.md`](../../../review.md).
> Adjudication is always *independent of the author*; `❌`/findings are not self-dismissible.

- **Trigger:** the diff adds or changes a `handle_event/3` that mutates data, a plug, a
  seed, or a domain action (Ash action, context function).
- **Rubric:** every mutating path is authorized on the server, never only by a UI `:if`
  or a hidden button. Policies live on the resource (Ash policies with the actor threaded
  through `actor:`), or in the context function's first clause; the LiveView passes the
  current user as actor and does not re-implement the rule. The mechanical
  `authorize?: false` scan is guard-delegated (project credo check); this seat judges
  *policy correctness*: is the rule the product wants, does the actor reach the policy,
  and are seeds, controllers, and LiveViews free of bootstrap allowlists. Canonical gate
  clause: a `%{is_admin: false}` (or equivalent) head that denies and flashes
  "Unauthorized", with a test that drives the event as the wrong actor.
- **Adjudication:** for each mutating path in the diff, name the policy or clause that
  denies the wrong actor and the test that proves it. A path with neither is `❌`. The
  author cannot close it with "only admins can reach that page".

## Evidence line

```
### Seat — Server-side authorization: ✅ / ❌ / N/A  · evidence: <mutating path → policy/clause file:line → denial test path:line | "no server-side check" | "no test">; authorize?: false guard → <result>
```
