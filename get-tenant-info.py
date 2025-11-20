import requests
import argparse
import json
import urllib.parse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan Issues by Status")
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
    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json"
              }

    # Build issues URL with filter
    tenant_url = f"{base_url}/Account/TenantInfo"

    print(f"Request URL: {tenant_url}")

    try:
        tenant_response = requests.get(tenant_url, headers=headers, verify=False)
        tenant_response.raise_for_status()
        tenant_data = tenant_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve issues: {e}")
        sys.exit(3)

    if not tenant_data or "Items" not in tenant_data or len(tenant_data["Items"]) == 0:
        print(f"No tenant Info found")
        sys.exit(0)

    # Extract fields
    filtered = []
    for issue in tenant_data["Items"]:
        filtered.append({
            "TenantName": issue.get("TenantName"),
            "TenantId": issue.get("TenantId"),
            "ContactEmail": issue.get("ContactEmail"),
            "Subscriptions": issue.get("Subscriptions"),
            "SubscriptionTechnologies": issue.get("SubscriptionTechnologies"),
            "ActiveTechnologies": issue.get("ActiveTechnologies"),
            "UserInfo": issue.get("UserInfo"),
            "SCAEnabled": issue.get("SCAEnabled"),
            "MaxScansPerApp": issue.get("MaxScansPerApp"),
            "MaxUsers": issue.get("MaxUsers"),
            "OpenAIConfiguration": issue.get("OpenAIConfiguration"),
            "ReportCustomization": issue.get("ReportCustomization"),
            "NumAssetGroupsWithIssuesStatusInheritance": issue.get("NumAssetGroupsWithIssuesStatusInheritance")
        })

    # Output filtered issues as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} issues found with status {args.Status}")

if __name__ == "__main__":
    main()