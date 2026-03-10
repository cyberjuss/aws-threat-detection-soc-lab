# 🛡️ AWS Threat Detection Soc Lab

<p align="center">
  <strong>Cloud logs → Splunk → Detection practice</strong>
</p>

---

Welcome to the **AWS Threat Detection Soc Lab**.

This project gives you a hands-on environment to learn AWS threat detection with Splunk: run Splunk locally in Docker, stand up AWS logging (CloudTrail, Config, VPC Flow Logs) with one script, and practice detection. **Build** brings the environment up; **destroy** tears it down. No need to manage Terraform by hand unless you want to—the scripts handle it.

---

## 🔧 Prerequisites

| Requirement | Purpose |
|-------------|---------|
| Docker Desktop | Splunk in a container |
| Python 3.10+ | Index setup script |
| AWS account | Lab resources |
| PowerShell | `build.ps1` / `destroy.ps1` |

> Run `aws configure` once so `build.ps1` stops prompting for keys.

---

## 🚀 Get started

### 1. 🐳 Splunk

```bash
cd soc
docker compose up -d
```

Open **https://localhost:8000** — `admin` / `ChangeMe123!` (or `soc/.env`). First start may take a few minutes.

### 2. 📊 Indexes

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

Check **Settings → Indexes** for `aws_cloudtrail`, `aws_config`, `aws_vpcflow`.

### 3. 📦 Splunk Add-on for AWS

Download: https://splunkbase.splunk.com/app/1876/

Splunk: **Apps → Manage Apps → Install app from file** → restart. Save `.tgz` in `soc/add-on/` if you like: [soc/add-on/README.md](soc/add-on/README.md).

### 4. ☁️ AWS

```powershell
cd infra
.\build.ps1
```

Confirm `yes`. Copy bucket names and `soc-lab-splunk-addon` keys — use in add-on **Configuration → AWS Account** and **Inputs** (S3 per bucket, plain S3 only).

Script blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

---

## 🔄 Flow

```
Splunk (Docker) → Indexes → Add-on → AWS (build.ps1)
                              ↓
                    CloudTrail | Config | VPC Flow → S3 → Splunk
```

Details: [guides/step-by-step.md](guides/step-by-step.md) · [guides/aws-data-and-splunk-ingestion.md](guides/aws-data-and-splunk-ingestion.md).

---

## 🔍 Usage

**Search once data flows**

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

Confirm `yes`. Splunk can stay up; only AWS resources are removed.

---

## 📁 Project structure

| Path | Purpose |
|------|---------|
| `infra/` | Terraform; `build.ps1` / `destroy.ps1` |
| `soc/` | Docker Splunk, add-on `.tgz` folder |
| `scripts/` | Index creation |
| `guides/` | Step-by-step + S3 vs SQS reference |

Terraform: `infra/` → `terraform plan` | `apply` | `destroy`. Options: [infra/README.md](infra/README.md).
