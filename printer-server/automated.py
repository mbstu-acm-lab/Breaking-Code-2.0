from flask import Flask, request, render_template, redirect, url_for
import os
import platform
from datetime import datetime

# Import utility modules
from utils import load_teams, get_team_info, move_to_completed
from quota_manager import load_quota, get_team_quota, update_team_quota, reset_team_quota
from pdf_utils import count_pdf_pages, validate_pdf, text_to_pdf_with_header
from print_utils import print_pdf, get_default_printer, list_available_printers, check_sumatra_pdf, WINDOWS_PRINTING

# Check for reportlab
try:
    import reportlab
    REPORTLAB_AVAILABLE = True
except ImportError:
    print("WARNING: reportlab not installed. Text file printing will be disabled.")
    print("Install with: pip install reportlab")
    REPORTLAB_AVAILABLE = False

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(SCRIPT_DIR, "uploads")
QUOTA_FILE = os.path.join(SCRIPT_DIR, "quota.json")
SEAT_PLAN_CSV = os.path.join(SCRIPT_DIR, "seat-plan.csv")
MAX_PAGES = 50  # Maximum pages per team
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
PRINT_RETRIES = 3  # Number of print attempts
PRINT_TIMEOUT = 60  # Seconds to wait for print job

os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# --- Routes ---
@app.route("/", methods=["GET", "POST"])
def upload_file():
    teams = load_teams(SEAT_PLAN_CSV)
    
    if request.method == "POST":
        try:
            # Get form data
            team = request.form.get("team", "").strip()
            file = request.files.get("file")
            
            # Validation
            if not team:
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="Team name is required")
            
            if not file or file.filename == '':
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="No file selected")
            
            if team not in teams:
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="Invalid team name")
            
            # Get team info
            team_info = get_team_info(team, SEAT_PLAN_CSV)
            
            # Check file extension - support PDF, txt, and code files
            filename_lower = file.filename.lower()
            allowed_extensions = ['.pdf', '.txt', '.cpp', '.c', '.java', '.py', '.js', '.cs', '.h', '.hpp']
            is_text_file = any(filename_lower.endswith(ext) for ext in allowed_extensions if ext != '.pdf')
            is_pdf = filename_lower.endswith('.pdf')
            
            if not (is_pdf or is_text_file):
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="Only PDF, TXT, and code files (.cpp, .c, .java, .py, etc.) are allowed")
            
            # For text files, check if reportlab is available
            if is_text_file and not REPORTLAB_AVAILABLE:
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="Text file printing is not available. Please convert to PDF first or contact organizers.")
            
            # Create team folder
            team_folder = os.path.join(UPLOAD_DIR, team)
            os.makedirs(team_folder, exist_ok=True)
            
            # Save file with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            safe_filename = f"{timestamp}_{file.filename}"
            file_path = os.path.join(team_folder, safe_filename)
            file.save(file_path)
            
            print(f"Received file from {team}: {file_path}")
            
            # Process based on file type
            pdf_to_print = file_path
            
            if is_text_file:
                # Convert text file to PDF with header
                print(f"Converting text file to PDF with team header...")
                pdf_path = file_path + ".pdf"
                try:
                    text_to_pdf_with_header(file_path, pdf_path, team_info)
                    pdf_to_print = pdf_path
                    print(f"Created PDF: {pdf_path}")
                except Exception as e:
                    os.remove(file_path)
                    return render_template("automated_result.html", 
                                         success=False, 
                                         error=f"Failed to process text file: {str(e)}")
            else:
                # Validate PDF
                if not validate_pdf(file_path):
                    os.remove(file_path)
                    return render_template("automated_result.html", 
                                         success=False, 
                                         error="Invalid or corrupted PDF file")
            
            # Count pages
            try:
                pages = count_pdf_pages(pdf_to_print)
            except ValueError as e:
                os.remove(file_path)
                if is_text_file and os.path.exists(pdf_to_print):
                    os.remove(pdf_to_print)
                return render_template("automated_result.html", 
                                     success=False, 
                                     error=str(e))
            
            if pages == 0:
                os.remove(file_path)
                if is_text_file and os.path.exists(pdf_to_print):
                    os.remove(pdf_to_print)
                return render_template("automated_result.html", 
                                     success=False, 
                                     error="File has no pages")
            
            # Check quota
            current_quota = get_team_quota(team, QUOTA_FILE)
            if current_quota + pages > MAX_PAGES:
                os.remove(file_path)
                if is_text_file and os.path.exists(pdf_to_print):
                    os.remove(pdf_to_print)
                return render_template("automated_result.html", 
                                     success=False, 
                                     error=f"Quota exceeded. You have used {current_quota}/{MAX_PAGES} pages. This file has {pages} pages.",
                                     quota_info={
                                         "used": current_quota,
                                         "max": MAX_PAGES,
                                         "remaining": MAX_PAGES - current_quota
                                     })
            
            # Print the PDF
            print_success = False
            print_error = None
            try:
                print_pdf(pdf_to_print, PRINT_RETRIES, PRINT_TIMEOUT)
                print_success = True
            except Exception as e:
                print_error = str(e)
                print(f"PRINTING FAILED: {print_error}")
                # Don't delete files on print failure - keep for manual printing
                # Still update quota to prevent abuse
                new_quota = update_team_quota(team, pages, QUOTA_FILE)
                
                return render_template("automated_result.html", 
                                     success=False, 
                                     error=f"Printing failed: {print_error}. File has been saved and will be printed manually by organizers. Your quota has been updated.",
                                     quota_info={
                                         "used": new_quota,
                                         "max": MAX_PAGES,
                                         "remaining": MAX_PAGES - new_quota
                                     },
                                     team=team,
                                     team_info=team_info,
                                     filename=file.filename,
                                     pages=pages)
            
            # Update quota only after successful print
            new_quota = update_team_quota(team, pages, QUOTA_FILE)
            
            # Move files to completed directory
            move_to_completed(file_path, team, UPLOAD_DIR)
            if is_text_file and os.path.exists(pdf_to_print) and pdf_to_print != file_path:
                move_to_completed(pdf_to_print, team, UPLOAD_DIR)
            
            print(f"Successfully printed {pages} pages for {team} ({team_info['room']}, Desk {team_info['desk']}). Total: {new_quota}/{MAX_PAGES}")
            
            return render_template("automated_result.html", 
                                 success=True, 
                                 team=team,
                                 team_info=team_info,
                                 filename=file.filename,
                                 pages=pages,
                                 quota_info={
                                     "used": new_quota,
                                     "max": MAX_PAGES,
                                     "remaining": MAX_PAGES - new_quota
                                 })
        
        except Exception as e:
            print(f"Error processing upload: {e}")
            import traceback
            traceback.print_exc()
            return render_template("automated_result.html", 
                                 success=False, 
                                 error=f"Server error: {str(e)}. Please try again or contact organizers.")
    
    # GET request - show upload form
    return render_template("automated_index.html", teams=teams, max_pages=MAX_PAGES)

@app.route("/quota")
def show_quota():
    """Show quota status for all teams."""
    quota = load_quota(QUOTA_FILE)
    teams = load_teams(SEAT_PLAN_CSV)
    
    quota_info = []
    for team in teams:
        used = quota.get(team, 0)
        quota_info.append({
            "team": team,
            "used": used,
            "remaining": MAX_PAGES - used,
            "percentage": (used / MAX_PAGES * 100) if MAX_PAGES > 0 else 0
        })
    
    return render_template("quota_status.html", 
                         quota_info=quota_info, 
                         max_pages=MAX_PAGES)

@app.route("/reset-quota/<team>")
def reset_quota_route(team):
    """Reset quota for a specific team (admin function)."""
    reset_team_quota(team, QUOTA_FILE)
    print(f"Reset quota for team: {team}")
    return redirect(url_for('show_quota'))

@app.route("/printer-status")
def printer_status():
    """Check printer status and configuration."""
    status = {
        "platform": platform.system(),
        "windows_printing": WINDOWS_PRINTING,
        "reportlab_available": REPORTLAB_AVAILABLE,
        "default_printer": None,
        "available_printers": [],
        "sumatra_pdf": False
    }
    
    if WINDOWS_PRINTING:
        status["default_printer"] = get_default_printer()
        status["available_printers"] = list_available_printers()
        status["sumatra_pdf"] = check_sumatra_pdf()
    
    return status

@app.route("/health")
def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "teams_loaded": len(load_teams(SEAT_PLAN_CSV)),
        "printer_available": WINDOWS_PRINTING or True  # True for simulation mode
    }

if __name__ == "__main__":
    print("="*60)
    print("Breaking Code 2.0 - Automated Print Server")
    print("="*60)
    print(f"Upload directory: {UPLOAD_DIR}")
    print(f"Quota file: {QUOTA_FILE}")
    print(f"Seat plan: {SEAT_PLAN_CSV}")
    print(f"Max pages per team: {MAX_PAGES}")
    print(f"Max file size: {MAX_FILE_SIZE / (1024*1024):.1f} MB")
    print(f"Print retries: {PRINT_RETRIES}")
    print(f"Print timeout: {PRINT_TIMEOUT}s")
    print()
    
    # Check critical files
    if not os.path.exists(SEAT_PLAN_CSV):
        print(f"ERROR: Seat plan not found: {SEAT_PLAN_CSV}")
        print("Please create seat-plan.csv with columns: Room, Desk No, Team Name")
        exit(1)
    
    teams = load_teams(SEAT_PLAN_CSV)
    if not teams:
        print(f"WARNING: No teams loaded from {SEAT_PLAN_CSV}")
        print("Please check the CSV file format.")
    else:
        print(f"Teams loaded: {len(teams)}")
    
    print()
    print("Printing Configuration:")
    print("-" * 40)
    
    if WINDOWS_PRINTING:
        default_printer = get_default_printer()
        available_printers = list_available_printers()
        
        if default_printer:
            print(f"Default printer: {default_printer}")
        else:
            print("WARNING: No default printer set!")
        
        if available_printers:
            print(f"Available printers ({len(available_printers)}):")
            for p in available_printers:
                marker = " (default)" if p == default_printer else ""
                print(f"  - {p}{marker}")
        else:
            print("WARNING: No printers found!")
            print("Please install and configure a printer in Windows.")
        
        # Check for SumatraPDF
        sumatra_path = check_sumatra_pdf()
        if sumatra_path:
            print(f"SumatraPDF: Found at {sumatra_path}")
        else:
            print("SumatraPDF: Not installed (optional, but recommended)")
            print("  Download: https://www.sumatrapdfreader.org/download-free-pdf-viewer")
    else:
        print("Printing: SIMULATED (not on Windows or pywin32 not installed)")
        print("Files will be saved but not actually printed.")
    
    if not REPORTLAB_AVAILABLE:
        print("\nWARNING: reportlab not installed!")
        print("Text file printing will not work.")
        print("Install with: pip install reportlab")
    
    print()
    print("="*60)
    print("\nServer starting on http://0.0.0.0:8080")
    print("Access from any device on the network")
    print("\nEndpoints:")
    print("  /          - Upload page")
    print("  /quota     - Quota status")
    print("  /printer-status - Printer configuration")
    print("  /health    - Health check")
    print("="*60)
    print("\nPress Ctrl+C to stop the server")
    print()
    
    try:
        app.run(host="0.0.0.0", port=8080, debug=False)
    except KeyboardInterrupt:
        print("\n\nServer stopped by user")
    except Exception as e:
        print(f"\n\nServer error: {e}")
        import traceback
        traceback.print_exc()
