# AWS Threat Detection SOC Lab

**Welcome to the AWS Threat Detection SOC Lab.**

This project gives you a hands-on environment to learn AWS threat detection with Splunk: run Splunk locally in Docker, stand up AWS logging (CloudTrail, Config, VPC Flow Logs) with one script, and practice detection. **Build** brings the environment up; **destroy** tears it down. No need to manage Terraform by hand unless you want to—the scripts handle it.

## Prerequisites

- Docker Desktop
- Python 3.10+
- AWS account
- PowerShell (Windows)

Optional: `aws configure` once so `build.ps1` stops prompting for keys.

## Installation

**1. Splunk**

```bash
cd soc
docker compose up -d
```

UI: https://localhost:8000 — `admin` / `ChangeMe123!` (override in `soc/.env`). First start may take several minutes.

**2. Indexes**

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

Splunk: **Settings → Indexes** — expect `aws_cloudtrail`, `aws_config`, `aws_vpcflow`.

**3. Splunk Add-on for AWS**

Download `.tgz`: https://splunkbase.splunk.com/app/1876/

Splunk: **Apps → Manage Apps → Install app from file** — restart. Drop folder: [soc/add-on/README.md](soc/add-on/README.md).

**4. AWS**

```powershell
cd infra
.\build.ps1
```

Confirm `yes`. Copy bucket names and `soc-lab-splunk-addon` keys from output — add-on **Configuration → AWS Account** and **Inputs** (S3 per bucket, plain S3 not SQS).

Script blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

## How it works

```
Gate 1 — Splunk up
  docker compose → Splunk UI, management port for setup_splunk.py

Gate 2 — Indexes
  setup_splunk.py → aws_cloudtrail | aws_config | aws_vpcflow

Gate 3 — Add-on
  Install from file → AWS account + S3 inputs wired to those indexes

Gate 4 — AWS side
  build.ps1 (Terraform) → buckets + CloudTrail + Config + VPC Flow Logs + IAM user
  AWS writes logs to S3; add-on polls S3 into Splunk
```

Full walkthrough and ingestion detail: [guides/step-by-step.md](guides/step-by-step.md) · [guides/aws-data-and-splunk-ingestion.md](guides/aws-data-and-splunk-ingestion.md).

## Usage

**Search after ingest**

```
index=aws_cloudtrail earliest=-1h
index=aws_config earliest=-1h
index=aws_vpcflow earliest=-1h
```

**Teardown**

```powershell
cd infra
.\destroy.ps1
```

Confirm `yes`. Splunk/Docker can stay up.

## Layout

| Path | Purpose |
|------|---------|
| `infra/` | Terraform; `build.ps1` / `destroy.ps1` |
| `soc/` | Docker Splunk, add-on `.tgz` folder |
| `scripts/` | Index creation |
| `guides/` | Step-by-step + S3 vs SQS reference |

Terraform directly: `infra/` → `terraform plan` | `apply` | `destroy`. Options: [infra/README.md](infra/README.md).
