from flask import Flask, request, render_template_string
import os
from datetime import datetime

# --- Configuration ---
UPLOAD_DIR = "C:\\ContestSubmissions"  # Change if needed
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__)

# Simple HTML upload page
HTML_PAGE = """
<!doctype html>
<title>Contest File Upload</title>
<h2>Upload yourfile</h2>
<form method=post enctype=multipart/form-data>
  Team Name: <input type=text name=team required><br><br>
  File: <input type=file name=file required><br><br>
  <input type=submit value=Upload>
</form>
"""

@app.route("/", methods=["GET", "POST"])
def upload_file():
    if request.method == "POST":
        file = request.files.get("file")
        team = request.form.get("team").strip()
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
        return f"Uploaded successfully: {safe_filename}"

    return render_template_string(HTML_PAGE)

if __name__ == "__main__":
    # Server accessible on all LAN IPs
    app.run(host="0.0.0.0", port=8080)
