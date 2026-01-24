"""
Printing utilities for Windows platform.
"""

import os
import platform
import subprocess

# Windows printing imports
if platform.system() == 'Windows':
    try:
        import win32print
        import win32api
        WINDOWS_PRINTING = True
    except ImportError:
        print("WARNING: pywin32 not installed. Printing will be simulated.")
        WINDOWS_PRINTING = False
else:
    WINDOWS_PRINTING = False


def get_default_printer():
    """Get default printer name."""
    if WINDOWS_PRINTING:
        try:
            return win32print.GetDefaultPrinter()
        except Exception as e:
            print(f"Error getting default printer: {e}")
            return None
    return "Simulated Printer"


def list_available_printers():
    """List all available printers."""
    if not WINDOWS_PRINTING:
        return []
    try:
        printers = []
        flags = win32print.PRINTER_ENUM_LOCAL | win32print.PRINTER_ENUM_CONNECTIONS
        for (a, b, name, c) in win32print.EnumPrinters(flags):
            printers.append(name)
        return printers
    except Exception as e:
        print(f"Error listing printers: {e}")
        return []


def print_pdf_windows(pdf_path, printer_name=None, retry_count=0, print_retries=3, print_timeout=60):
    """Print PDF using Windows printing with retry logic."""
    if not printer_name:
        printer_name = get_default_printer()
    
    if not printer_name:
        # Try to find any available printer
        available_printers = list_available_printers()
        if available_printers:
            printer_name = available_printers[0]
            print(f"No default printer. Using: {printer_name}")
        else:
            raise Exception("No printer available. Please configure a printer in Windows.")
    
    # Verify printer exists
    available_printers = list_available_printers()
    if printer_name not in available_printers:
        print(f"WARNING: Printer '{printer_name}' not found. Available: {available_printers}")
        if available_printers:
            printer_name = available_printers[0]
            print(f"Using alternative printer: {printer_name}")
    
    last_error = None
    
    try:
        # Method 1: Try SumatraPDF if available (most reliable)
        sumatra_paths = [
            r"C:\Program Files\SumatraPDF\SumatraPDF.exe",
            r"C:\Program Files (x86)\SumatraPDF\SumatraPDF.exe"
        ]
        
        for sumatra_path in sumatra_paths:
            if os.path.exists(sumatra_path):
                try:
                    cmd = [sumatra_path, "-print-to", printer_name, "-silent", pdf_path]
                    result = subprocess.run(cmd, check=True, timeout=print_timeout, 
                                          capture_output=True, text=True)
                    print(f"Printed via SumatraPDF: {pdf_path} -> {printer_name}")
                    return True
                except subprocess.TimeoutExpired:
                    last_error = "Print job timed out"
                    print(f"SumatraPDF timeout, trying alternative method...")
                except Exception as e:
                    last_error = str(e)
                    print(f"SumatraPDF failed: {e}, trying alternative method...")
                break
        
        # Method 2: Direct printer API (more reliable than ShellExecute)
        try:
            import time
            hprinter = win32print.OpenPrinter(printer_name)
            try:
                # Start a print job
                hjob = win32print.StartDocPrinter(hprinter, 1, ("Python Print Job", None, "RAW"))
                try:
                    # Read PDF and send to printer
                    with open(pdf_path, 'rb') as f:
                        pdf_data = f.read()
                    win32print.StartPagePrinter(hprinter)
                    win32print.WritePrinter(hprinter, pdf_data)
                    win32print.EndPagePrinter(hprinter)
                    win32print.EndDocPrinter(hprinter)
                    print(f"Printed via Win32 API: {pdf_path} -> {printer_name}")
                    return True
                except Exception as e:
                    win32print.EndDocPrinter(hprinter)
                    raise e
            finally:
                win32print.ClosePrinter(hprinter)
        except Exception as e:
            last_error = str(e)
            print(f"Win32 printing failed: {e}, trying ShellExecute...")
        
        # Method 3: ShellExecute fallback
        try:
            win32api.ShellExecute(
                0,
                "print",
                pdf_path,
                f'/d:"{printer_name}"',
                ".",
                0  # SW_HIDE
            )
            # ShellExecute returns immediately, wait a bit to ensure it started
            import time
            time.sleep(2)
            print(f"Printed via ShellExecute: {pdf_path} -> {printer_name}")
            return True
        except Exception as e:
            last_error = str(e)
            print(f"ShellExecute failed: {e}")
        
        # All methods failed
        raise Exception(f"All printing methods failed. Last error: {last_error}")
        
    except Exception as e:
        # Retry logic
        if retry_count < print_retries - 1:
            print(f"Print attempt {retry_count + 1} failed, retrying...")
            import time
            time.sleep(2)  # Wait before retry
            return print_pdf_windows(pdf_path, printer_name, retry_count + 1, print_retries, print_timeout)
        else:
            print(f"Printing failed after {print_retries} attempts")
            raise Exception(f"Failed to print after {print_retries} attempts: {str(e)}")


def print_pdf_simulated(pdf_path):
    """Simulate printing (for testing on non-Windows)."""
    print(f"[SIMULATED] Would print: {pdf_path}")
    return True


def print_pdf(pdf_path, print_retries=3, print_timeout=60):
    """Print PDF file."""
    if WINDOWS_PRINTING:
        return print_pdf_windows(pdf_path, print_retries=print_retries, print_timeout=print_timeout)
    else:
        return print_pdf_simulated(pdf_path)


def check_sumatra_pdf():
    """Check if SumatraPDF is installed."""
    if platform.system() != 'Windows':
        return None
    
    sumatra_paths = [
        r"C:\Program Files\SumatraPDF\SumatraPDF.exe",
        r"C:\Program Files (x86)\SumatraPDF\SumatraPDF.exe"
    ]
    for path in sumatra_paths:
        if os.path.exists(path):
            return path
    return None
