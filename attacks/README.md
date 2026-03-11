# Attacks (Stratus Red Team)

Use IAM user **soc-lab-stratus** to run techniques. Events → **CloudTrail → Splunk**.

---

## Setup

1. **Build infra** (creates Stratus user, `.env.stratus`):
   ```powershell
   cd infra
   .\build.ps1
   ```

2. **Configure Stratus** (installs Go + Stratus CLI if needed, creates `stratus-lab` profile):
   ```powershell
   cd attacks
   .\configure-stratus.ps1
   ```

---

## Run

Same PowerShell window:

```powershell
stratus list --platform aws
stratus detonate <technique-id> --cleanup
```

[Stratus usage guide](https://stratus-red-team.cloud/user-guide/usage/) — list, detonate, warmup, cleanup, status.

**New terminal?** Run `.\configure-stratus.ps1` again or `$env:AWS_PROFILE = "stratus-lab"`.

**Destroy:** Use build credentials (not Stratus). Open a new terminal or unset `AWS_PROFILE` before `.\destroy.ps1`.
