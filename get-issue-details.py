import requests
import argparse
import json
import sys
import urllib3

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan Issue Details")
    parser.add_argument("--IssueId", required=True, help="Issue ID")
    parser.add_argument("--ApiKey", required=True, help="API Key")
    parser.add_argument("--ApiSecret", required=True, help="API Secret")
    args = parser.parse_args()

    # Base URL for AppScan 360
    base_url = "https://ip-192-168-69-208.appscan.il/api/v4"

    # Authenticate and get token
    auth_body = {
        "KeyId": args.ApiKey,
        "KeySecret": args.ApiSecret
    }

    urllib3.disable_warnings()

    try:
        auth_response = requests.post(
            f"{base_url}/Account/APIKeyLogin",
            headers={"Content-Type": "application/json"},
            data=json.dumps(auth_body),
            verify=False  # Disable SSL verification
        )
        auth_response.raise_for_status()
        token = auth_response.json().get("Token")
        if not token:
            print("Authentication token not received.")
            sys.exit(2)
        print(f"Auth successful. Token: {token}")
    except requests.RequestException as e:
        print(f"Failed to authenticate: {e}")
        sys.exit(2)

    # Prepare headers
    headers = {"Authorization": f"Bearer {token}"}

    # Build issue details URL
    issues_url = f"{base_url}/Issues/{args.IssueId}?applyPolicies=None&$top=100&count=false"
    print(f"Request URL: {issues_url}")
    urllib3.disable_warnings()


    try:
        issues_response = requests.get(issues_url, headers=headers, verify=False)
        issues_response.raise_for_status()
        issues_data = issues_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve issue details: {e}")
        sys.exit(3)

    if not issues_data or "Items" not in issues_data or len(issues_data["Items"]) == 0:
        print(f"No details found for Issue ID: {args.IssueId}")
        sys.exit(0)

    # Extract fields
    filtered = []
    for issue in issues_data["Items"]:
        filtered.append({
            "ApplicationId": issue.get("ApplicationId"),
            "scanId": issue.get("ScanId"),  # If available
            "issueId": issue.get("Id"),
            "cwe": issue.get("Cwe"),
            "status": issue.get("Status"),
            "severity": issue.get("Severity"),
            "lastUpdated": issue.get("LastUpdated"),
            "dateCreated": issue.get("DateCreated"),
            "lastFound": issue.get("LastFound"),
            "FixGroupId": issue.get("FixGroupId"),
            "FGStatus": issue.get("FGStatus"),
            "Source": issue.get("Source"),
            "CallingLine": issue.get("CallingLine"),
            "Context": issue.get("Context"),
            "DiffResult": issue.get("DiffResult"),
            "RemediationId": issue.get("RemediationId")
        })

    # Output filtered issues as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} issues found")

if __name__ == "__main__":
    main()