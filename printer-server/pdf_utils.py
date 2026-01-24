"""
PDF processing utilities for the print server.
"""

import os
from PyPDF2 import PdfReader
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER


def count_pdf_pages(pdf_path):
    """Count pages in PDF file."""
    try:
        reader = PdfReader(pdf_path)
        return len(reader.pages)
    except Exception as e:
        print(f"Error counting PDF pages: {e}")
        raise ValueError(f"Invalid PDF file: {str(e)}")


def validate_pdf(file_path):
    """Validate PDF file."""
    try:
        reader = PdfReader(file_path)
        # Try to access first page to ensure it's readable
        if len(reader.pages) > 0:
            _ = reader.pages[0]
        return True
    except Exception as e:
        print(f"PDF validation failed: {e}")
        return False


def text_to_pdf_with_header(text_path, output_pdf, team_info):
    """Convert text/code file to PDF with team header."""
    try:
        # Read the text file with multiple encoding fallbacks
        content = None
        encodings = ['utf-8', 'latin-1', 'cp1252', 'iso-8859-1']
        for encoding in encodings:
            try:
                with open(text_path, 'r', encoding=encoding) as f:
                    content = f.read()
                break
            except UnicodeDecodeError:
                continue
        
        if content is None:
            # Last resort: read as binary and ignore errors
            with open(text_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        
        # Limit content size to prevent memory issues
        max_chars = 100000  # ~100KB of text
        if len(content) > max_chars:
            content = content[:max_chars] + "\n\n[Content truncated - file too large]\n"
        
        # Create PDF
        doc = SimpleDocTemplate(output_pdf, pagesize=letter)
        story = []
        styles = getSampleStyleSheet()
        
        # Header style
        header_style = ParagraphStyle(
            'CustomHeader',
            parent=styles['Heading1'],
            fontSize=12,
            textColor='black',
            spaceAfter=6,
            alignment=TA_CENTER,
            borderWidth=2,
            borderColor='black',
            borderPadding=10,
            backColor='lightgrey'
        )
        
        # Create header text
        header_text = f"<b>Breaking Code 2.0</b><br/>"
        if team_info['room']:
            header_text += f"Room: {team_info['room']} | "
        if team_info['desk']:
            header_text += f"Desk: {team_info['desk']} | "
        header_text += f"Team: {team_info['team']}"
        
        story.append(Paragraph(header_text, header_style))
        story.append(Spacer(1, 0.2*inch))
        
        # File name
        filename_style = ParagraphStyle(
            'Filename',
            parent=styles['Normal'],
            fontSize=10,
            textColor='darkblue'
        )
        story.append(Paragraph(f"<b>File:</b> {os.path.basename(text_path)}", filename_style))
        story.append(Spacer(1, 0.15*inch))
        
        # Content style (code formatting)
        code_style = ParagraphStyle(
            'Code',
            parent=styles['Code'],
            fontSize=8,
            fontName='Courier',
            leftIndent=20,
            rightIndent=20
        )
        
        # Add content as preformatted text
        story.append(Preformatted(content, code_style))
        
        # Build PDF
        doc.build(story)
        return True
        
    except Exception as e:
        print(f"Error converting text to PDF: {e}")
        raise Exception(f"Failed to convert text file: {str(e)}")
