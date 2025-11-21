import requests
import argparse
import json
import urllib.parse
import sys

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Fetch Scan Executions by Scan Id")
    parser.add_argument("--ScanId", required=True, help="Scan ID")
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
        #print(f"Failed to authenticate: {e}")
        sys.exit(2)

    # Prepare headers
    #headers = {"Authorization: fBearer {token}", 
    #           "Content-Type: application/json"
    #        }
    headers = {"Authorization": f"Bearer {token}"}


    # Build issues URL with filter
    executions_url = f"{base_url}/Scans/{args.ScanId}/Executions?%24top=100&%24count=false"
    #https://ip-192-168-69-208.appscan.il/api/v4/Scans/{args.ScanId}/Executions?%24top=100&%24count=false
    print(f"Request headers: {headers}")
    print(f"Request URL: {executions_url}")

    try:
        executions_response = requests.get(executions_url, headers=headers, verify=False)
        executions_response.raise_for_status()
        execution_data = executions_response.json()
    except requests.RequestException as e:
        print(f"Failed to retrieve executions: {e}")
        sys.exit(3)

    #if not execution_data or "Items" not in execution_data or len(execution_data["Items"]) == 0:
    #    print(f"No executions found for scan ID: {args.ScanId}")
    #    sys.exit(0)

    # Extract fields
    filtered = []
    #for issue in execution_data["Items"]:
    for item in execution_data:
        filtered.append({
            "executionId": item.get("Id"),
            "scanId": args.ScanId,
            "ExecutedAt": item.get("ExecutedAt"),
            "ExecutionDurationSec": item.get("ExecutionDurationSec"),
            "Status": item.get("Status"),
            "ExecutionProgress": item.get("ExecutionProgress"),
            "SupportModeEnabled": item.get("SupportModeEnabled")
        })

    # Output filtered issues as JSON
    print(json.dumps(filtered, indent=4))

    # Print summary
    print(f"Summary: {len(filtered)} executions found for scanId {args.ScanId}")

if __name__ == "__main__":
    main()