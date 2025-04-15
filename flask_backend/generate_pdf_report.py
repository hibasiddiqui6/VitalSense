from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO
import datetime
import json

def create_pdf(report_data):
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    width, height = letter

    # HEADER
    c.setFont("Helvetica-Bold", 16)
    c.drawString(400, height - 40, datetime.datetime.now().strftime("%b %d, %Y"))
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
    c.drawString(50, y, f"Session Start: {report_data.get('session_start', '-')}")
    c.drawString(300, y, f"Session End: {report_data.get('session_end', '-')}")

    # VITALS SUMMARY
    y -= 30
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Vitals Summary")
    c.line(50, y - 2, width - 50, y - 2)
    y -= 20

    c.setFont("Helvetica", 11)
    vitals = [
        ("Avg BPM", report_data.get("avg_bpm", "-")),
        ("Avg Temp", report_data.get("avg_temp", "-")),
        ("Avg Resp", report_data.get("avg_resp", "-")),
        ("Temperature Status", report_data.get("temp_status", "-")),
        ("Respiration Status", report_data.get("resp_status", "-")),
        ("ECG Status", report_data.get("ecg_status", "-")),
    ]

    for i in range(0, len(vitals), 2):
        c.drawString(50, y, f"{vitals[i][0]}: {vitals[i][1]}")
        if i + 1 < len(vitals):
            c.drawString(300, y, f"{vitals[i + 1][0]}: {vitals[i + 1][1]}")
        y -= 16

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
            title = details.get("title", "-")
            message = details.get("message", "-")
            c.drawString(50, y, f"{vital.title()} Title: {title}")
            y -= 16
            c.drawString(50, y, f"{vital.title()} Message: {message}")
            y -= 20
    except Exception as e:
        c.drawString(50, y, f"Error parsing recommendations: {str(e)}")
        y -= 20

    c.showPage()
    c.save()
    buffer.seek(0)
    return buffer
