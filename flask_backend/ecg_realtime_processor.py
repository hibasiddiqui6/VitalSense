import numpy as np
import pywt
import neurokit2 as nk
from vitals_classifier import classify_ecg_bpm
from db_utils import modify_data

# Buffer per shirt
ecg_buffers = {}

# Config
ECG_BUFFER_SIZE = 1710
ECG_SAMPLING_RATE = 35

# === Wavelet Denoising ===
def wavelet_denoise(signal, wavelet='db6', level=2):
    coeffs = pywt.wavedec(signal, wavelet, level=level)
    sigma = np.median(np.abs(coeffs[-1])) / 0.6745
    uthresh = sigma * np.sqrt(2 * np.log(len(signal)))
    coeffs[1:] = [pywt.threshold(i, value=uthresh, mode='soft') for i in coeffs[1:]]
    return pywt.waverec(coeffs, wavelet)

def process_ecg_batch(batch):
    """
    Expects batch as a list of dictionaries:
    [
        {
            "smartshirt_id": "123",
            "age": 22,
            "gender": "Female",
            "ecg_values": [2048, 2049, ..., 2050]  # length must be >= ECG_BUFFER_SIZE
        },
        ...
    ]
    """
    for entry in batch:
        try:
            # Log the entry being processed
            print(f"🔍 Processing batch item: {entry}")
            
            smartshirt_id = entry["smartshirt_id"]
            age = entry["age"]
            gender = entry["gender"]
            ecg_values = entry["ecg_values"]

            # Log the size of ECG values before processing
            print(f"📏 ECG values size for smartshirt {smartshirt_id}: {len(ecg_values)}")

            if len(ecg_values) < ECG_BUFFER_SIZE:
                print(f"⚠️ ECG batch too small for {smartshirt_id} (got {len(ecg_values)}) — skipping")
                continue

            # Store to buffer (optional if needed later)
            ecg_buffers[smartshirt_id] = ecg_values[:ECG_BUFFER_SIZE]

            # Log the buffer size
            print(f"✅ ECG buffer for smartshirt {smartshirt_id} stored with size {len(ecg_buffers[smartshirt_id])}")

            # Process this buffer
            process_ecg_buffer(smartshirt_id, age, gender)

        except Exception as e:
            print(f"❌ Failed to process batch item for smartshirt_id {entry['smartshirt_id']}: {e}")

def process_ecg_buffer(smartshirt_id, age, gender):
    try:
        print(f"[PROCESS] Running ECG classification for {smartshirt_id}")
        
        signal = np.array(ecg_buffers[smartshirt_id])
        ecg_mv = (signal - 2048) / 200.0
        print(f"Converted mV range: min={ecg_mv.min():.3f}, max={ecg_mv.max():.3f}")

        ecg_denoised = wavelet_denoise(ecg_mv)
        # print(f"🔧 Denoised ECG shape: {ecg_denoised.shape}")

        # # Ensure fixed length
        # if len(ecg_denoised) > ECG_BUFFER_SIZE:
        #     ecg_denoised = ecg_denoised[:ECG_BUFFER_SIZE]
        # elif len(ecg_denoised) < ECG_BUFFER_SIZE:
        #     ecg_denoised = np.pad(ecg_denoised, (0, ECG_BUFFER_SIZE - len(ecg_denoised)), mode='edge')

        print(f"🔁 Resized ECG length: {len(ecg_denoised)}")

        ecg_cleaned = nk.ecg_clean(ecg_denoised, sampling_rate=ECG_SAMPLING_RATE)

        # Basic stats
        print("📏 ECG cleaned min:", np.min(ecg_cleaned))
        print("📏 ECG cleaned max:", np.max(ecg_cleaned))
        print("📏 ECG cleaned mean:", np.mean(ecg_cleaned))
        print("📏 ECG cleaned std:", np.std(ecg_cleaned))
        print("📏 ECG cleaned shape:", ecg_cleaned.shape)

        # Try manual peak detection
        _, info_temp = nk.ecg_peaks(ecg_cleaned, sampling_rate=ECG_SAMPLING_RATE)
        r_peaks_pre = info_temp.get("ECG_R_Peaks", [])
        print(f"🔍 Detected R-peaks before ecg_process: {len(r_peaks_pre)} → {r_peaks_pre[:10]}")

        signals, info = nk.ecg_process(ecg_cleaned, sampling_rate=ECG_SAMPLING_RATE)
        print("signals", signals)

        print(f"📦 neurokit2 info keys: {list(info.keys())}")
        print(f"🔎 Detected R-peaks: {len(info.get('ECG_R_Peaks', []))}")
        print(f"📊 ECG_Rate preview: {signals['ECG_Rate'].head()}")

        r_peaks = info.get("ECG_R_Peaks", [])
        print(f"🔎 Detected R-peaks: {len(r_peaks)}")

        if len(r_peaks) < 2:
            print("⚠️ Too few R-peaks — skipping ECG segment analysis")
            return

        # HR & HRV
        # hr_raw = np.mean(signals["ECG_Rate"])
        # hr = round(hr_raw, 1) if not np.isnan(hr_raw) else "-"
        # hrv_raw = nk.hrv_time(signals, sampling_rate=ECG_SAMPLING_RATE)["HRV_MeanNN"][0]
        # hrv = round(hrv_raw, 1) if not np.isnan(hrv_raw) else "-"
        # rr_raw = np.mean(np.diff(r_peaks)) / ECG_SAMPLING_RATE * 1000
        # rr = round(rr_raw, 1) if not np.isnan(rr_raw) else "-"

        hr = round(np.mean(signals["ECG_Rate"]), 1)
        hrv = round(nk.hrv_time(signals, sampling_rate=ECG_SAMPLING_RATE)["HRV_MeanNN"][0], 1)
        rr = round(np.mean(np.diff(r_peaks)) / ECG_SAMPLING_RATE * 1000, 1)

        if hr == "-":
            print("⚠️ Invalid HR (NaN) — skipping classification.")
            return
        
        # === Duration Extractor ===
        def duration_ms(start_key, end_key):
            start = info.get(start_key)
            end = info.get(end_key)
            if isinstance(start, (list, np.ndarray)) and isinstance(end, (list, np.ndarray)):
                pairs = zip(start, end)
                durations = [(e - s) for s, e in pairs if e > s]
                return round(np.mean(durations) * 1000 / ECG_SAMPLING_RATE, 1) if durations else "nan"
            return "nan"

        # ECG Durations
        pr = duration_ms("ECG_P_Onsets", "ECG_R_Onsets")
        p_dur = duration_ms("ECG_P_Onsets", "ECG_P_Offsets")
        qrs = duration_ms("ECG_R_Onsets", "ECG_R_Offsets")
        qrs_dur = duration_ms("ECG_R_Onsets", "ECG_R_Offsets")
        qt = duration_ms("ECG_Q_Peaks", "ECG_T_Offsets")
        qt_int = duration_ms("ECG_Q_Peaks", "ECG_T_Offsets")
        pr_int = duration_ms("ECG_P_Onsets", "ECG_R_Onsets")

         # QTc (Bazett)
        try:
            rr_sec = rr / 1000
            qtc = round(qt_int / (rr_sec ** 0.5), 1) if qt_int != "nan" and rr_sec > 0 else "nan"
        except:
            print(f"⚠️ QTc calculation failed: {ex}")
            qtc = "nan"


        print("📈 ECG Metrics:")
        print(f"   HR (BPM): {hr}")
        print(f"   HRV MeanNN: {hrv}")
        print(f"   RR Interval: {rr} ms")
        print(f"   PR Interval: {pr_int} ms")
        print(f"   P Duration: {p_dur} ms")
        print(f"   QRS Duration: {qrs_dur} ms")
        print(f"   QT Interval: {qt_int} ms")
        print(f"   QTc (Bazett): {qtc} ms")

        # HR from peaks
        rr_intervals = np.diff(r_peaks) / ECG_SAMPLING_RATE
        bpm_rr = round(60 / np.mean(rr_intervals), 1)
        bpm_count = round(60 * len(r_peaks) / (len(ecg_denoised) / ECG_SAMPLING_RATE), 1)

        print(f"📊 R-peaks: {len(r_peaks)} | Duration: {len(ecg_denoised)/ECG_SAMPLING_RATE:.2f}s")
        print(f"✅ BPM (RR method): {bpm_rr} | BPM (count-based): {bpm_count}")

        # Classification
        bpm = hr
        classification = classify_ecg_bpm(bpm, age, gender)
        status = classification['status']
        disease = classification['disease']

        print(f"📊 ECG Classify | BPM={bpm} | Age={age} | Gender={gender} → {status}")
        
        def safe_str(value):
            return str(value) if value != "-" else None

        insert_query = """
            INSERT INTO ecg (
                smartshirtid, bpm, ecgstatus, detecteddisease,
                hrv, rr, pr, p, qrs, qt, qtc
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        modify_data(insert_query, (
            smartshirt_id,
            safe_str(hr), status, disease,
            safe_str(hrv), safe_str(rr), safe_str(pr),
            safe_str(p_dur), safe_str(qrs), safe_str(qt), safe_str(qtc)
        ))

        print(f"✅ ECG saved | BPM={bpm}, HRV={hrv}, RR={rr}, PR={pr}, P={p_dur}, QRS={qrs}, QT={qt}, QTc={qtc}")

    except Exception as e:
        print(f"❌ ECG processing failed: {e}")
