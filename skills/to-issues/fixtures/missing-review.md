## What to build

When an operator archives a workspace, its scheduled jobs stop firing and the
workspace shows an "Archived" badge. Unarchiving restores the schedule.

## Predicate

`mix test test/workspaces/archive_test.exs` green

## You see

The workspace card shows the "Archived" badge and no new job rows appear.

## Verify

- unit: test/workspaces/archive_test.exs gains "archiving pauses schedules"; `mix test test/workspaces/archive_test.exs`
- live: archive a seeded workspace in the admin UI; the badge appears and the scheduler log stays quiet for one tick
- perf: n/a: no hot path

## Review gate

none

## Depends on

None — can start immediately

## Prototype

none
