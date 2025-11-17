<#
.SYNOPSIS
  Retrieves an AppScan on Cloud Issue by ID and returns a JSON array with selected fields
  (CWE, severity, status, cvss, cvssVersion, discoveryMethod, scanner, ScanName).

.DESCRIPTION
  Uses ASoC v4 REST API:
    - POST /api/v4/Account/ApiKeyLogin           (get bearer token)
    - GET  /api/v4/Issues(<IssueId>)             (issue by key route)  [fallback to OData $filter]
    - GET  /api/v4/Scans(<ScanId>)               (scan by key route)   [fallback to OData $filter]

.PARAMETER IssueId
  The Issue GUID (or string) as shown in ASoC.

.PARAMETER BaseUrl
  Optional. Defaults to North America DC: https://cloud.appscan.com
  Use the EU DC if applicable: https://eu.cloud.appscan.com

.PARAMETER KeyId
  Optional. If not provided, script uses environment variable ASoC_KEY_ID.

.PARAMETER KeySecret
  Optional. If not provided, script uses environment variable ASoC_KEY_SECRET.

.EXAMPLE
  # Using environment variables
  $env:ASoC_KEY_ID     = "YOUR_KEY_ID"
  $env:ASoC_KEY_SECRET = "YOUR_KEY_SECRET"
  .\Get-ASoCIssue.ps1 -IssueId 9ea1fcb6-dc1d-443a-bfff-7465ced2ef1b

.EXAMPLE
  # Passing credentials and EU DC
  .\Get-ASoCIssue.ps1 -IssueId 9ea1fcb6-dc1d-443a-bfff-7465ced2ef1b `
                      -KeyId YOUR_KEY_ID -KeySecret YOUR_KEY_SECRET `
                      -BaseUrl https://eu.cloud.appscan.com

.OUTPUTS
  JSON array with one object:
  [
    {
      "CWE": "79",
      "severity": "High",
      "status": "Open",
      "cvss": "8.8",
      "cvssVersion": "3.1",
      "discoveryMethod": "Dynamic",
      "scanner": "DAST",
      "ScanName": "My Nightly DAST"
    }
  ]
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$IssueId,
  [string]$KeyId    = $env:ASoC_KEY_ID,
  [string]$KeySecret= $env:ASoC_KEY_SECRET
)

#$BaseUrl = "https://cloud.appscan.com"
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"
echo $BaseUrl


$ErrorActionPreference = 'Stop'

function Invoke-Json {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    [hashtable]$Headers
  )
  Invoke-RestMethod -Method GET -Uri $Url -Headers $Headers -Accept 'application/json'
}

function Get-AccessToken {
  param(
    [Parameter(Mandatory=$true)][string]$BaseUrl,
    [Parameter(Mandatory=$true)][string]$KeyId,
    [Parameter(Mandatory=$true)][string]$KeySecret
  )
  $loginBody = @{
    KeyId     = $KeyId
    KeySecret = $KeySecret
  } | ConvertTo-Json

  $loginUrl = "$BaseUrl/api/v4/Account/ApiKeyLogin"
  $resp = Invoke-RestMethod -Method POST -Uri $loginUrl `
          -ContentType 'application/json' -Body $loginBody `
          -Accept 'application/json'
  if (-not $resp.Token) {
    throw "Failed to obtain access token (check KeyId/KeySecret)."
  }
  return $resp.Token
}

function TryGet-Issue {
  param(
    [Parameter(Mandatory=$true)][string]$BaseUrl,
    [Parameter(Mandatory=$true)][string]$IssueId,
    [Parameter(Mandatory=$true)][hashtable]$Headers
  )

  # 1) Try key route: /api/v4/Issues(<IssueId>)
  try {
    $issueUrlKey = "$BaseUrl/api/v4/Issues($IssueId)"
    return (Invoke-Json -Url $issueUrlKey -Headers $Headers)
  } catch {
    # 2) Fallback: /api/v4/Issues?$filter=Id eq <IssueId> & $top=1
    $encodedFilter = [uri]::EscapeDataString(
      (if ($IssueId -match '^[0-9a-fA-F-]+$') { "Id eq $IssueId" } else { "Id eq '$IssueId'" })
    )
    $issueUrlFilter = "$BaseUrl/api/v4/Issues?`$top=1&`$filter=$encodedFilter"
    $collection = Invoke-Json -Url $issueUrlFilter -Headers $Headers
    if ($collection.value -and $collection.value.Count -gt 0) { return $collection.value[0] }
    throw "Issue not found by ID: $IssueId"
  }
}

function TryGet-ScanName {
  param(
    [Parameter(Mandatory=$true)][string]$BaseUrl,
    [Parameter(Mandatory=$true)][string]$ScanId,
    [Parameter(Mandatory=$true)][hashtable]$Headers
  )
  if ([string]::IsNullOrWhiteSpace($ScanId)) { return $null }

  # 1) Try key route
  try {
    $scanUrlKey = "$BaseUrl/api/v4/Scans($ScanId)"
    $scanObj = Invoke-Json -Url $scanUrlKey -Headers $Headers
    if ($scanObj.Name) { return $scanObj.Name }
  } catch { }

  # 2) Fallback: filter + select
  try {
    $encodedFilter = [uri]::EscapeDataString(
      (if ($ScanId -match '^[0-9a-fA-F-]+$') { "Id eq $ScanId" } else { "Id eq '$ScanId'" })
    )
    $scanUrlFilter = "$BaseUrl/api/v4/Scans?`$top=1&`$select=Id,Name&`$filter=$encodedFilter"
    $collection = Invoke-Json -Url $scanUrlFilter -Headers $Headers
    if ($collection.value -and $collection.value.Count -gt 0) {
      return $collection.value[0].Name
    }
  } catch { }
  return $null
}

function Get-Field {
  param(
    [Parameter(Mandatory=$true)]$Object,
    [Parameter(Mandatory=$true)][string[]]$Candidates
  )
  foreach ($name in $Candidates) {
    if ($Object.PSObject.Properties.Name -contains $name) {
      $val = $Object.$name
      if ($null -ne $val -and $val -ne '') { return $val }
    }
  }
  return $null
}

# --- validate credentials ---
if ([string]::IsNullOrWhiteSpace($KeyId) -or [string]::IsNullOrWhiteSpace($KeySecret)) {
  throw "Provide ASoC credentials: -KeyId/-KeySecret parameters or set env vars ASoC_KEY_ID / ASoC_KEY_SECRET."
}

# --- 1) Authenticate ---
$token = Get-AccessToken -BaseUrl $BaseUrl -KeyId $KeyId -KeySecret $KeySecret
$headers = @{ Authorization = "Bearer $token" }

# --- 2) Get issue ---
$issue = TryGet-Issue -BaseUrl $BaseUrl -IssueId $IssueId -Headers $headers

# --- 3) Extract fields (robust across scanner types) ---
$cwe            = Get-Field -Object $issue -Candidates @('CweId','CWE','Cwe','CweID','PrimaryCweId','PrimaryCWE')
$severity       = Get-Field -Object $issue -Candidates @('Severity','severity','IssueSeverity')
$status         = Get-Field -Object $issue -Candidates @('Status','status','IssueStatus')
$cvss           = Get-Field -Object $issue -Candidates @('Cvss','cvss','CvssScore','CVSS')
$cvssVersion    = Get-Field -Object $issue -Candidates @('CvssVersion','cvssVersion','CVSSVersion')
$discoveryMethod= Get-Field -Object $issue -Candidates @('DiscoveryMethod','discoveryMethod','DetectionMethod')
$scanner        = Get-Field -Object $issue -Candidates @('Scanner','scanner','ScanType','Source')
$scanId         = Get-Field -Object $issue -Candidates @('ScanId','scanId','ParentScanId')
$scanName       = $null

# --- 4) Lookup scan name when ScanId is available ---
if ($scanId) {
  $scanName = TryGet-ScanName -BaseUrl $BaseUrl -ScanId $scanId -Headers $headers
}

# --- 5) Build JSON array with one object ---
$result = @(
  [pscustomobject]@{
    CWE             = $cwe
    severity        = $severity
    status          = $status
    cvss            = $cvss
    cvssVersion     = $cvssVersion
    discoveryMethod = $discoveryMethod
    scanner         = $scanner
    ScanName        = $scanName
  }
)

$result | ConvertTo-Json -Depth 6
``