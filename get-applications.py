import requests
import argparse
import json
import csv
import urllib.parse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch AppScan Applications")
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
            #print("Authentication token not received.")
            sys.exit(2)
        #print(f"Auth successful. Token: {token}")
    except requests.RequestException as e:
        print(f"Failed to authenticate: {e}")
        sys.exit(2)

    # Prepare headers
    headers = {"Authorization": f"Bearer {token}"}

    # Build URL
    apps_url = f"{base_url}/Apps?%24top=100&%24count=false"

    #print(f"Request URL: {apps_url}")

    try:
        apps_response = requests.get(apps_url, headers=headers, verify=False)
        apps_response.raise_for_status()
        app_data = apps_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve applications: {e}")
        sys.exit(3)

    if not app_data or "Items" not in app_data or len(app_data["Items"]) == 0:
        print(f"No Applications found")
        sys.exit(0)

    # Extract fields
    filtered = []
    for issue in app_data["Items"]:
        filtered.append({
            "applicationId": issue.get("ApplicationId"),
            "applicationName": issue.get("Name"),
            "RiskRating": issue.get("RiskRating"),
            "AssetGroupName": issue.get("AssetGroupName"),
            "AssetGroupId": issue.get("AssetGroupId"),
            "Url": issue.get("Url"),
            "Description": issue.get("Description"),
            "BusinessUnit": issue.get("BusinessUnit"),
            "BusinessUnitId": issue.get("BusinessUnitId"),
            "BusinessOwner": issue.get("BusinessOwner"),
            "CreatedBy": issue.get("CreatedBy"),
            "TestingStatus": issue.get("TestingStatus"),
            "TotalIssues": issue.get("TotalIssues")

        })

    # Output filtered issues as JSON
    #print(json.dumps(filtered, indent=4))

    # Print summary
    #print(f"Summary: {len(filtered)} applications found")

    csv_file = "applications.csv"
    
    # Get keys from the first subscription for header
    if filtered:
        headers = filtered[0].keys()

    # Write to CSV
        with open(csv_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            writer.writerows(filtered)

        print(f"CSV file '{csv_file}' created successfully.")
    else:
        print("No applications found in JSON.")


if __name__ == "__main__":
    main()