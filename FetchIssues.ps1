param (
    [Parameter(Mandatory=$true)][string]$ScanId,
    [Parameter(Mandatory=$true)][string]$token
)

echo "Fetch Issues"
echo $ScanId
echo $token

#$BaseUrl = "https://cloud.appscan.com/api"
# 
# use AppScan 360 for BaseUrl.
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"

# Fetch issues
#try {
    $headers = @{ Authorization = "Bearer $token" }
    echo $headers
    echo $BaseUrl/Issues/Scan/$ScanId
   # https://ip-192-168-69-208.appscan.il/api/v4/Issues/Scan/9d565b00-21c0-4d81-b428-9e279fe75409?applyPolicies=None&%24top=100&%24count=false

   $issuesUrl = "$BaseUrl/Issues/Scan/$ScanId?applyPolicies=None&`$top=100&`$count=false"
   Write-Host "Request URL: $issuesUrl"

   $issuesResponse = Invoke-RestMethod -Uri $issuesUrl -Headers $headers -Method Get
   Write-Host ($issuesResponse | ConvertTo-Json -Depth 3)

#} catch {
   # Write-Error "Failed to retrieve issues or response is not valid JSON."
   # exit 3
#}

if (-not $issuesResponse -or $issuesResponse.Count -eq 0) {
    Write-Host "No issues found for scan ID: $ScanId"
    exit 0
}
