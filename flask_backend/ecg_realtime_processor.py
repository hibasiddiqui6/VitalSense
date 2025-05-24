import numpy as np
from vitals_classifier import classify_ecg_bpm
from db_utils import modify_data
import numpy as np
from scipy.signal import find_peaks
from datetime import datetime
from pytz import timezone

ECG_SAMPLING_RATE = 12.5  # Hz

# Get current time in Pakistan timezone
pkt = timezone("Asia/Karachi")
current_time = datetime.now(pkt)

def process_ecg_batch(batch_data):
    for item in batch_data:
        ecg_values = item.get("ecg_values", [])
        smartshirt_id = item.get("smartshirt_id")
        age = item.get("age")
        gender = item.get("gender")

        if len(ecg_values) < 2:
            print(f"❌ Not enough ECG values for ID {smartshirt_id}")
            continue

        bpm = calculate_bpm(ecg_values)
        if bpm is not None:
            classification = classify_ecg_bpm(bpm, age, gender)
            status = classification['status']
            disease = classification['disease']

            print(f"✅ SmartShirt ID: {smartshirt_id} | BPM: {bpm} | Status: {status} | Disease: {disease}")

            # Insert into ecg table
            query = """
                INSERT INTO ecg (smartshirtID, bpm, ecgstatus, detecteddisease, timestamp)
                VALUES (%s, %s, %s, %s, %s);
            """
            values = (smartshirt_id, str(bpm), status, disease, current_time)
            modify_data(query, values)

        else:
            print(f"❌ Failed to calculate BPM for ID {smartshirt_id}")

def calculate_bpm(ecg_signal):
    # Normalize (assuming signal is in raw ADC units centered at 2048)
    ecg_mv = (np.array(ecg_signal) - 2048) / 200.0

    # For now: basic peak detection
    peaks, _ = find_peaks(ecg_mv, distance=ECG_SAMPLING_RATE * 0.6)  # ~min 60 BPM

    if len(peaks) < 2:
        print("⚠️ Not enough R-peaks")
        return None

    rr_intervals = np.diff(peaks) / ECG_SAMPLING_RATE  # in seconds
    bpm = round(60 / np.mean(rr_intervals), 1)

    print(f"📊 R-peaks: {len(peaks)} | BPM: {bpm}")
    return bpm
