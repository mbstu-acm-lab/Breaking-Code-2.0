"""
Common utility functions shared between automated and simple servers.
"""

import os
import csv
import shutil


def load_teams(seat_plan_file):
    """Load team names from CSV file."""
    teams = []
    if os.path.exists(seat_plan_file):
        try:
            with open(seat_plan_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    team_name = row.get('Team Name', '').strip()
                    if team_name:
                        teams.append(team_name)
        except Exception as e:
            print(f"Error loading teams: {e}")
    return sorted(teams)


def get_team_info(team_name, seat_plan_file):
    """Get team information (room, desk) from CSV file."""
    if os.path.exists(seat_plan_file):
        try:
            with open(seat_plan_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row.get('Team Name', '').strip() == team_name:
                        return {
                            'room': row.get('Room', '').strip(),
                            'desk': row.get('Desk No', '').strip(),
                            'team': team_name
                        }
        except Exception as e:
            print(f"Error loading team info: {e}")
    return {'room': '', 'desk': '', 'team': team_name}


def load_team_details(seat_plan_file):
    """Load all team details into a dictionary."""
    team_details = {}
    if os.path.exists(seat_plan_file):
        try:
            with open(seat_plan_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    team_name = row.get('Team Name', '').strip()
                    if team_name:
                        team_details[team_name] = {
                            'room': row.get('Room', '').strip(),
                            'desk': row.get('Desk No', '').strip()
                        }
        except Exception as e:
            print(f"Error loading team details: {e}")
    return team_details


def move_to_completed(file_path, team, upload_dir):
    """Move file to completed directory after successful printing."""
    try:
        team_folder = os.path.join(upload_dir, team)
        completed_folder = os.path.join(team_folder, "completed")
        os.makedirs(completed_folder, exist_ok=True)
        
        filename = os.path.basename(file_path)
        dest_path = os.path.join(completed_folder, filename)
        
        # If file already exists, add counter to avoid overwrite
        if os.path.exists(dest_path):
            base, ext = os.path.splitext(filename)
            counter = 1
            while os.path.exists(os.path.join(completed_folder, f"{base}_{counter}{ext}")):
                counter += 1
            dest_path = os.path.join(completed_folder, f"{base}_{counter}{ext}")
        
        shutil.move(file_path, dest_path)
        print(f"Moved to completed: {dest_path}")
        return True
    except Exception as e:
        print(f"Warning: Could not move file to completed: {e}")
        return False
