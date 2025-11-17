$token = C:\Users\appscanadmin\cATO\getBearerToken.ps1 2f87fc7f-bdfd-445f-bd9b-2862078e44dc local_90e47a5b-9f48-fb1a-b59a-16ff0d03b76d l9d2k4MpW5iAeabh5mNMc26AMc1YnlvUm9bpQW4myGA9
echo "FlowAssy.ps1"
echo $token

C:\Users\appscanadmin\cATO\FetchIssues.ps1 2f87fc7f-bdfd-445f-bd9b-2862078e44dc $token.ToString()

#C:\Users\appscanadmin\cATO\get-reopened-issues.ps1 9d565b00-21c0-4d81-b428-9e279fe75409 local_90e47a5b-9f48-fb1a-b59a-16ff0d03b76d l9d2k4MpW5iAeabh5mNMc26AMc1Y