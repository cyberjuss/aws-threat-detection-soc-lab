# AWS environment (infra)

This folder holds the AWS side of the lab. Use the scripts for a simple workflow.

---

## Bring up the environment

```powershell
.\build.ps1
```

- The script will install **AWS CLI** and **Terraform** if they’re missing.
- It will ask for your **AWS Access Key ID** and **Secret** if you don’t already have credentials set.
- Type **yes** when it asks to create resources.

**Options:**

- `-AutoApprove` — create without typing yes  
- `-SkipApply` — only show what would be created; don’t create anything  

If PowerShell blocks the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

---

## Shut down the environment

```powershell
.\destroy.ps1
```

- The script empties the S3 buckets, then removes all resources.
- Enter credentials if prompted; type **yes** to confirm.

---

## What gets created

| Resource | Purpose |
|----------|---------|
| 3 S3 buckets | CloudTrail, Config, and VPC Flow logs; Splunk reads from these. |
| CloudTrail | Records API activity in your account. |
| AWS Config | Records configuration changes. |
| VPC Flow Logs | Network traffic logs. |
| IAM user `soc-lab-splunk-addon` | Used by Splunk to read the buckets; least privilege. |

When the build finishes, it prints **bucket names** and **Splunk user credentials**. Use those in the Splunk Add-on for AWS.

---

## Optional settings

- **Different region or project name:** Copy `terraform.tfvars.example` to `terraform.tfvars` and edit. Then run `.\build.ps1` as usual.

---

## Using Terraform directly

Advanced users can run Terraform from this folder:

- `terraform plan` — see what would change  
- `terraform apply` — create or update resources  
- `terraform destroy` — remove resources (empty S3 buckets first, or use the `destroy.ps1` script)

The scripts are the recommended way to build and tear down; Terraform is there if you want more control.
