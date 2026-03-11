# Attacks (Stratus Red Team)

Use the **Stratus Red Team** IAM user (`soc-lab-stratus`) to run attack techniques in your lab. Events show up in CloudTrail → Splunk for detection practice.

## One-time setup

1. **Build infra** (creates Stratus user and writes `.env.stratus` at repo root):
   ```powershell
   cd infra
   .\build.ps1
   ```

2. **Configure Stratus** (run from this folder). Installs Go via winget if needed, then `go install` for Stratus CLI. Creates/updates the `stratus-lab` AWS profile from `.env.stratus` and sets this session:
   ```powershell
   cd attacks
   .\configure-stratus.ps1
   ```

## Run attacks

In the **same** PowerShell window after running the script:

```powershell
stratus list --platform aws
stratus detonate <technique-id> --cleanup
```

For **list**, **detonate**, **warmup**, **cleanup**, and **status**, see the [Stratus usage guide](https://stratus-red-team.cloud/user-guide/usage/).

**New terminal?** Run `.\configure-stratus.ps1` again, or `$env:AWS_PROFILE = "stratus-lab"`.
