# Step-by-step 🪜

Nothing running to AWS logs searchable in Splunk. Skip any step already done.

## Flow

1. Splunk runs in Docker on your machine. Browser UI at localhost.
2. `build.ps1` turns on AWS logging and writes to three S3 buckets. IAM user `soc-lab-splunk-addon` can read those buckets only.
3. Splunk Add-on pulls from S3 into indexes `aws_cloudtrail`, `aws_config`, `aws_vpcflow`.

## Terms

| Term | Meaning |
|------|---------|
| Index | Splunk storage for events; one per source in this lab |
| Add-on | Splunk app that reads AWS S3 |
| build.ps1 | Creates buckets, trail, config, flow logs, Splunk IAM user |
| destroy.ps1 | Empties buckets and deletes lab resources |

## Prerequisites

Docker Desktop, Python 3, AWS account, PowerShell.

If `build.ps1` keeps asking for keys: run `aws configure` once, then rerun build.

---

## Step 1 — Splunk

```bash
cd soc
docker compose up -d
```

Open https://localhost:8000 — `admin` / `ChangeMe123!` unless changed in `soc/.env`. First start may take a few minutes.

---

## Step 2 — Indexes

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

Password = Splunk admin password.

Check **Settings → Indexes** for `aws_cloudtrail`, `aws_config`, `aws_vpcflow`.

---

## Step 3 — Splunk Add-on for AWS

Splunkbase “Already installed” is account-side only. Install the `.tgz` into your Splunk.

1. Download: https://splunkbase.splunk.com/app/1876/
2. Optional: save under `soc/add-on/`
3. Splunk: **Apps → Manage Apps → Install app from file** → upload `.tgz` → restart

Inputs are configured after build (Step 5). Field detail: [aws-data-and-splunk-ingestion.md](aws-data-and-splunk-ingestion.md).

---

## Step 4 — AWS (build)

```powershell
cd infra
.\build.ps1
```

Keys = your IAM user access key if prompted. Confirm with `yes`.

Copy from output before closing terminal:

- Three bucket names (`soc-lab-cloudtrail-…`, `soc-lab-config-…`, `soc-lab-vpcflow-…`)
- `soc-lab-splunk-addon` access key ID and secret (add-on only). Secret is shown once.

### Credentials {#credentials}

```powershell
aws configure
```

Stops repeated prompts on later runs.

---

## Step 5 — Add-on inputs

1. Add-on **Configuration** → **AWS Account** using Splunk IAM keys from Step 4.
2. **Inputs** → **Create New Input** × 3:

| Input type | Bucket (from build) | Index |
|------------|---------------------|-------|
| CloudTrail | cloudtrail bucket | `aws_cloudtrail` |
| Config | config bucket | `aws_config` |
| VPC Flow Logs | vpcflow bucket | `aws_vpcflow` |

Use S3-only mode. Do not use SQS-based S3 for this lab.

---

## Step 6 — Verify

Search app:

```
index=aws_cloudtrail earliest=-30m
index=aws_config earliest=-30m
index=aws_vpcflow earliest=-30m
```

Empty index: wait; AWS write and add-on poll are async.

---

## Teardown

```powershell
cd infra
.\destroy.ps1
```

Confirm with `yes`. Splunk can keep running.

## Issues

| Issue | Action |
|-------|--------|
| Script blocked | `powershell -ExecutionPolicy Bypass -File .\build.ps1` |
| SQS errors | [aws-data-and-splunk-ingestion.md §4](aws-data-and-splunk-ingestion.md#4-sqs-based-s3-vs-plain-s3) |
