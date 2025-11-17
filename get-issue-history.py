import requests
import argparse
import json
import sys
import urllib3

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan Issue History and filter for Status=Fixed")
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

    # Build issue history URL
    issues_url = f"{base_url}/Issues/{args.IssueId}/History?includeAllScanExecutions=false&locale=en-US"
    print(f"Request URL: {issues_url}")

    urllib3.disable_warnings()

    try:
        issues_response = requests.get(issues_url, headers=headers, verify=False)
        issues_response.raise_for_status()
        issues_data = issues_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve issue history: {e}")
        sys.exit(3)

    if not issues_data or "Items" not in issues_data or len(issues_data["Items"]) == 0:
        print(f"No history found for Issue ID: {args.IssueId}")
        sys.exit(0)

    # Extract fields where Status changed to Fixed
    filtered = []
    for item in issues_data["Items"]:
        changes = item.get("Changes", [])
        for change in changes:
            if change.get("Property") == "Status" and change.get("NewValue") == "Fixed":
                filtered.append({
                    "Status": change.get("NewValue"),
                    "ChangedAt": item.get("ChangedAt"),
                    "ChangedId": item.get("ChangedBy", {}).get("Id"),
                    "ChangedFirstName": item.get("ChangedBy", {}).get("FirstName"),
                    "ChangedLastName": item.get("ChangedBy", {}).get("LastName"),
                    "ChangedUserName": item.get("ChangedBy", {}).get("UserName"),
                    "ChangedEmail": item.get("ChangedBy", {}).get("Email")
                })

    # Output filtered changes as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} changes found with status Fixed")

if __name__ == "__main__":
    main()
