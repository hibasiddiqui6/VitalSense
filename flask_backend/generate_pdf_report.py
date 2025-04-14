from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO
import json

def create_pdf(report_data):
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    width, height = letter

    def draw_heading(text, y_offset):
        c.setFont("Helvetica-Bold", 14)
        c.drawString(50, y_offset, text)
        return y_offset - 20

    def draw_line(label, value, y_offset):
        c.setFont("Helvetica", 12)
        c.drawString(50, y_offset, f"{label}: {value}")
        return y_offset - 16

    y = height - 50
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, y, "Health Report")
    y -= 40

    # Patient Info
    y = draw_heading("Patient Info", y)
    y = draw_line("Full Name", report_data.get("full_name", "-"), y)
    y = draw_line("Age", report_data.get("age", "-"), y)
    y = draw_line("Gender", report_data.get("gender", "-"), y)
    y = draw_line("Weight", report_data.get("weight", "-"), y)

    # Session Info
    y -= 10
    y = draw_heading("Session Info", y)
    y = draw_line("Session Start", report_data.get("session_start", "-"), y)
    y = draw_line("Session End", report_data.get("session_end", "-"), y)

    # Vitals
    y -= 10
    y = draw_heading("Vitals Summary", y)
    y = draw_line("Avg BPM", report_data.get("avg_bpm", "-"), y)
    y = draw_line("Avg Temp", report_data.get("avg_temp", "-"), y)
    y = draw_line("Avg Resp", report_data.get("avg_resp", "-"), y)
    y = draw_line("Temperature Status", report_data.get("temp_status", "-"), y)
    y = draw_line("Respiration Status", report_data.get("resp_status", "-"), y)
    y = draw_line("ECG Status", report_data.get("ecg_status", "-"), y)

    # Severity & Main Recommendation
    y -= 10
    y = draw_heading("Assessment", y)
    y = draw_line("Severity", report_data.get("severity", "-"), y)
    y = draw_line("Primary Recommendation", report_data.get("recommendation", "-"), y)

    # Recommendations by Vital
    y -= 10
    y = draw_heading("Recommendations by Vital", y)

    try:
        recs = report_data.get("recommendations_by_vital", {})
        if isinstance(recs, str):
            recs = json.loads(recs)

        for vital, details in recs.items():
            y = draw_line(f"{vital.title()} Title", details.get("title", "-"), y)
            y = draw_line(f"{vital.title()} Message", details.get("message", "-"), y)
            y -= 10
    except Exception as e:
        y = draw_line("Error parsing recommendations", str(e), y)

    c.save()
    buffer.seek(0)
    return buffer
