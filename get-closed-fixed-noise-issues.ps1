param (
    [string]$ScanId,
    [string]$ApiKeyId = "your_api_key_id",
    [string]$ApiKeySecret = "your_api_key_secret"
)

echo $ScanId
echo $ApiKeyId
echo $ApiKeySecret

# Disable SSL certificate validation if needed (for internal/self-signed certs)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

#$BaseUrl = "https://cloud.appscan.com/api"
# 
# use AppScan 360 for BaseUrl.
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"

# Authenticate and get token
$authBody = @{
    KeyId = $ApiKeyId
    KeySecret = $ApiKeySecret
} | ConvertTo-Json -Compress

echo $BaseUrl/Account/APIKeyLogin
echo $authBody


[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

#try {
    $authResponse = Invoke-RestMethod -Uri "$BaseUrl/Account/APIKeyLogin" -Method Post -Body $authBody -ContentType "application/json"
    Write-Host "Auth Response: $($authResponse | ConvertTo-Json -Depth 3)"
    $token = $authResponse.Token
    echo $token
#} 
#   catch {
#    Write-Error "Authentication failed. Please check your API credentials."
#    exit 1
#}



if (-not $token) {
    Write-Error "Token not received. Authentication failed."
    exit 1
}

# Get issues for the scan
$headers = @{ Authorization = "Bearer $token" }
echo $headers

   echo $ScanId

   #$issuesUrl = "$BaseUrl/Issues/Scan/$ScanId?applyPolicies=None&`$top=100&`$count=false"

   $issuesUrl = "$BaseUrl/Issues/Scan/" + $ScanId + "?applyPolicies=None&`$top=100&`$count=false"

   Write-Host "Request URL: $issuesUrl"
   echo $issuesUrl

   $issuesResponse = Invoke-RestMethod -Uri $issuesUrl -Headers $headers -Method Get
   echo $issuesResponse


#try {
#    $issuesResponse = Invoke-RestMethod -Uri "$BaseUrl/v4/Issues/Scan/$ScanId" -Headers $headers -Method Get
#} catch {
#    Write-Error "Failed to retrieve issues."
#    exit 2
#}

echo "Now filter the issues!"
Write-Host ($issuesResponse | ConvertTo-Json -Depth 3)


# Filter for Closed, Fixed, or Noise issues and map severity
$filteredIssues = $issuesResponse | Where-Object {
    $_.Status -in @("Closed", "Fixed", "Noise")
} | ForEach-Object {
    [PSCustomObject]@{
        issueId  = $_.Id
        cwe      = $_.CweId
        severity = switch ($_.Severity) {
            5 { "critical" }
            4 { "high" }
            3 { "medium" }
            2 { "low" }
            1 { "informational" }
            default { "unknown" }
        }
    }
}

# Output as JSON
$filteredIssues | ConvertTo-Json -Depth 3
echo $filteredIssues