# Infra (AWS)

**Up:** `.\build.ps1` — installs AWS CLI/Terraform if missing; confirm with `yes`.  
**Down:** `.\destroy.ps1` — empties buckets then destroys. Use **build credentials**, not Stratus.

**Created:** 3 S3 buckets, CloudTrail, Config, VPC Flow Logs, IAM user `soc-lab-splunk-addon`. Build output = bucket names + Splunk keys for the add-on.

**Options:** `.\build.ps1 -SkipApply` (plan only). Copy `terraform.tfvars.example` → `terraform.tfvars` for region/project name.
