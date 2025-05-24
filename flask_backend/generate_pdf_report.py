from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO
import json
from datetime import datetime

def create_pdf(report_data):
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    width, height = letter

    # HEADER
    c.setFont("Helvetica-Bold", 16)
    c.drawString(450, height - 40, datetime.now().strftime("%b %d, %Y"))
    c.setFont("Helvetica-Bold", 18)
    c.drawString(50, height - 80, "Patient Health Audit Report")

    # GENERAL INFO
    y = height - 120
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "General Information")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)
    c.drawString(50, y, f"Full Name: {report_data.get('full_name', '-')}")
    c.drawString(300, y, f"Age: {report_data.get('age', '-')}")
    y -= 16
    c.drawString(50, y, f"Gender: {report_data.get('gender', '-')}")
    c.drawString(300, y, f"Weight: {report_data.get('weight', '-')}")

    # SESSION INFO
    y -= 30
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Session Information")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)

    # Session info formatting
    c.drawString(50, y, f"Session Start: {format_datetime(report_data.get('session_start', '-'))}")
    c.drawString(300, y, f"Session End: {format_datetime(report_data.get('session_end', '-'))}")

    # VITALS SUMMARY
    y -= 30
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Vitals Summary")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)
    # Left column: actual values
    c.drawString(50, y, f"Average BPM(Beats per minute): {report_data.get('avg_bpm', '-')}")
    y -= 16
    c.drawString(50, y, f"Average Respiration: {report_data.get('avg_resp', '-')}")
    y -= 16
    c.drawString(50, y, f"Average Temperature: {report_data.get('avg_temp', '-')}")

    # Reset y for right column
    y = y + 32  # move back up to align
    c.drawString(300, y, f"ECG Status: {report_data.get('ecg_status', '-')}")
    y -= 16
    c.drawString(300, y, f"Respiration Status: {report_data.get('resp_status', '-')}")
    y -= 16
    c.drawString(300, y, f"Temperature Status: {report_data.get('temp_status', '-')}")

    # ASSESSMENT
    y -= 30
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Assessment")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)
    c.drawString(50, y, f"Severity: {report_data.get('severity', '-')}")
    c.drawString(300, y, f"Primary Recommendation: {report_data.get('recommendation', '-')}")

    # RECOMMENDATIONS
    y -= 30
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Recommendations by Vital")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)
    try:
        recs = report_data.get("recommendations_by_vital", {})
        if isinstance(recs, str):
            recs = json.loads(recs)

        for vital, details in recs.items():
            findings = details.get("title", "-") 
            recommendation = details.get("message", "-")  
            
            # Modify the text to make it more user-friendly
            c.drawString(50, y, f"{vital.title()} Findings: {findings}")
            y -= 16
            c.drawString(50, y, f"{vital.title()} Recommendation: {recommendation}")
            y -= 20
    except Exception as e:
        c.drawString(50, y, f"Error parsing recommendations: {str(e)}")
        y -= 20

    c.showPage()
    c.save()
    buffer.seek(0)
    return buffer

# Function to format datetime strings for user readability
def format_datetime(dt):
    try:
        if isinstance(dt, str):  # If dt is a string
            dt = datetime.fromisoformat(dt)  # Convert string to datetime object
        elif not isinstance(dt, datetime):  # If dt is neither string nor datetime
            return "-"
        return dt.strftime("%b %d, %Y %H:%M:%S")  # Format as 'Apr 13, 2025 23:32:30'
    except ValueError:
        return "-"