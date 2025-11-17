param (
    [Parameter(Mandatory=$true)][string]$ScanId,
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
} else { 
    return $token
}


