param (
    [Parameter(Mandatory=$true)][string]$IssueId,
    [Parameter(Mandatory=$true)][string]$ApiKey,
    [Parameter(Mandatory=$true)][string]$ApiSecret
)

#$BaseUrl = "https://cloud.appscan.com/api"
# 
# use AppScan 360 for BaseUrl.
$BaseUrl = "https://ip-192-168-69-208.appscan.il/api/v4"

# Authenticate and get token
$authBody = @{
    KeyId = $ApiKey
    KeySecret = $ApiSecret
} | ConvertTo-Json #-Compress


[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    $authResponse = Invoke-RestMethod -Uri "$BaseUrl/Account/APIKeyLogin" -Method POST -Body $authBody -ContentType "application/json"
     Write-Host "Auth Response: $($authResponse | ConvertTo-Json -Depth 3)"
    $token = $authResponse.Token

if (-not $token) {
    Write-Error "Authentication token not received."
    exit 2
}

# Fetch issue
   $headers = @{ Authorization = "Bearer $token" }
 

   $issuesUrl = "$BaseUrl/Issues/" + $IssueId + "/History?includeAllScanExecutions=false&locale=en-US"
   Write-Host "Request URL: $issuesUrl"

   $issuesResponse = Invoke-RestMethod -Uri $issuesUrl -Headers $headers -Method Get


if (-not $issuesResponse -or $issuesResponse.Count -eq 0) {
    Write-Host "No issues found for scan ID: $ScanId"
    exit 0
}


#$items = $issuesResponse | ConvertFrom-Json

#echo $items

# Iterate over the array
echo ------------------------------
echo "extract fields"


$filtered = foreach ( $issue in $issueResponse.Items ) {
    #Write-Host $issue.Changes
    $statusChange = $issue.Changes | Where-Object { $issue.Property -eq "Status" -and $issue.NewValue -eq "Fixed" }
    #$statusChange=1
    #Write-Host $statusChange

    if ($statusChange) {
        [
        PSCustomObject]@{
        Status     = $statusChange.NewValue
        ChangedAt  = $issue.ChangedAt
        ChangedId  = $issue.ChangedBy.Id
        ChangedFirstName  = $issue.ChangedBy.FirstName
        ChangedLastName  = $issue.ChangedBy.LastName
        ChangedUserName  = $issue.ChangedBy.Email
        ChangedEmail  = $issue.ChangedBy.Email
        }
     }
}


#echo $issue
#    [
#PSCustomObject]@{
#
#        scanName      = $issue.ScanExecution.ScanName
#        scanId        = $issue.ScanExecution.ScanId
#        ExecutionId   = $issue.ScanExecution.ExecutionId
#        issueId       = $issueId
#        ChangedAt     = $issue.ChangedAt
#        ChangedBy     = $issue.ChangedBy
#        Changes       = $issue.Changes
#        
#
        #cwe           = $issue.Cwe
        #status        = $issue.Status
        #severity      = $issue.Severity
        #lastUpdated   = $issue.LastUpdated
        #dateCreated   = $issue.DateCreated
        #lastFound     = $issue.LastFound
        #isNew         = ($issue.DateCreated -eq $issue.LastFound)
        #isReopened    = ($issue.LastUpdated.Date -eq $issue.DateCreated.Date)
        #isModified    = ($issue.DateCreated.Date -lt $issue.LastUpdated.Date)
#    }
#}

# Output filtered issues as JSON
$filtered | ConvertTo-Json -Depth 3

# Print summary
$issueCount = $filtered.Count
Write-Host "Summary: $issueCount issues found with status Fixed"