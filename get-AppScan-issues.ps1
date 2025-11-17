param (
    [Parameter(Mandatory=$true)][string]$Scope,
    [Parameter(Mandatory=$true)][string]$ScanId,
    [Parameter(Mandatory=$true)][string]$ApiKey,
    [Parameter(Mandatory=$true)][string]$ApiSecret,
    [Parameter(Mandatory=$true)][string]$Status
)

#$BaseUrl = "https://cloud.appscan.com/api"
# 
# use AppScan 360 for BaseUrl.
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"

# Authenticate and get token
$authBody = @{
    KeyId = $ApiKey
    KeySecret = $ApiSecret
} | ConvertTo-Json -Compress


echo $authBody
#$authBody="{\"KeyId\":\"local_b610f1fb-1c39-7bf2-a389-746c7d2abbbf\", \"KeySecret\":\"06qUZfPKBuaPbhKdjEXGG8rd7DDhCDdi4JKMf0Nj17/q\"}"
echo $authBody

echo $BaseUrl/Account/APIKeyLogin

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

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



# Fetch issues
#try {
    $headers = @{ Authorization = "Bearer $token" }
    echo $headers
   # echo $BaseUrl/Issues/Scan/$ScanId
   # https://ip-192-168-69-208.appscan.il/api/v4/Issues/$Scope/9d565b00-21c0-4d81-b428-9e279fe75409?applyPolicies=None&%24top=100&%24count=false

   #$issuesUrl = "$BaseUrl/Issues/Scan/$ScanId?applyPolicies=None&`$top=100&`$count=false"
   $filter="filter=Status eq '" + $Status + "'"
   #$filter=Status eq 'Fixed'
   $encodedFilter = [System.Web.HttpUtility]::UrlEncode($filter)
   echo $encodedFilter

   $issuesUrl = "$BaseUrl/Issues/" + $Scope +"/" + $ScanId + "?applyPolicies=None&`$top=100&count=false&" + $filter
   Write-Host "Request URL: $issuesUrl"
   #Write-Host "headers: $headers"

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

Write-Host ($issuesResponse | ConvertTo-Json -Depth 3)
#echo "Now filter the issues!"

#$items = $issuesResponse | ConvertFrom-Json

#echo $items

# Iterate over the array
#foreach ($item in $items) {
#    Write-Host "ID: $($item.id), Name: $($item.name)"
#}

#    echo $issuesResponse.Status


 

# Filter and transform issues
#$filtered = $issuesResponse | Where-Object {
#    $_.Status -in '^(?.)(Open|Reopened|In Progress)$'
#    $_.Status.Trim -match 'Open'
#    $_.Status -and $_.Status.Trim() -in @("Open", "Reopened", "In Progress")
#} | 

#ForEach-Object {
echo ------------------------------
echo "extract fields"
#echo $issuesResponse Get-Process | Out-File -FilePath C:\Users\appscanadmin\cATO\issueResponse.json

$filtered = foreach ( $issue in $issuesResponse.Items ) {
#echo $issue
    [
PSCustomObject]@{
        applicationId = $Issue.ApplicationId
        scanId        = $ScanId
        issueId       = $issue.Id
        cwe           = $issue.Cwe
        FixGroupId    = $issue.FixGroupId
        status        = $issue.Status
        severity      = $issue.Severity
        lastUpdated   = $issue.LastUpdated
        dateCreated   = $issue.DateCreated
        lastFound     = $issue.LastFound
    }
}

# Output filtered issues as JSON
$filtered | ConvertTo-Json -Depth 3

# Print summary
$issueCount = $filtered.Count
Write-Host "Summary: $issueCount issues found with status " + $Status