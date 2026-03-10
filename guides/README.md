# Guides 📚

Main README = commands only. This folder = full flow and reference.

## Order

| | Doc | Use |
|---|-----|-----|
| 1 | [step-by-step.md](step-by-step.md) | End-to-end: Splunk up through data in indexes |
| 2 | [aws-data-and-splunk-ingestion.md](aws-data-and-splunk-ingestion.md) | Build output, what each log source is, S3 inputs, SQS vs S3 |

## Quick links

| Topic | Link |
|-------|------|
| AWS keys / `aws configure` | [step-by-step.md § Credentials](step-by-step.md#credentials) |
| Add-on install | [step-by-step.md § Step 3](step-by-step.md#step-3-install-the-splunk-add-on-for-aws) |
| SQS AccessDenied | [aws-data-and-splunk-ingestion.md § SQS](aws-data-and-splunk-ingestion.md#4-sqs-based-s3-vs-plain-s3) |
| Teardown | `infra` → `.\destroy.ps1` |

## Paths

| | Folder |
|---|--------|
| Splunk (Docker) | `soc/` |
| Build / destroy | `infra/` |
| Add-on `.tgz` | `soc/add-on/` |
