---
name: remote-cli
description: Use when the user asks you to perform any Remote.com HR action — create or list time off, manage expenses (approve/decline/download receipts), list or create employments, view or amend employment contracts (salary changes, title changes, etc.), download payslips, submit terminations — via the remotecli CLI tool in this project. Also triggers when asked to look up leave balance, employment status, or company info through the CLI.
---

# Using the Remote CLI

## Overview

`remotecli` is the built binary for this project. Build it with `make build` if the binary is missing or stale after code changes.

Requires three environment variables:
```bash
export REMOTE_BASE_URL=https://gateway.remote.com/api/eor
export REMOTE_CLIENT_ID=<your_client_id>
export REMOTE_CLIENT_SECRET=<your_client_secret>
```

An **active company** must be selected before most commands:
```bash
remotecli companies list   # see what's saved
remotecli use              # interactively pick the active one
```

## Driving the CLI Autonomously

When acting without a human at the keyboard, every interactive prompt is friction — the TUI blocks waiting for keystrokes and your agent has no way to answer. Use this priority order; **top is always cheaper than bottom**:

### 1. Suppress the prompt with flags (preferred)

Every interactive picker has a flag equivalent. Resolve IDs via `list` filters, then pass them to the action. This requires zero special protocol and zero per-prompt round-trips.

```bash
# ❌ Picker fires — TUI blocks; the agent has no way to answer
remotecli contracts list

# ✅ Resolve the ID via a filter, then pass it
remotecli employments list --email alice@example.com --pretty
remotecli contracts list --employment-id emp_abc123
```

Same pattern for `expenses approve --expense-id`, `time-off approve --timeoff-id`, `payslips download --id`, `contract-amendments create --employment-id`, etc. See `references/commands.md` for the full flag inventory.

### 2. Use `--json-prompts` only when a prompt is unavoidable

Schema-driven flows (`employments create`, `contract-amendments create`) prompt for required fields the API doesn't expose as flags. For those, `--json-prompts` swaps the TUI for an NDJSON stdio protocol: stdout emits `{"type":"prompt", ...}` events, stdin takes one `{"answer": ...}` line per event, in order.

**Read the protocol first.** The complete spec lives in `CLAUDE.md` → "JSON prompter mode" (about 30 lines). It enumerates every event type and answer shape. Don't speculate at the format — read it once and you'll know exactly what to send.

Drive the whole flow in **one Bash call**, pre-computing every answer:

```bash
# After reading the schema (or doing a dry-run to learn the prompt order):
printf '%s\n' \
  '{"answer":"Alice Cooper"}' \
  '{"answer":"alice@example.com"}' \
  '{"answer":"2026-06-01"}' \
  | remotecli --json-prompts employments create --country GBR
```

Splitting the flow across multiple Bash tool calls multiplies permission prompts and breaks the pipe. One process, one pipeline, one permission.

**Discovering prompts: each probe should reveal many prompts, not one.** The prompter validates answers in order and emits the next prompt *before* reading its answer, so one Bash call with N valid answers reveals N+1 prompts. Pipe several plausible answers per probe call — `0` validates as a select or number, `"2026-06-01"` as a date, a sufficiently long string as `role_description` — and read every prompt the call emits before composing the next one. Two or three probe calls is usually enough to map a whole form; firing ten one-answer-at-a-time calls is the anti-pattern, because it costs permission prompts and round-trips for no information you couldn't have learned in a single pass. Stop probing the moment field names appear that match data you already have (`job_title`, `work_hours_per_week`, `annual_gross_salary` are all in `contracts list` output) and switch to a real run with the real values.

### 3. Never write a Python wrapper

If `printf | remotecli` can't express the flow, the answer is to read the schema and pre-compute the answers — **not** to wrap the CLI in `subprocess.Popen`. A wrapper script costs:

- File-write permission to create the script
- Python execution permission to run it
- A near-guaranteed stdin-buffering bug (forgetting `flush=True`, line-buffering on pipes)
- More permission prompts every time you iterate on the script

The CLI was designed for Unix pipes. If you're reaching for Python, you've misread the protocol — go back to step 2 and re-read the `JSON prompter mode` section.

### Red flags — stop and reconsider

| You're about to... | Instead, do this |
|---|---|
| Open an interactive picker via `--json-prompts` and try to answer it | Run the matching `list` command with a filter flag, pass the resulting ID via `--<resource>-id` |
| `cat answers.txt \| remotecli --json-prompts ...` after writing the file in a separate step | Inline the answers with `printf` in a single Bash call — no temp file, no extra permission prompt |
| `python wrapper.py` that calls `subprocess.Popen(["remotecli", ...])` | Stop. Read `CLAUDE.md` → "JSON prompter mode". Use `printf \| remotecli` instead |
| Run multiple Bash tool calls to drive one CLI invocation | One Bash call, one pipeline — the CLI process should not span tool invocations |

## Quick Command Reference

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `login` | Authenticate via browser (PKCE) | — |
| `use` | Pick active company (interactive) | — |
| `me` | Show current identity | `--company-token` |
| `companies list` | List saved companies | `--pretty` |
| `companies create` | Create a company | `--integration-token` |
| `employments list` | List employments | `--status`, `--email`, `--all` |
| `employments create` | Onboard a new employee | `--country` |
| `employments show <id>` | Get a single employment | — |
| `contracts list` | List contracts for an employment for historical contracts set the only-active to false | `--employment-id`, `--only-active=false` |
| `contract-amendments list` | List submitted contract amendments | `--employment-id`, `--status`, `--all` |
| `contract-amendments show <id>` | Show a single amendment | — |
| `contract-amendments create` | Submit a contract amendment | `--employment-id`, `--contract-id`, `--country` |
| `expenses list` | List expenses | `--all`, `--pretty` |
| `expenses create` | Submit an expense | `--employment-id`, `--amount`, `--currency`, `--expense-date`, `--title`, `--tax-amount` |
| `expenses approve` | Approve a pending expense | `--expense-id` |
| `expenses decline` | Decline a pending expense | `--expense-id`, `--reason` |
| `expenses download-receipt` | Download a receipt file | `--expense-id`, `--receipt-id`, `--out-file` |
| `payslips list` | List payslips | `--employment-id`, `--start-date`, `--end-date` |
| `payslips download` | Download a payslip PDF | `--id`, `--out-file` |
| `time-off policies` | List leave policies details | `--employment-id` |
| `time-off balance` | Show leave balance summary | `--employment-id` |
| `time-off create` | Create time off (approved if manager, requested if employee) | `--employment-id`, `--timeoff-type`, `--start-date`, `--end-date` |
| `time-off list` | List time off records | `--employment-id`, `--status`, `--timeoff-type` |
| `time-off approve` | Approve a requested time off | `--timeoff-id` |
| `time-off cancel` | Cancel an approved time off | `--timeoff-id`, `--reason` |
| `time-off decline` | Decline a requested time off | `--timeoff-id`, `--reason` |
| `terminations list` | List terminations | `--employment-id`, `--type` |
| `terminations create` | Submit a termination request | `--employment-id` |
| `cache clear` | Flush cached responses (all or by prefix) | `--resource` |
| `cache path` | Print the cache file path | — |

## Common Workflows

**Create time off for an employee:**
```bash
remotecli time-off create \
  --employment-id emp_abc123 \
  --timeoff-type time_off \
  --start-date 2026-05-09 \
  --end-date 2026-05-09
```
Common types: `time_off`, `sick_leave`, `paid_time_off`, `public_holiday`, `unpaid_leave`, `maternity_leave`, `paternity_leave`, `bereavement`. Full list in `references/commands.md`.

**List active employments:**
```bash
remotecli employments list --status active --pretty
```

**Approve a pending expense:**
```bash
remotecli expenses approve --expense-id exp_xyz789
```

**Download the latest payslip for an employment:**
```bash
remotecli payslips list --employment-id emp_abc123 --pretty
remotecli payslips download --id <id> --out-file ./payslip.pdf
```

**Check an employee's leave balance:**
```bash
remotecli time-off balance --employment-id emp_abc123 --pretty
```

**Amend an employee's contract (salary, title, hours, etc.):**

A contract amendment is a *delta* over the current contract — never submit one without first reading the existing terms, or you'll propose changes that conflict with current state or are no-ops. When you only have a name or email, resolve the employment via `employments list` filters (not the interactive picker — filters are faster and unambiguous for autonomous use).

```bash
# 1. Resolve the employment by email/status filter (skip the picker)
remotecli employments list --email alice@example.com --pretty

# 2. Read the current active contract for context (current salary, title, work hours, etc.)
remotecli contracts list --employment-id emp_abc123 --pretty

# 3. Submit the amendment — schema-driven, country-specific, ends with a confirm step
remotecli contract-amendments create --employment-id emp_abc123
```

**Most amendment fields are unchanged — copy them verbatim from the active contract.** Read the JSON form of `contracts list --employment-id X` (the default; don't pass `--pretty`) and take the first element of `data.employment_contracts`. For a salary raise, only `annual_gross_salary` (and `reason_for_change` / `effective_date`) actually change; every other answer — `job_title`, `role_description`, `work_hours_per_week`, `contract_duration_type`, `work_schedule`, `compensation_currency_code` — must equal the active contract's value, or the API records each one as an additional proposed change. Units already line up: `annual_gross_salary: 7200000` in `contracts list` means £72,000 in pence (minor units), and the form expects the same integer — don't divide by 100, don't convert to a decimal string, and don't reinvent `role_description` from scratch.

`contract-amendments create` pulls the country and `active_contract_id` off the employment automatically; override either with `--country` / `--contract-id` if needed. After submission, track the amendment with `contract-amendments list --employment-id emp_abc123` or `contract-amendments show <amendment_id>`.

## Output Control

```bash
remotecli <cmd>           # JSON output (default)
remotecli <cmd> --pretty  # human-readable table
remotecli <cmd> --all     # fetch all pages (list commands; default page-size: 20)
```

## Role Restrictions

These operations require a **company manager token** and fail with employee tokens:
- `expenses create / approve / decline`
- `time-off create / approve / decline`
- `terminations create`

Employee tokens use different endpoints (`/v1/employee/...`) and expose a read-only subset.

## Constraints to Know

- `expenses create --expense-date` must be **today or in the past** — future dates are rejected by the API.
- File uploads (receipts, termination docs): PDF/DOC/DOCX only, max 10 MB each, max 5 files.

## Full Reference

See `references/commands.md` for every flag, valid enum values, and pagination options for each command.
