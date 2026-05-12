# Remote CLI — Full Command Reference

## Global Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--output, -o` | `json` | Output format: `json` or `table` |
| `--pretty` | false | Alias for `--output=table` |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `REMOTE_BASE_URL` | API base URL (e.g. `https://gateway.remote.com/api/eor`) |
| `REMOTE_CLIENT_ID` | OAuth2 client ID |
| `REMOTE_CLIENT_SECRET` | OAuth2 client secret |

---

## `login`

Authenticate via browser (OAuth2 PKCE flow). Opens browser automatically.

```bash
./remote login
```

No flags.

---

## `use`

Interactively select the active company from saved companies. Required before most commands.

```bash
./remote use
```

No flags.

---

## `me`

Show the identity associated with the current OAuth credentials.

```bash
./remote me
```

No flags. Calls `/v1/identity/current`.

---

## `companies`

### `companies list`

List all saved companies. The active one is marked `[active]`.

```bash
./remote companies list [--pretty]
```

### `companies create`

Create a new company (interactive — prompts for country and company info form).

```bash
./remote companies create
```

Saves the new company to local state and marks it active. Returns: `company_id`, `company_name`, `company_owner_user_id`, token fields.

---

## `employments`

### `employments list`

List employments for the active company.

```bash
./remote employments list [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--email` | string | Filter by login email |
| `--status` | string | Filter by status (comma-separated) |
| `--employment-type` | string | Filter by employment product type |
| `--employment-model` | string | Filter by model: `global_payroll`, `peo`, `eor` |
| `--columns` | string | Comma-separated column names for table output |
| `--all` | bool | Fetch all pages |
| `--page` | int | Page number (default: 1) |
| `--page-size` | int | Results per page (default: 100) |

Table columns: ID, Name, Email, Country, Status, Model.

### `employments create`

Onboard a new employee (multi-step interactive form).

```bash
./remote employments create [--country GBR] [--company-token <token>]
```

| Flag | Type | Description |
|------|------|-------------|
| `--country` | string | 3-letter ISO country code (e.g. `GBR`, `USA`, `BEL`) |
| `--company-token` | string | Override active company token |

Steps: Basic Info → Address → Personal Details → Contract Details → Pricing Plan (country-dependent).

### `employments show <id>`

Get a single employment by ID.

```bash
./remote employments show emp_abc123 [--company-token <token>]
```

---

## `expenses`

### `expenses list`

List expenses for the active company (or employee if using employee token).

```bash
./remote expenses list [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--columns` | string | Comma-separated column names |
| `--all` | bool | Fetch all pages |
| `--page` | int | Page number (default: 1) |
| `--page-size` | int | Results per page (default: 100) |

Table columns: ID, Title, Status, Date, Category, Amount, Currency, Employee, Employment.

### `expenses create`

Submit an expense. **Company manager token required.**

```bash
./remote expenses create [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--employment-id` | string | Employment ID (picker if omitted) |
| `--title` | string | Expense title |
| `--currency` | string | 3-letter ISO currency code (e.g. `EUR`, `USD`) |
| `--amount` | string | Amount in major units (e.g. `42.50`) |
| `--expense-date` | string | Date in `YYYY-MM-DD` format — **must be today or in the past** |
| `--category` | string | Category code (e.g. `business_travel.fuel`) — picker if omitted |
| `--receipt` | string[] | Path to receipt file, repeatable, max 5 (PDF/DOC/DOCX, max 10 MB each) |
| `--tax-amount` | string | Tax amount in major units |
| `--reviewer-id` | string | Reviewer user ID |

### `expenses approve`

Approve a pending expense. **Company manager token required.**

```bash
./remote expenses approve [--expense-id <id>] [--company-token <token>]
```

Omitting `--expense-id` opens an interactive picker of pending expenses.

### `expenses decline`

Decline a pending expense. **Company manager token required.**

```bash
./remote expenses decline [--expense-id <id>] [--reason <text>] [--company-token <token>]
```

### `expenses download-receipt`

Download a receipt file attached to an expense.

```bash
./remote expenses download-receipt [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--expense-id` | string | Expense ID (picker if omitted) |
| `--receipt-id` | string | Specific receipt ID (skips picker when combined with `--expense-id`) |
| `--out-file` | string | Output path (defaults to `./<receipt name>`) |

---

## `payslips`

### `payslips list`

List payslips. Behaviour differs by token type:
- **Company token**: full filters, calls `/v1/payslips`
- **Employee token**: no filters, calls `/v1/employee/payslip-files`

```bash
./remote payslips list [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--employment-id` | string | Filter by employment ID |
| `--start-date` | string | Issued on or after (`YYYY-MM-DD`) |
| `--end-date` | string | Issued on or before (`YYYY-MM-DD`) |
| `--expected-payout-start-date` | string | Expected payout on or after (`YYYY-MM-DD`) |
| `--expected-payout-end-date` | string | Expected payout on or before (`YYYY-MM-DD`) |
| `--columns` | string | Comma-separated column names |
| `--all` | bool | Fetch all pages |
| `--page` | int | Page number (default: 1) |
| `--page-size` | int | Results per page (default: 100) |

### `payslips download`

Download a payslip as PDF.

```bash
./remote payslips download [--payslip-id <id>] [--out-file <path>] [--company-token <token>]
```

Omitting `--payslip-id` opens an interactive picker. Default output path is the server filename or `./payslip-<id>.pdf`.

---

## `time-off`

### `time-off policies`

List leave policies for an employment.

```bash
./remote time-off policies [--employment-id <id>] [--company-token <token>]
```

Table columns: Name, Variant, Custom.

### `time-off balance`

Show leave balance summary for an employment.

```bash
./remote time-off balance [--employment-id <id>] [--company-token <token>]
```

Table columns: Policy, Type, Unit, Used, Balance, Booked, Pending.

### `time-off create`

Create an approved time off record. **Company manager token required.**

```bash
./remote time-off create [flags]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--company-token` | string | | Override active company token |
| `--employment-id` | string | | Employment ID (picker if omitted) |
| `--timeoff-type` | string | | See valid types below |
| `--start-date` | string | | `YYYY-MM-DD` |
| `--end-date` | string | | `YYYY-MM-DD` |
| `--timezone` | string | `UTC` | IANA timezone identifier |
| `--approved-at` | string | now | Approval timestamp (RFC3339) |
| `--approver-id` | string | active company user | User ID of the approver |
| `--notes` | string | | Optional notes |
| `--hours-per-day` | float | `8.0` | Hours per day for timeoff_days breakdown |

**Valid `--timeoff-type` values:**
`sick_leave`, `time_off`, `public_holiday`, `unpaid_leave`, `extended_leave`, `in_lieu_time`, `maternity_leave`, `paternity_leave`, `parental_leave`, `bereavement`, `military_leave`, `other`, `paid_time_off`, `custom_company_leave`, `rtt`, `casual_leave`, `rolex_festivita`

### `time-off list`

List time off records. Behaviour differs by token type (company vs employee).

```bash
./remote time-off list [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--employment-id` | string | Filter by employment ID |
| `--timeoff-type` | string | Filter by type |
| `--status` | string | Filter by status (see valid values below) |
| `--order` | string | Sort direction: `asc` or `desc` |
| `--sort-by` | string | Field: `timeoff_type` or `status` |
| `--columns` | string | Comma-separated column names |
| `--all` | bool | Fetch all pages |
| `--page` | int | Page number (default: 1) |
| `--page-size` | int | Results per page (default: 100) |

**Valid `--status` values:** `approved`, `cancelled`, `declined`, `requested`, `taken`, `cancel_requested`

Table columns: ID, Employee, Employment, Type, Status, Start, End.

### `time-off approve`

Approve a requested time off. **Company manager token required.**

```bash
./remote time-off approve [--timeoff-id <id>] [--approver-id <user_id>] [--company-token <token>]
```

Omitting `--timeoff-id` opens a picker filtered to `requested` status.

### `time-off cancel`

Cancel an approved time off.

```bash
./remote time-off cancel [--timeoff-id <id>] [--reason <text>] [--company-token <token>]
```

Omitting `--timeoff-id` opens a picker filtered to `approved` status.

### `time-off decline`

Decline a requested time off. **Company manager token required.**

```bash
./remote time-off decline [--timeoff-id <id>] [--reason <text>] [--company-token <token>]
```

---

## `terminations` (alias: `offboardings`)

### `terminations list`

List terminations for the active company.

```bash
./remote terminations list [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--employment-id` | string | Filter by employment ID |
| `--type` | string | `resignation` or `termination` |
| `--include-confidential` | bool | Include confidential termination requests (default: false) |
| `--columns` | string | Comma-separated column names |
| `--all` | bool | Fetch all pages |
| `--page` | int | Page number (default: 1) |
| `--page-size` | int | Results per page (default: 100) |

Table columns: ID, Employee, Employment, Type, Status, Submitted, Termination date.

### `terminations create`

Submit a termination request. **Company manager token required.**

```bash
./remote terminations create [--employment-id <id>] [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `--company-token` | string | Override active company token |
| `--employment-id` | string | Employment to terminate (picker if omitted) |
| `--reason-file` | string[] | Supporting document path, repeatable, max 5 (PDF/DOC/DOCX, max 10 MB) |
| `--timesheet-file` | string | Timesheet file path (skips PTO balance question if provided) |

Interactive prompts (cannot be bypassed via flags):
1. Confidential request? (yes/no)
2. Proposed termination date (`YYYY-MM-DD`)
3. Termination reason (dropdown)
4. Reason description
5. Risk assessment reasons (multi-select, min 1)
6. Employee challenge risk
7. Employee informed details
8. PTO balance agreement
9. Personal email and comments (optional)

**Valid termination reasons:** `gross_misconduct`, `performance`, `workforce_reduction`, `values`, `compliance_issue`, `incapacity_to_perform_inherent_duties`, `mutual_agreement`, `cancellation_before_start_date`, `conversion_to_contractor`, `job_abandonment`, `dissatisfaction_with_remote_service`, `end_of_fixed_term_contract_*` (8 variants), `other`

**Valid risk assessment reasons:** `sick_leave`, `family_leave`, `pregnant_or_breastfeeding`, `requested_medical_or_family_leave`, `disabled_or_health_condition`, `member_of_union_or_works_council`, `caring_responsibilities`, `reported_concerns_with_workplace`, `none_of_these`
