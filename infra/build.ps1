<#
.SYNOPSIS
    Prompts for AWS credentials if needed, installs AWS CLI and Terraform if needed, then builds the AWS environment.
.DESCRIPTION
    Run from the infra folder (or repo root). Installs AWS CLI and Terraform via winget if missing; prompts for credentials; runs init, plan, apply.
#>

[CmdletBinding()]
param(
    [switch] $AutoApprove,
    [switch] $SkipApply
)

$ErrorActionPreference = "Stop"

# --- Find infra folder (where .tf files live) ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraDir = if (Test-Path (Join-Path $scriptDir "versions.tf")) { $scriptDir } else { Join-Path $scriptDir "infra" }
if (-not (Test-Path (Join-Path $infraDir "versions.tf"))) {
    Write-Error "Infra folder not found. Run from repo root or infra folder. Expected: $infraDir"
}
Set-Location $infraDir
Write-Host "Working directory: $infraDir" -ForegroundColor Cyan

# Refresh PATH so we see Terraform and AWS CLI (e.g. after winget install)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# --- AWS CLI: used to verify credentials and by destroy.ps1 to empty buckets. Install if missing. ---
$awsCmd = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsCmd) {
    Write-Host "`n[AWS CLI] Not found. Installing via winget..." -ForegroundColor Yellow
    try {
        winget install Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
    } catch {
        Write-Error "AWS CLI install failed. Install manually: winget install Amazon.AWSCLI"
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI installed but not found. Close and reopen PowerShell, then run this script again."
    }
    Write-Host "[AWS CLI] Installed successfully." -ForegroundColor Green
} else {
    Write-Host "`n[AWS CLI] Already installed." -ForegroundColor Green
}

# --- Credentials: who you are in AWS. Terraform uses these to create resources. ---
function Test-AwsCredentialsSet {
    if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) { return $true }
    try {
        $null = aws sts get-caller-identity 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

if (-not (Test-AwsCredentialsSet)) {
    Write-Host "`n[AWS] No credentials found. Enter your AWS access key (IAM -> Users -> Security credentials -> Create access key)." -ForegroundColor Yellow
    $accessKey = Read-Host "AWS Access Key ID"
    if ([string]::IsNullOrWhiteSpace($accessKey)) { throw "Access Key ID is required." }
    $secretPrompt = Read-Host "AWS Secret Access Key" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretPrompt)
    try {
        $env:AWS_SECRET_ACCESS_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    $env:AWS_ACCESS_KEY_ID = $accessKey.Trim()
    Write-Host "[AWS] Credentials set for this run." -ForegroundColor Green
    $regionPrompt = Read-Host "AWS region (press Enter for us-east-1)"
    if (-not [string]::IsNullOrWhiteSpace($regionPrompt)) {
        $env:TF_VAR_aws_region = $regionPrompt.Trim()
    }
} else {
    Write-Host "`n[AWS] Using existing credentials." -ForegroundColor Green
}

function Test-TerraformInstalled {
    $tf = Get-Command terraform -ErrorAction SilentlyContinue
    return ($null -ne $tf)
}

# --- Terraform: infra-as-code. Installed once; then init / plan / apply. ---
if (-not (Test-TerraformInstalled)) {
    Write-Host "`n[Terraform] Not found. Installing via winget..." -ForegroundColor Yellow
    try {
        winget install Hashicorp.Terraform --accept-package-agreements --accept-source-agreements
    } catch {
        Write-Error "Terraform install failed. Install manually: winget install Hashicorp.Terraform. See infra/README.md for more."
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Test-TerraformInstalled)) {
        Write-Error "Terraform installed but not found. Close and reopen PowerShell, then run this script again."
    }
    Write-Host "[Terraform] Installed successfully." -ForegroundColor Green
} else {
    Write-Host "`n[Terraform] Already installed." -ForegroundColor Green
}

& terraform version
Write-Host ""

# --- init: download providers (AWS, etc.) and prepare state ---
$terraformDir = Join-Path $infraDir ".terraform"
$providersDir = Join-Path $terraformDir "providers"
$alreadyInitialized = (Test-Path $terraformDir) -and ((Test-Path $providersDir) -or (Test-Path (Join-Path $terraformDir "plugins")))

if ($alreadyInitialized) {
    Write-Host "[Build] Terraform already initialized. Skipping init." -ForegroundColor Green
} else {
    Write-Host "[Build] terraform init (downloading providers if needed)..." -ForegroundColor Cyan
    & terraform init -input=false
    if ($LASTEXITCODE -ne 0) { throw "terraform init failed." }
}
Write-Host ""

# --- plan: preview what will be created (no changes yet) ---
Write-Host "[Build] terraform plan..." -ForegroundColor Cyan
& terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) { throw "terraform plan failed." }
Write-Host ""

if ($SkipApply) {
    Write-Host "[Build] SkipApply: no resources created. Run 'terraform apply tfplan' to create." -ForegroundColor Yellow
    exit 0
}

# --- apply: create/update resources in AWS ---
if ($AutoApprove) {
    Write-Host "[Build] terraform apply (auto-approve)..." -ForegroundColor Cyan
    & terraform apply -auto-approve tfplan
} else {
    Write-Host "[Build] terraform apply (type 'yes' to confirm)..." -ForegroundColor Cyan
    & terraform apply tfplan
}
if ($LASTEXITCODE -ne 0) { throw "terraform apply failed." }

Write-Host ""
Write-Host "=== Build complete ===" -ForegroundColor Green
Write-Host "Outputs (for Splunk Add-on):" -ForegroundColor Cyan
& terraform output

Write-Host ""
Write-Host "Splunk secret key: terraform output -raw splunk_iam_secret_key" -ForegroundColor Gray
