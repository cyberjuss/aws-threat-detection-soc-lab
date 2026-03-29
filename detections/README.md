# Detections

Share **Splunk detection content** others can copy or adapt: SPL, saved-search notes, or brief write-ups tied to the lab indexes (`aws_cloudtrail`, `aws_config`, `aws_vpcflow`).

## Contributing

1. **Pick a clear filename** — e.g. `failed-console-login.spl`, `iam-create-user.md`.
2. **Document context** — index, key `eventName` / fields, and what the search is meant to catch.
3. **Open a PR** against `main` (or an issue first if the change is large).

Starter SPL lives in the repo [README](../README.md) under **Detection examples**. To generate matching telemetry, use [Stratus Red Team AWS techniques](https://stratus-red-team.cloud/attack-techniques/AWS/).
