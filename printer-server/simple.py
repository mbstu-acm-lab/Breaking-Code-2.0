from flask import Flask, request, render_template
import os
from datetime import datetime

# Import utility modules
from utils import load_teams, load_team_details

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(SCRIPT_DIR, "uploads")
SEAT_PLAN_FILE = os.path.join(SCRIPT_DIR, "seat-plan.csv")

os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__)

# Load team names and info from CSV
TEAMS = load_teams(SEAT_PLAN_FILE)
TEAM_DETAILS = load_team_details(SEAT_PLAN_FILE)

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

        # Get team details if available
        room_desk_info = ""
        if team in TEAM_DETAILS:
            room = TEAM_DETAILS[team]['room']
            desk = TEAM_DETAILS[team]['desk']
            room_desk_info = f"_R{room}_D{desk}"
        
        # Save file with timestamp and room/desk info
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}{room_desk_info}_{file.filename}"
        save_path = os.path.join(team_folder, safe_filename)
        file.save(save_path)

        print(f"Received file from {team} (Room: {TEAM_DETAILS.get(team, {}).get('room', 'N/A')}, Desk: {TEAM_DETAILS.get(team, {}).get('desk', 'N/A')}): {save_path}")
        return render_template("success.html", filename=safe_filename, team=team)

    return render_template("index.html", teams=TEAMS)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
