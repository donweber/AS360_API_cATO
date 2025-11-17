from datetime import datetime

def compare_timestamps(t1: str, t2: str):
    """
    Compare two ISO 8601 timestamps and return the difference in days, hours, and minutes.
    
    Args:
        t1 (str): First timestamp (e.g., '2025-09-06T08:57:07.0952628Z')
        t2 (str): Second timestamp (e.g., '2025-11-14T18:31:24.1280083Z')
    
    Returns:
        dict: Difference in days, hours, minutes, and total seconds.
    """
    fmt = "%Y-%m-%dT%H:%M:%S.%fZ"
    
    # Normalize fractional seconds to microseconds (Python supports up to 6 digits)
    dt1 = datetime.strptime(t1[:26] + "Z", fmt)
    dt2 = datetime.strptime(t2[:26] + "Z", fmt)
    
    diff = dt2 - dt1
    days = diff.days
    total_seconds = diff.total_seconds()
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    
    return {
        "days": days,
        "hours": int(hours),
        "minutes": int(minutes),
        "total_seconds": int(total_seconds)
    }

# Example usage:
result = compare_timestamps("2025-09-06T08:57:07.0952628Z", "2025-11-14T18:31:24.1280083Z")
print(result)