---
name: remote-cli
description: Use when the user asks you to perform any Remote.com HR action — create or list time off, manage expenses (approve/decline/download receipts), list or create employments, download payslips, submit terminations — via the remotecli CLI tool in this project. Also triggers when asked to look up leave balance, employment status, or company info through the CLI.
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

## Non-Interactive Usage

Every command that normally prompts can be driven entirely with flags — always prefer flags when acting autonomously. See `references/commands.md` for every flag per command.

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
