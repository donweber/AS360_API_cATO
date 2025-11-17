import requests
import argparse
import json
import urllib.parse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan issues by status")
    parser.add_argument("--Scope", required=True, help="Scope ID")
    parser.add_argument("--ScanId", required=True, help="Scan ID")
    parser.add_argument("--ApiKey", required=True, help="API Key")
    parser.add_argument("--ApiSecret", required=True, help="API Secret")
    parser.add_argument("--Status", required=True, help="Status filter (e.g., Fixed)")
    args = parser.parse_args()

    # Base URL for AppScan 360
    base_url = "https://ip-192-168-69-208.appscan.il/api/v4"

    # Authenticate and get token
    auth_body = {
        "KeyId": args.ApiKey,
        "KeySecret": args.ApiSecret
    }

    try:
        auth_response = requests.post(f"{base_url}/Account/APIKeyLogin",
                                      headers={"Content-Type": "application/json"},
                                      data=json.dumps(auth_body),
                                      verify=False)  # Disable SSL verification
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

    # Build issues URL with filter
    filter_query = f"filter=Status eq '{args.Status}'"
    encoded_filter = urllib.parse.quote(filter_query)
    issues_url = f"{base_url}/FixGroups/{args.Scope}/{args.ScanId}?applyPolicies=None&$top=100&count=false&{filter_query}"

    print(f"Request URL: {issues_url}")

    try:
        issues_response = requests.get(issues_url, headers=headers, verify=False)
        issues_response.raise_for_status()
        issues_data = issues_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve issues: {e}")
        sys.exit(3)

    if not issues_data or "Items" not in issues_data or len(issues_data["Items"]) == 0:
        print(f"No issues found for scan ID: {args.ScanId}")
        sys.exit(0)

    # Extract fields
    filtered = []
    for issue in issues_data["Items"]:
        filtered.append({
            "applicationId": issue.get("AppId"),
            "scanId": args.ScanId,
            "issueId": issue.get("Id"),
            "FixGroupType": issue.get("FixGroupType"),
            "FixGroupId": issue.get("Id"),
            "Subject": issue.get("Subject"),
            "Language": issue.get("Language"),
            "status": issue.get("Status"),
            "severity": issue.get("Severity"),
            "File": issue.get("File"),
            "Line": issue.get("Line"),
            "NIssues": issue.get("NIssues"),
            "NOpenIssues": issue.get("NOpenIssues"),
            "lastUpdated": issue.get("LastUpdated"),
            "dateCreated": issue.get("DateCreated"),
            "lastFound": issue.get("LastFound")
        })

    # Output filtered issues as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} issues found with status {args.Status}")

if __name__ == "__main__":
    main()