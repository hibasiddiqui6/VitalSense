import numpy as np
import pywt
import neurokit2 as nk
from vitals_classifier import classify_ecg_bpm
from db_utils import modify_data, fetch_data

# Buffer per shirt
ecg_buffers = {}

# Config
ECG_BUFFER_SIZE = 150
ECG_SAMPLING_RATE = 25

# === Wavelet Denoising ===
def wavelet_denoise(signal, wavelet='db6', level=2):
    coeffs = pywt.wavedec(signal, wavelet, level=level)
    sigma = np.median(np.abs(coeffs[-1])) / 0.6745
    uthresh = sigma * np.sqrt(2 * np.log(len(signal)))
    coeffs[1:] = [pywt.threshold(i, value=uthresh, mode='soft') for i in coeffs[1:]]
    return pywt.waverec(coeffs, wavelet)

def add_ecg_sample(smartshirt_id, raw_ecg_value, hv_id, age, gender):
    if smartshirt_id not in ecg_buffers:
        ecg_buffers[smartshirt_id] = []
    ecg_buffers[smartshirt_id].append(raw_ecg_value)

    if len(ecg_buffers[smartshirt_id]) >= ECG_BUFFER_SIZE:
        process_ecg_buffer(smartshirt_id, hv_id, age, gender)
        ecg_buffers[smartshirt_id].clear()

def process_ecg_buffer(smartshirt_id, hv_id, age, gender):
    try:
        signal = np.array(ecg_buffers[smartshirt_id])
        ecg_mv = (signal - 2048) / 200.0
        ecg_denoised = wavelet_denoise(ecg_mv)

        ecg_cleaned = nk.ecg_clean(ecg_denoised, sampling_rate=ECG_SAMPLING_RATE)
        signals, info = nk.ecg_process(ecg_cleaned, sampling_rate=ECG_SAMPLING_RATE)

        r_peaks = info.get("ECG_R_Peaks", [])
        if len(r_peaks) < 3:
            print("⚠️ Too few R-peaks — skipping ECG segment analysis")
            return

        # HR & HRV
        hr = round(np.mean(signals["ECG_Rate"]), 1)
        hrv = round(nk.hrv_time(signals, sampling_rate=ECG_SAMPLING_RATE)["HRV_MeanNN"][0], 1)
        rr = round(np.mean(np.diff(r_peaks)) / ECG_SAMPLING_RATE * 1000, 1)

        # === Duration Extractor ===
        def duration_ms(start_key, end_key):
            start = info.get(start_key)
            end = info.get(end_key)
            if isinstance(start, (list, np.ndarray)) and isinstance(end, (list, np.ndarray)):
                durations = [(e - s) for s, e in zip(start, end) if e > s]
                return round(np.mean(durations) * 1000 / ECG_SAMPLING_RATE, 1) if durations else "-"
            return "-"

        # ECG Durations
        pr = duration_ms("ECG_P_Onsets", "ECG_R_Onsets")
        p_dur = duration_ms("ECG_P_Onsets", "ECG_P_Offsets")
        qrs = duration_ms("ECG_R_Onsets", "ECG_R_Offsets")
        qt = duration_ms("ECG_Q_Peaks", "ECG_T_Offsets")

        # QTc (Bazett's)
        try:
            rr_sec = rr / 1000
            qtc = round(qt / (rr_sec ** 0.5), 1) if qt != "-" and rr_sec > 0 else "-"
        except Exception:
            qtc = "-"

        # Classification
        bpm = hr
        classification = classify_ecg_bpm(bpm, age, gender)
        status = classification['status']
        disease = classification['disease']

        print(f"📊 ECG Classify | BPM={bpm} | Age={age} | Gender={gender} → {status}")

        if not fetch_data("SELECT 1 FROM health_vitals WHERE id = %s", (hv_id,)):
            print(f"❌ health_vitals ID {hv_id} not found in DB.")
            return

        insert_query = """
            INSERT INTO ecg (
                healthvitalsid, bpm, ecgstatus, detecteddisease,
                hrv, rr, pr, p, qrs, qt, qtc
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        modify_data(insert_query, (
            hv_id, str(bpm), status, disease,
            str(hrv), str(rr), str(pr), str(p_dur), str(qrs), str(qt), str(qtc)
        ))

        print(f"✅ ECG saved | BPM={bpm}, HRV={hrv}, RR={rr}, PR={pr}, P={p_dur}, QRS={qrs}, QT={qt}, QTc={qtc}")

    except Exception as e:
        print(f"❌ ECG processing failed: {e}")
