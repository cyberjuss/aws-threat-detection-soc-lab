# AWS data sources and Splunk ingestion ☁️

Reference for build output, log sources, and add-on inputs. Walkthrough order: [step-by-step.md](step-by-step.md).

---

## 1. Build (`infra\build.ps1`)

Runs Terraform. Installs AWS CLI/Terraform if missing. Prompts for credentials unless `aws configure` is set.

Creates: three S3 buckets, CloudTrail trail, Config recorder and channel, VPC Flow Logs to S3, IAM user `soc-lab-splunk-addon`.

| Output | Use |
|--------|-----|
| cloudtrail_bucket_name | Add-on CloudTrail input |
| config_bucket_name | Add-on Config input |
| vpc_flow_logs_bucket_name | Add-on VPC Flow input |
| splunk_iam_access_key_id / splunk_iam_secret_key | Add-on AWS account |

```powershell
cd infra
.\build.ps1
```

---

## 2. What each source writes

**CloudTrail** — API calls (management events). Trail delivers JSON into the CloudTrail bucket.

**Config** — Resource configuration snapshots and changes into the Config bucket.

**VPC Flow Logs** — Network flow metadata into the VPC Flow bucket.

No console setup required; Terraform owns the wiring.

---

## 3. Add-on inputs

Indexes must exist first (`setup_splunk.py`). One input per bucket; SQS fields empty/disabled.

CloudTrail → index `aws_cloudtrail`. Config → `aws_config`. VPC Flow → `aws_vpcflow`.

After a few minutes:

```
index=aws_cloudtrail earliest=-30m
index=aws_config earliest=-30m
index=aws_vpcflow earliest=-30m
```

---

## 4. SQS-based S3 vs plain S3

| Pattern | Behavior | Lab |
|---------|----------|-----|
| Plain S3 | Splunk lists/reads objects in bucket | Use this |
| SQS-based S3 | S3 events → queue; Splunk reads queue | Skip |

SQS path needs queues and IAM (`sqs:ListQueues`, `sqs:ReceiveMessage`, …). `soc-lab-splunk-addon` has S3 only by design, so `sqs:ListQueues` AccessDenied appears if the UI probes SQS. Choose plain S3 inputs only; the error can be ignored if you are not using SQS-based inputs.
