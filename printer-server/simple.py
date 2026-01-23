from flask import Flask, request, render_template
import os
from datetime import datetime
import csv

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(SCRIPT_DIR, "uploads")
SEAT_PLAN_FILE = os.path.join(SCRIPT_DIR, "seat-plan.csv")

os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__)

# Load team names from CSV
def load_teams():
    teams = []
    if os.path.exists(SEAT_PLAN_FILE):
        with open(SEAT_PLAN_FILE, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                team_info = f"{row['Team Name']} (Room: {row['Room']}, Desk: {row['Desk No']})"
                teams.append((row['Team Name'], team_info))
    return teams

TEAMS = load_teams()

@app.route("/", methods=["GET", "POST"])
def upload_file():
    if request.method == "POST":
        file = request.files.get("file")
        team = request.form.get("team") or request.form.get("team_custom")
        
        if team:
            team = team.strip()
        
        if not file or not team:
            return "Missing team name or file", 400

        # Create team folder
        team_folder = os.path.join(UPLOAD_DIR, team)
        os.makedirs(team_folder, exist_ok=True)

        # Save file with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{file.filename}"
        save_path = os.path.join(team_folder, safe_filename)
        file.save(save_path)

        print(f"Received file from {team}: {save_path}")
        return render_template("success.html", filename=safe_filename, team=team)

    return render_template("index.html", teams=TEAMS)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
