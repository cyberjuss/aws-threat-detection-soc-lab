<#
.SYNOPSIS
    Configures Stratus Red Team: installs Go and Stratus CLI if missing, creates AWS profile from .env.stratus, sets current session.
.DESCRIPTION
    Ensures Stratus CLI is on PATH. If missing: installs Go via winget if needed, then runs go install for Stratus.
    Reads .env.stratus, writes [stratus-lab] to ~/.aws/credentials, sets AWS_PROFILE/AWS_REGION for this process.
.EXAMPLE
    .\configure-stratus.ps1
    stratus list --platform aws
    stratus detonate <technique-id> --cleanup
#>

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path $scriptDir -Parent

# --- Ensure Stratus CLI is available (install via Go if missing) ---
$stratusCmd = Get-Command stratus -ErrorAction SilentlyContinue
if (-not $stratusCmd) {
    Write-Host "Stratus CLI not found. Installing via Go..." -ForegroundColor Cyan

    # Install Go if missing
    $goCmd = Get-Command go -ErrorAction SilentlyContinue
    if (-not $goCmd) {
        Write-Host "Go not found. Installing via winget..." -ForegroundColor Yellow
        try {
            winget install GoLang.Go --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Error "Go install failed. Install manually: winget install GoLang.Go"
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        $goCmd = Get-Command go -ErrorAction SilentlyContinue
        if (-not $goCmd) {
            Write-Error "Go was installed but not found. Close and reopen PowerShell, then run this script again."
        }
        Write-Host "Go installed." -ForegroundColor Green
    }

    Write-Host "Installing Stratus Red Team CLI (go install)..." -ForegroundColor Gray
    & go install -v github.com/datadog/stratus-red-team/v2/cmd/stratus@latest
    if ($LASTEXITCODE -ne 0) { Write-Error "go install stratus failed." }

    $goBin = if ($env:GOBIN) { $env:GOBIN } else { Join-Path (Join-Path $env:USERPROFILE "go") "bin" }
    $env:Path = $goBin + ";" + $env:Path
    if (-not (Get-Command stratus -ErrorAction SilentlyContinue)) {
        Write-Error "Stratus installed to $goBin but not on PATH. Add $goBin to your PATH or restart PowerShell."
    }
    Write-Host "Stratus CLI installed." -ForegroundColor Green
}

$envPath = Join-Path $repoRoot ".env.stratus"
if (-not (Test-Path $envPath)) {
    Write-Error "Missing .env.stratus at $envPath. Run infra\build.ps1 first."
}

$accessKeyId = $null
$secretKey   = $null
Get-Content $envPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -and $line -notmatch '^\s*#') {
        $eq = $line.IndexOf('=')
        if ($eq -gt 0) {
            $name = $line.Substring(0, $eq).Trim()
            $val  = $line.Substring($eq + 1).Trim()
            if ($name -eq 'STRATUS_AWS_ACCESS_KEY_ID' -or $name -eq 'AWS_ACCESS_KEY_ID') { $script:accessKeyId = $val }
            if ($name -eq 'STRATUS_AWS_SECRET_ACCESS_KEY' -or $name -eq 'AWS_SECRET_ACCESS_KEY') { $script:secretKey = $val }
        }
    }
}
if (-not $accessKeyId -or -not $secretKey) {
    Write-Error ".env.stratus must contain STRATUS_AWS_ACCESS_KEY_ID and STRATUS_AWS_SECRET_ACCESS_KEY."
}

$awsDir   = Join-Path $env:USERPROFILE ".aws"
$credPath = Join-Path $awsDir "credentials"
$profile  = "stratus-lab"
$region   = "us-east-1"

if (-not (Test-Path $awsDir)) { New-Item -ItemType Directory -Path $awsDir -Force | Out-Null }

$newSection = @"
[$profile]
aws_access_key_id = $accessKeyId
aws_secret_access_key = $secretKey

"@

$existing = @()
if (Test-Path $credPath) {
    $inStratus = $false
    Get-Content $credPath -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s*\[\s*([^\]]+)\s*\]\s*$') {
            if ($Matches[1] -eq $profile) { $inStratus = $true } else { $inStratus = $false }
            if (-not $inStratus) { $existing += $_ }
        } else {
            if (-not $inStratus) { $existing += $_ }
        }
    }
}

$content = ($existing -join "`n").Trim()
if ($content -and -not $content.EndsWith("`n")) { $content += "`n" }
$content += "`n" + $newSection.TrimEnd()

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($credPath, $content, $utf8NoBom)

$env:AWS_PROFILE = $profile
$env:AWS_REGION  = $region

Write-Host "Profile '$profile' updated in $credPath" -ForegroundColor Green
Write-Host "Session: AWS_PROFILE=$profile, AWS_REGION=$region" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run: stratus list --platform aws" -ForegroundColor Yellow
Write-Host "     stratus detonate <technique-id> --cleanup" -ForegroundColor Gray
Write-Host ""
