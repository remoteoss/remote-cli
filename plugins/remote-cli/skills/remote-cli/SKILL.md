---
name: remote-cli
description: Use when the user asks you to perform any Remote.com HR action — create or list time off, manage expenses (approve/decline/download receipts), list or create employments, download payslips, submit terminations — via the ./remote CLI tool in this project. Also triggers when asked to look up leave balance, employment status, or company info through the CLI.
---

# Using the Remote CLI

## Overview

`./remote` is the built binary for this project. Build it with `go build -o remote .` if the binary is missing or stale after code changes.

Requires three environment variables:
```bash
export REMOTE_BASE_URL=https://gateway.remote.com/api/eor
export REMOTE_CLIENT_ID=<your_client_id>
export REMOTE_CLIENT_SECRET=<your_client_secret>
```

An **active company** must be selected before most commands:
```bash
./remote companies list   # see what's saved
./remote use              # interactively pick the active one
```

## Non-Interactive Usage

Every command that normally prompts can be driven entirely with flags — always prefer flags when acting autonomously. See `references/commands.md` for every flag per command.

## Quick Command Reference

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `login` | Authenticate via browser (PKCE) | — |
| `use` | Pick active company (interactive) | — |
| `me` | Show current identity | — |
| `companies list` | List saved companies | `--pretty` |
| `companies create` | Create a company | — |
| `employments list` | List employments | `--status`, `--email`, `--all` |
| `employments create` | Onboard a new employee | `--country` |
| `employments show <id>` | Get a single employment | — |
| `expenses list` | List expenses | `--employment-id`, `--pretty` |
| `expenses create` | Submit an expense | `--employment-id`, `--amount`, `--currency`, `--expense-date` |
| `expenses approve` | Approve a pending expense | `--expense-id` |
| `expenses decline` | Decline a pending expense | `--expense-id`, `--reason` |
| `expenses download-receipt` | Download a receipt file | `--expense-id`, `--out-file` |
| `payslips list` | List payslips | `--employment-id`, `--start-date`, `--end-date` |
| `payslips download` | Download a payslip PDF | `--payslip-id`, `--out-file` |
| `time-off policies` | List leave policies | `--employment-id` |
| `time-off balance` | Show leave balance | `--employment-id` |
| `time-off create` | Create approved time off | `--employment-id`, `--timeoff-type`, `--start-date`, `--end-date` |
| `time-off list` | List time off records | `--employment-id`, `--status` |
| `time-off approve` | Approve a requested time off | `--timeoff-id` |
| `time-off cancel` | Cancel approved time off | `--timeoff-id`, `--reason` |
| `time-off decline` | Decline a requested time off | `--timeoff-id`, `--reason` |
| `terminations list` | List terminations | `--employment-id`, `--type` |
| `terminations create` | Submit a termination request | `--employment-id` |

## Common Workflows

**Create time off for an employee:**
```bash
./remote time-off create \
  --employment-id emp_abc123 \
  --timeoff-type time_off \
  --start-date 2026-05-09 \
  --end-date 2026-05-09
```
Common types: `time_off`, `sick_leave`, `paid_time_off`, `public_holiday`, `unpaid_leave`, `maternity_leave`, `paternity_leave`, `bereavement`. Full list in `references/commands.md`.

**List active employments:**
```bash
./remote employments list --status active --pretty
```

**Approve a pending expense:**
```bash
./remote expenses approve --expense-id exp_xyz789
```

**Download the latest payslip for an employment:**
```bash
./remote payslips list --employment-id emp_abc123 --pretty
./remote payslips download --payslip-id <id> --out-file ./payslip.pdf
```

**Check an employee's leave balance:**
```bash
./remote time-off balance --employment-id emp_abc123 --pretty
```

## Output Control

```bash
./remote <cmd>           # JSON output (default)
./remote <cmd> --pretty  # human-readable table
./remote <cmd> --all     # fetch all pages (list commands; default page-size: 100)
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
