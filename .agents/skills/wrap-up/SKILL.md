---
name: wrap-up
description: Handles session closures, records major architectural decisions in PROJECT.md, and overwrites ROADMAP.md with current progress.
---

# Wrap-Up Skill

Use this skill at the end of a work session or sprint to ensure project state and memory are cleanly documented and synchronized.

## Session Wrap-Up Workflow

### 1. Review Work & Outcomes
- Identify all tasks and components modified or tested during this session.
- Check build status and ensure no unfinished or breaking changes are left uncommitted/untested.

### 2. Update `PROJECT.md`
- If any architectural decisions, API choices, or design pivots occurred, append an entry to the **Key Architectural Decisions Log** in `PROJECT.md`.
- Include: Date, Decision, Rationale, and Alternatives Considered.

### 3. Synchronize `ROADMAP.md`
- **Rule:** Always **overwrite** `ROADMAP.md` completely. Never append.
- Update the following sections:
  - **Current Status**: Set to active sprint / milestone.
  - **Last Updated**: Current date.
  - **Live Blocker**: List any active blockers or note "None".
  - **Sprint Checklist**: Mark completed items with `[x]`, in-progress items with `[/]` or notes, and pending items with `[ ]`.
  - **Immediate Next Step**: Define the exact task to start on when resuming.

### 4. Clean Up Temporary Artifacts
- Remove or archive any scratch files or test binaries that are no longer needed.
- Verify workspace integrity.

### 5. Final Report
- Provide the user with a concise summary of accomplishments, updated roadmap status, and the immediate next step.
