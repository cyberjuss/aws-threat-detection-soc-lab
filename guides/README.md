# Guides

This folder holds the **full flow** and **reference** material for the AWS Threat Detection Soc Lab. The [main README](../README.md) stays high-level; these guides walk through every step from Splunk up through detection practice and dashboards.

---

## Overview

| Step | Topic | Purpose |
|------|-------|---------|
| 1 | [Using Docker to host Splunk](step-by-step.md#1-using-docker-to-host-splunk) | Run Splunk locally in a container. |
| 2 | [Splunk setup for indexes](step-by-step.md#2-splunk-setup-for-indexes) | Create `aws_cloudtrail`, `aws_config`, `aws_vpcflow`. |
| 3 | [Installing the AWS add-on](step-by-step.md#3-installing-the-aws-add-on) | Splunk Add-on for AWS from Splunkbase. |
| 4 | [Terraform: build infra in AWS](step-by-step.md#4-terraform-basics-and-usage-to-build-infra) | Understand and run `build.ps1` to create buckets, trail, Config, VPC Flow. |
| 5 | [Data ingestion in Splunk](step-by-step.md#5-data-ingestion-in-splunk) | Configure add-on inputs; verify data flows. |
| 6 | [Red team strategies for adversary simulation](step-by-step.md#6-red-team-strategies-for-adversary-simulation) | Lab-safe adversary simulation to validate detections. |
| 7 | [Detections and corporate dashboard](step-by-step.md#7-detections-to-build-corporate-dashboard) | Example searches and dashboard for threat visibility. |

**Reference:** [aws-data-and-splunk-ingestion.md](aws-data-and-splunk-ingestion.md) — build output, log sources, S3 vs SQS.

---

## Quick reference

| Topic | Where |
|-------|--------|
| AWS keys / stop repeated prompts | [step-by-step.md — Credentials](step-by-step.md#credentials) |
| SQS `AccessDenied` / plain S3 only | [aws-data-and-splunk-ingestion.md — SQS vs plain S3](aws-data-and-splunk-ingestion.md#4-sqs-based-s3-vs-plain-s3) |
| Teardown | `infra` → `.\destroy.ps1` |

---

## Repository paths

| Path | Contents |
|------|----------|
| `soc/` | Docker Splunk, optional add-on `.tgz` |
| `infra/` | Terraform, `build.ps1`, `destroy.ps1` |
| `scripts/` | Index creation (`setup_splunk.py`) |
