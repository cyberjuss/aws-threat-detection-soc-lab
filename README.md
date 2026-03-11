# 🛡️ AWS Threat Detection SOC Lab

CloudTrail, Config, VPC Flow → S3 → Splunk (Docker). Detection practice + Stratus Red Team.

Built by me, with AI assistance (Cursor and Codex) to speed up iteration and documentation.

<p align="center">
  <img width="1330" height="778" alt="Architecture: AWS → S3 → SQS → Splunk (Docker)" src="https://github.com/user-attachments/assets/c8b22a6b-affa-441a-88df-82d818fa1a4e" />
</p>

---

## Requirements

Docker Desktop · Python 3.10+ · AWS account · PowerShell · `aws configure`

---

## Quick start

| Step | Action |
|------|--------|
| 1 | `cd soc` → `docker compose up -d` → https://localhost:8000 |
| 2 | `pip install splunk-sdk` → `python ./scripts/setup_splunk.py` |
| 3 | Install [Splunk Add-on for AWS](https://splunkbase.splunk.com/app/1876/) (Apps → Install from file) |
| 4 | `cd infra` → `.\build.ps1` → save bucket names + Splunk IAM keys from output |
| 5 | Add-on: **AWS Account** (paste keys) → **Inputs** → 3 S3 inputs (CloudTrail, Config, VPC Flow; buckets from step 4; indexes `aws_cloudtrail`, `aws_config`, `aws_vpcflow`) |
| 6 | Optional [Stratus](attacks/README.md): `cd attacks` → `.\configure-stratus.ps1` → `stratus list --platform aws` |

[Full steps](guides/step-by-step.md)

---

## Verify

Splunk Search: `index=aws_cloudtrail earliest=-1h` (and `aws_config`, `aws_vpcflow`). Wait if empty.

---

## Cleanup

```powershell
cd infra
.\destroy.ps1
```

Same credentials as build (not Stratus).

---

## Layout

| Path | What |
|------|------|
| `infra/` | `build.ps1`, `destroy.ps1`, Terraform |
| `soc/` | Splunk Docker, add-on |
| `scripts/` | `setup_splunk.py` |
| `guides/` | [Step-by-step](guides/step-by-step.md) |
| `attacks/` | [Stratus Red Team](attacks/README.md) |

Medium blog (link TBD) for deeper walkthroughs.
