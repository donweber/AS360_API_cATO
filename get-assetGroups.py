import requests
import argparse
import json
import urllib.parse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan Asset Groups")
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
    headers = {"Authorization": f"Bearer {token}"}

    # Build URL
    assetGroups_url = f"{base_url}/AssetGroups?%24top=100&%24count=false"

    print(f"Request URL: {assetGroups_url}")

    try:
        assetGroups_response = requests.get(assetGroups_url, headers=headers, verify=False)
        assetGroups_response.raise_for_status()
        assetGroup_data = assetGroups_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve applications: {e}")
        sys.exit(3)

    if not assetGroup_data or "Items" not in assetGroup_data or len(assetGroup_data["Items"]) == 0:
        print(f"No Applications found")
        sys.exit(0)

    # Extract fields
    filtered = []
    for issue in assetGroup_data["Items"]:
        filtered.append({
            "assetGroupId": issue.get("ApplicationId"),
            "assetGroupName": issue.get("Name"),
            "AppsCount": issue.get("AppsCount"),
            "UsersCount": issue.get("UsersCount"),
        })

    # Output filtered issues as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} applications found")

if __name__ == "__main__":
    main()