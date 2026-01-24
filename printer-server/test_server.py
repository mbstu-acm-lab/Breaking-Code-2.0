#!/usr/bin/env python3
"""
Test script for the automated print server.
Run this before the contest to verify everything works.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# Colors for terminal output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_status(message, status="info"):
    """Print colored status message."""
    if status == "ok":
        print(f"{GREEN}✓{RESET} {message}")
    elif status == "error":
        print(f"{RED}✗{RESET} {message}")
    elif status == "warning":
        print(f"{YELLOW}⚠{RESET} {message}")
    else:
        print(f"{BLUE}ℹ{RESET} {message}")

def check_file_exists(filepath, name):
    """Check if a file exists."""
    if os.path.exists(filepath):
        print_status(f"{name}: Found", "ok")
        return True
    else:
        print_status(f"{name}: NOT FOUND at {filepath}", "error")
        return False

def check_python_package(package_name):
    """Check if a Python package is installed."""
    try:
        __import__(package_name)
        print_status(f"Python package '{package_name}': Installed", "ok")
        return True
    except ImportError:
        print_status(f"Python package '{package_name}': NOT INSTALLED", "error")
        print(f"   Install with: pip install {package_name}")
        return False

def check_seat_plan_csv():
    """Check seat-plan.csv format."""
    csv_path = "seat-plan.csv"
    if not os.path.exists(csv_path):
        print_status("seat-plan.csv not found", "error")
        return False
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            import csv
            reader = csv.DictReader(f)
            rows = list(reader)
            
            if not rows:
                print_status("seat-plan.csv is empty", "error")
                return False
            
            # Check required columns
            required_cols = ['Room', 'Desk No', 'Team Name']
            first_row = rows[0]
            missing = [col for col in required_cols if col not in first_row.keys()]
            
            if missing:
                print_status(f"seat-plan.csv missing columns: {missing}", "error")
                return False
            
            # Count teams
            teams = [row['Team Name'] for row in rows if row.get('Team Name', '').strip()]
            print_status(f"seat-plan.csv: {len(teams)} teams loaded", "ok")
            
            # Show first few teams
            if teams:
                print(f"   Sample teams: {', '.join(teams[:3])}...")
            
            return True
    except Exception as e:
        print_status(f"Error reading seat-plan.csv: {e}", "error")
        return False

def check_windows_printer():
    """Check Windows printer configuration."""
    try:
        import win32print
        
        # Get default printer
        try:
            default = win32print.GetDefaultPrinter()
            print_status(f"Default printer: {default}", "ok")
        except:
            print_status("No default printer configured", "warning")
            default = None
        
        # List all printers
        try:
            flags = win32print.PRINTER_ENUM_LOCAL | win32print.PRINTER_ENUM_CONNECTIONS
            printers = [name for (a, b, name, c) in win32print.EnumPrinters(flags)]
            
            if printers:
                print_status(f"Available printers: {len(printers)}", "ok")
                for p in printers:
                    marker = " (default)" if p == default else ""
                    print(f"   - {p}{marker}")
            else:
                print_status("No printers found", "error")
                return False
                
        except Exception as e:
            print_status(f"Error listing printers: {e}", "error")
            return False
        
        return True
        
    except ImportError:
        print_status("pywin32 not installed (required for Windows printing)", "error")
        print("   Install with: pip install pywin32")
        return False

def check_sumatra_pdf():
    """Check if SumatraPDF is installed."""
    paths = [
        r"C:\Program Files\SumatraPDF\SumatraPDF.exe",
        r"C:\Program Files (x86)\SumatraPDF\SumatraPDF.exe"
    ]
    
    for path in paths:
        if os.path.exists(path):
            print_status(f"SumatraPDF: Found at {path}", "ok")
            return True
    
    print_status("SumatraPDF: Not installed (recommended)", "warning")
    print("   Download: https://www.sumatrapdfreader.org/download-free-pdf-viewer")
    return False

def create_test_files():
    """Create test files for uploading."""
    test_dir = "test_files"
    os.makedirs(test_dir, exist_ok=True)
    
    # Create a test text file
    cpp_file = os.path.join(test_dir, "test_program.cpp")
    with open(cpp_file, 'w') as f:
        f.write("""#include <iostream>
using namespace std;

int main() {
    cout << "Hello from Breaking Code 2.0!" << endl;
    return 0;
}
""")
    
    # Create a test PDF
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.pdfgen import canvas
        
        pdf_file = os.path.join(test_dir, "test_document.pdf")
        c = canvas.Canvas(pdf_file, pagesize=letter)
        c.drawString(100, 750, "Breaking Code 2.0 - Test Document")
        c.drawString(100, 700, "This is a test PDF for the print server.")
        c.save()
        
        print_status(f"Test files created in {test_dir}/", "ok")
        print(f"   - {cpp_file}")
        print(f"   - {pdf_file}")
        return True
    except ImportError:
        print_status("reportlab not available, skipping PDF creation", "warning")
        print(f"   Created: {cpp_file}")
        return True

def main():
    """Run all checks."""
    print("="*60)
    print("Breaking Code 2.0 - Print Server Test")
    print("="*60)
    print()
    
    all_ok = True
    
    # Check Python version
    print("Python Version:")
    print(f"   {sys.version}")
    print()
    
    # Check critical files
    print("Critical Files:")
    all_ok &= check_file_exists("simple.py", "Backup server (simple.py)")
    all_ok &= check_file_exists("automated.py", "Automated server")
    all_ok &= check_seat_plan_csv()
    print()
    
    # Check Python packages
    print("Python Dependencies:")
    all_ok &= check_python_package("flask")
    all_ok &= check_python_package("PyPDF2")
    check_python_package("reportlab")  # Optional but recommended
    print()
    
    # Check directories
    print("Directories:")
    for dir_name in ["templates", "static", "static/css", "static/images"]:
        check_file_exists(dir_name, f"Directory: {dir_name}")
    print()
    
    # Check templates
    print("Templates:")
    check_file_exists("templates/index.html", "Simple upload page")
    check_file_exists("templates/automated_index.html", "Automated upload page")
    check_file_exists("templates/automated_result.html", "Result page")
    check_file_exists("templates/quota_status.html", "Quota page")
    print()
    
    # Check static files
    print("Static Assets:")
    check_file_exists("static/css/style.css", "Stylesheet")
    check_file_exists("static/images/main_logo.png", "Main logo")
    check_file_exists("static/images/mbstu_logo.png", "MBSTU logo")
    check_file_exists("static/images/cse_logo.png", "CSE logo")
    print()
    
    # Platform-specific checks
    import platform
    if platform.system() == 'Windows':
        print("Windows Printing:")
        check_windows_printer()
        check_sumatra_pdf()
        print()
    else:
        print_status("Not running on Windows - printing will be simulated", "warning")
        print()
    
    # Create test files
    print("Test Files:")
    create_test_files()
    print()
    
    # Network info
    print("Network Configuration:")
    try:
        import socket
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
        print_status(f"Hostname: {hostname}", "info")
        print_status(f"IP Address: {ip}", "info")
        print(f"   Server will be accessible at: http://{ip}:8080")
    except:
        pass
    print()
    
    # Final summary
    print("="*60)
    if all_ok:
        print_status("All critical checks passed! ✓", "ok")
        print()
        print("Next steps:")
        print("1. Run: python automated.py")
        print("2. Open browser: http://localhost:8080")
        print("3. Test upload with files from test_files/")
        print("4. Check printer output")
        print("5. Verify quota tracking at /quota")
    else:
        print_status("Some checks failed. Fix errors before starting.", "error")
        print()
        print("Common issues:")
        print("- Missing dependencies: pip install flask PyPDF2 reportlab")
        print("- On Windows: pip install pywin32")
        print("- Missing seat-plan.csv or wrong format")
        print("- No printer configured in Windows")
    print("="*60)

if __name__ == "__main__":
    main()
