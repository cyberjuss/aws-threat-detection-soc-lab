# Splunk Add-on for AWS

**Download:** https://splunkbase.splunk.com/app/1876/

Install the add-on **in this lab's Splunk** (Docker). "Already Installed" on Splunkbase means your Splunkbase account, not your local instance — you still need to install the `.tgz` here.

1. Download the `.tgz` from the link above (log in to Splunkbase if needed). Save it in this folder for convenience (e.g. `splunk-add-on-for-aws-7.x.x.tgz`).
2. In Splunk Web (**https://localhost:8000**): **Apps → Manage Apps** → **Install app from file** → select the `.tgz` → **Upload app** → restart when prompted.
3. After restart: **Settings → Data inputs** → add your AWS account and S3 inputs for each bucket.

The `.tgz` is not in the repo (Splunk distributes it via Splunkbase). This folder is a convenient place to keep it once downloaded.
