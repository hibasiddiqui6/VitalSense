from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO

def create_pdf(report_data):
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    width, height = letter

    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, height - 50, "Health Report Summary")

    c.setFont("Helvetica", 12)
    y = height - 100
    for key, value in report_data.items():
        c.drawString(50, y, f"{key.replace('_', ' ').title()}: {value}")
        y -= 20

    c.save()
    buffer.seek(0)
    return buffer
