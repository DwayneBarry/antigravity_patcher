# Antigravity Universal Patcher V3 - All Emails Unlocked
# Target: Windows

Write-Host "=== Antigravity UNIVERSAL UNLOCKER (v3 - All Emails) ===" -ForegroundColor Cyan
Write-Host "Initializing..."

# 1. Dynamic Path Resolution
$possiblePaths = @(
    "$env:LOCALAPPDATA\Programs\Antigravity\resources\app\out\main.js",
    "D:\Antigravity\resources\app\out\main.js",
    "C:\Program Files\Antigravity\resources\app\out\main.js",
    "$PSScriptRoot\..\main.js",
    "$PSScriptRoot\main.js"
)

$targetPath = $null
foreach ($p in $possiblePaths) {
    if (Test-Path -Path $p) {
        $targetPath = $p
        break
    }
}

if (-not $targetPath) {
    Write-Host "[ERROR] Could not find Antigravity installation (main.js)!" -ForegroundColor Red
    Write-Host "Please check if Antigravity is installed."
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "[INFO] Target found: $targetPath"

# 2. Read File
$content = Get-Content -Path $targetPath -Raw
if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Host "[ERROR] main.js is empty! Restore from backup first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# 3. Remove old God Mode patch (email check) if present
if ($content.Contains("createRequire")) {
    Write-Host "[INFO] Removing old email check patch..."
    $pattern = '(?s)import \{ createRequire.*?\}\)\(\);\s*'
    $content = $content -replace $pattern, ""
    $content = $content.TrimStart()
}

# 4. Create Backup
Write-Host "[INFO] Creating backup..."
Copy-Item -Path $targetPath -Destination "$targetPath.bak" -Force

# 5. Detect Antigravity version from product.json (informational)
$appDir = Split-Path (Split-Path $targetPath)
$prodPath = Join-Path $appDir "product.json"
$agVersion = "unknown"
if (Test-Path $prodPath) {
    try {
        $prod = Get-Content $prodPath -Raw | ConvertFrom-Json
        if ($prod.ideVersion) { $agVersion = $prod.ideVersion }
    } catch {}
}

# 6. Apply DYNAMIC Feature Unlock (works for ALL emails)
$unlockApplied = $false

# Check if already patched
if ($content.Contains("[HACK] FORCE LOGIN")) {
    Write-Host "[INFO] Feature Unlock already present." -ForegroundColor Yellow
    $unlockApplied = $true
}

if (-not $unlockApplied) {
    # Find the unique end anchor first, then search backwards for function start
    $endAnchor = '"only sensitiveData may contain user data"'
    $endIdx = $content.IndexOf($endAnchor)

    if ($endIdx -gt 0) {
        # Search backwards from end anchor
        $searchBack = 5000
        $regionStart = [Math]::Max(0, $endIdx - $searchBack)
        $region = $content.Substring($regionStart, $endIdx - $regionStart)

        # Find the LAST "async X(Y){if([optional_code,]this.Z.isGoogleInternal)"
        $funcMatch = [regex]::Matches($region, 'async\s+(\w+)\((\w+)\)\{if\([^{]*?this\.(\w+)\.isGoogleInternal\)')

        if ($funcMatch.Count -gt 0) {
            $lastMatch = $funcMatch[$funcMatch.Count - 1]
            $funcName = $lastMatch.Groups[1].Value
            $argName = $lastMatch.Groups[2].Value
            $ctxProp = $lastMatch.Groups[3].Value

            # Calculate actual start position in the full content
            $actualStart = $regionStart + $lastMatch.Index

            # Find end: skip past end anchor + closing "))}}
            $afterEnd = $endIdx + $endAnchor.Length
            $closingChars = $content.Substring($afterEnd, [Math]::Min(10, $content.Length - $afterEnd))
            $extraClose = 0
            foreach ($ch in $closingChars.ToCharArray()) {
                $extraClose++
                if ($ch -eq '}') {
                    $soFar = $closingChars.Substring(0, $extraClose)
                    if ($soFar.Contains('}}')) { break }
                }
            }
            $funcEnd = $afterEnd + $extraClose

            $originalFunc = $content.Substring($actualStart, $funcEnd - $actualStart)

            # Extract minified property names from original function
            $svc = "t"
            $m = [regex]::Match($originalFunc, 'this\.(\w+)\.loadCodeAssist')
            if ($m.Success) { $svc = $m.Groups[1].Value }

            $evt = "h"
            $m = [regex]::Match($originalFunc, 'this\.(\w+)\.fire\(')
            if ($m.Success) { $evt = $m.Groups[1].Value }

            $push = "z"
            $m = [regex]::Match($originalFunc, 'this\.(\w+)\.pushUpdate')
            if ($m.Success) { $push = $m.Groups[1].Value }

            $pushHelper = ""
            $m = [regex]::Match($originalFunc, '=(\w+)\(\w+\);this\.\w+\.pushUpdate')
            if ($m.Success) { $pushHelper = $m.Groups[1].Value }

            # Build replacement (no email checks)
            if ($pushHelper -ne "") {
                $replacement = "async $funcName($argName){console.log(`"[HACK] FORCE LOGIN`");if(this.$ctxProp.isGoogleInternal){try{await this.$svc.loadCodeAssist($argName);const{settings:n,userTier:a}=await this.refreshUserStatus($argName),_s=$pushHelper($argName);this.$push.pushUpdate(_s),this.$evt.fire({settings:n,userTier:a})}catch(_){}return}try{try{await this.$svc.loadCodeAssist($argName)}catch(_){}this.$evt.fire({oauthTokenInfo:$argName});try{await this.$svc.onboardUser(`"standard-tier`",$argName)}catch(_){try{await this.$svc.onboardUser(`"free-tier`",$argName)}catch(__){}}try{const{settings:p,userTier:g}=await this.refreshUserStatus($argName),_b=$pushHelper($argName);this.$push.pushUpdate(_b),this.$evt.fire({settings:p,userTier:g})}catch(_){}console.log(`"[HACK] DONE`")}catch(n){this.$evt.fire({oauthTokenInfo:$argName})}}"
            } else {
                $replacement = "async $funcName($argName){console.log(`"[HACK] FORCE LOGIN`");if(this.$ctxProp.isGoogleInternal){try{await this.$svc.loadCodeAssist($argName);const{settings:n,userTier:a}=await this.refreshUserStatus($argName);this.$evt.fire({settings:n,userTier:a})}catch(_){}return}try{try{await this.$svc.loadCodeAssist($argName)}catch(_){}this.$evt.fire({oauthTokenInfo:$argName});try{await this.$svc.onboardUser(`"standard-tier`",$argName)}catch(_){try{await this.$svc.onboardUser(`"free-tier`",$argName)}catch(__){}}try{const{settings:p,userTier:g}=await this.refreshUserStatus($argName);this.$evt.fire({settings:p,userTier:g})}catch(_){}console.log(`"[HACK] DONE`")}catch(n){this.$evt.fire({oauthTokenInfo:$argName})}}"
            }

            $content = $content.Substring(0, $actualStart) + $replacement + $content.Substring($funcEnd)
            $unlockApplied = $true
        } else {
            Write-Host "[WARN] Could not parse auth function signature." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] Auth anchor not found. Feature unlock may not be applied." -ForegroundColor Yellow
    }
}

# 7. Write patched file
[System.IO.File]::WriteAllText($targetPath, $content, [System.Text.Encoding]::UTF8)

if ($unlockApplied) {
    Write-Host "[INFO] Feature Unlock applied (Dynamic Method v$agVersion)." -ForegroundColor Green
    Write-Host "[SUCCESS] Licensed to: All emails (unlocked)" -ForegroundColor Green
} else {
    Write-Host "[NOTE] No changes were necessary." -ForegroundColor Yellow
}

Write-Host "You can now run Antigravity."
