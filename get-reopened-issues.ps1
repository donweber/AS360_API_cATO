param (
    [string]$ScanId,
    [string]$ApiKeyId = "your_api_key_id",
    [string]$ApiKeySecret = "your_api_key_secret"
)

echo $ScanId
echo $ApiKeyId
echo $ApiKeySecret

#$BaseUrl = "https://cloud.appscan.com/api"
# 
# use AppScan 360 for BaseUrl.
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"

# Authenticate and get token
$authBody = @{
    KeyId = $ApiKeyId
    KeySecret = $ApiKeySecret
} | ConvertTo-Json -Compress


echo $authBody
#$authBody="{\"KeyId\":\"local_b610f1fb-1c39-7bf2-a389-746c7d2abbbf\", \"KeySecret\":\"06qUZfPKBuaPbhKdjEXGG8rd7DDhCDdi4JKMf0Nj17/q\"}"
echo $authBody

echo $BaseUrl/Account/APIKeyLogin

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$requestUrl = "$BaseUrl/Account/APIKeyLogin"
echo $requestUrl

#try {
    $authResponse = Invoke-RestMethod -Uri "$BaseUrl/Account/APIKeyLogin" -Method Post -Body $authBody -ContentType "application/json"
     Write-Host "Auth Response: $($authResponse | ConvertTo-Json -Depth 3)"
    $token = $authResponse.Token
    echo $token
#} catch {
#    Write-Host $authResponse.Content
#    Write-Error "Failed to authenticate. Please check your API credentials."
#    exit 2
#}

if (-not $token) {
    Write-Error "Authentication token not received."
    exit 2
}



# Get issues for the scan
$headers = @{ Authorization = "Bearer $token" }
echo $headers

   echo $ScanId

  # $issuesUrl = "$BaseUrl/Issues/Scan/$ScanId?applyPolicies=None&`$top=100&`$count=false"
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

# Filter for Closed, Fixed, or Noise issues and map severity
$filteredIssues = $issuesResponse | Where-Object {
    $_.Status -in @("Reopened")
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