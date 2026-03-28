# Detections

This folder is for **Splunk-style detection content** you can reuse: SPL snippets, saved-search notes, or short descriptions of what to look for in `aws_cloudtrail`, `aws_config`, or `aws_vpcflow`.

## How to contribute

1. Add a **descriptive filename** (e.g. `failed-console-login.spl` or `iam-create-user.md`).
2. Include **which index** (`aws_cloudtrail`, etc.) and any **event names** or **fields** the search relies on.
3. Open a **pull request** against `main`; optional issues are fine for larger ideas.

The root [README](../README.md) **Detection Examples** section lists starter queries. For attack simulations that pair with Stratus, see [Stratus AWS techniques](https://stratus-red-team.cloud/attack-techniques/AWS/).
