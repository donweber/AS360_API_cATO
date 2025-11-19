import json
import argparse
from datetime import datetime

def normalize_timestamp(ts):
    if "." in ts:
        date_part, frac_part = ts.split(".")
        frac_part = frac_part.rstrip("Z")[:6]  # keep only 6 digits
        return f"{date_part}.{frac_part}Z"
    return ts


def parse_iso_date(date_str):
    date_str = normalize_timestamp(date_str)
    formats = [
        "%Y-%m-%dT%H:%M:%SZ",      # without fractional seconds
        "%Y-%m-%dT%H:%M:%S.%fZ"    # with fractional seconds
    ]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    raise ValueError(f"Invalid date format: {date_str}")



def filter_by_changed_at(data, input_date):
    input_dt = parse_iso_date(input_date)
    filtered = []
    for item in data:
        changed_dt = parse_iso_date(item["ChangedAt"])
        if changed_dt > input_dt:
            filtered.append(item)
    return filtered

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Filter JSON data to after input date")
    parser.add_argument("--JSON_data", required=True, help="JSON data")
    parser.add_argument("--AfterTimeStamp", required=True, help="After TimeStamp")
    args = parser.parse_args() 
    # Example usage:
    #
    json_filename = args.JSON_data

    # Read JSON data
    with open(json_filename, "r") as f:
       json_data = json.load(f)


    
    print(json.dumps(json_data, indent=4))
    #print(args.JSON_data)
    print(args.AfterTimeStamp)
    #result = filter_by_changed_at(json_data, "2025-11-03T15:00:58.8953259Z")
    result = filter_by_changed_at(json_data, args.AfterTimeStamp)

    print(json.dumps(result, indent=4, default=str))


if __name__ == "__main__":
    main()