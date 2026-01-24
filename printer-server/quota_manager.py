"""
Quota management for the print server.
"""

import os
import json


def load_quota(quota_file):
    """Load quota from JSON file."""
    if os.path.exists(quota_file):
        try:
            with open(quota_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading quota file: {e}")
            return {}
    return {}


def save_quota(quota, quota_file):
    """Save quota to JSON file with atomic write."""
    try:
        # Write to temp file first (atomic operation)
        temp_file = quota_file + '.tmp'
        with open(temp_file, 'w') as f:
            json.dump(quota, f, indent=2)
        # Atomic rename
        os.replace(temp_file, quota_file)
    except Exception as e:
        print(f"Error saving quota file: {e}")
        # Clean up temp file if it exists
        if os.path.exists(quota_file + '.tmp'):
            try:
                os.remove(quota_file + '.tmp')
            except:
                pass


def get_team_quota(team_name, quota_file):
    """Get current quota for a team."""
    quota = load_quota(quota_file)
    return quota.get(team_name, 0)


def update_team_quota(team_name, pages, quota_file):
    """Update team quota after printing."""
    quota = load_quota(quota_file)
    quota[team_name] = quota.get(team_name, 0) + pages
    save_quota(quota, quota_file)
    return quota[team_name]


def reset_team_quota(team_name, quota_file):
    """Reset quota for a specific team."""
    quota = load_quota(quota_file)
    if team_name in quota:
        del quota[team_name]
        save_quota(quota, quota_file)
    return True
