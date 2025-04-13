def classify_temp(tempF, age, gender):
    """
    Classify temperature based on age and gender.
    """
    if tempF == -100.0:
        return {"status": "Sensor Disconnected", "disease": None}

    # Adjust baseline ranges
    if age >= 60:
        normal_low, normal_high = 96.0, 98.5
    else:
        if gender == "Female":
            normal_low, normal_high = 97.2, 99.2
        else:
            normal_low, normal_high = 96.8, 98.8

    # Classification logic
    if tempF < 95.0:
        return {"status": "Low", "disease": "Hypothermia"}
    elif tempF < normal_low:
        return {"status": "Below Normal", "disease": None}
    elif tempF <= normal_high:
        return {"status": "Normal", "disease": None}
    elif tempF <= 100.4:
        return {"status": "Elevated", "disease": None}
    elif tempF <= 104.0:
        return {"status": "High", "disease": "Fever"}
    elif tempF <= 107.0:
        return {"status": "Very High", "disease": "Hyperthermia"}
    else:
        return {"status": "Critical", "disease": "Hyperpyrexia"}

def classify_respiration(resp, age):
    """
    Classify respiration rate based on age and gender.
    Parameters:
        resp (float): Respiration rate in breaths per minute
        age (int): Patient's age
        gender (str): 'Male' or 'Female'
    Returns:
        dict: classification with status and disease label
    """
    if resp <= 0:
        return {"status": "Sensor Disconnected", "disease": None}

    # Define normal ranges based on age
    if age < 40:
        normal_low, normal_high = 12, 18
    elif age < 60:
        normal_low, normal_high = 14, 18
    else:
        normal_low, normal_high = 14, 20

    # Classification logic
    if resp < normal_low:
        return {"status": "Slow", "disease": "Bradypnea"}
    elif resp > normal_high:
        return {"status": "Rapid", "disease": "Tachypnea"}
    else:
        return {"status": "Normal", "disease": None}

def classify_ecg_bpm(bpm, age, gender):
    """
    Classify ECG heart rate based on age and gender.
    Parameters:
        bpm (float): Heart rate in BPM
        age (int): Patient's age
        gender (str): 'Male' or 'Female'
    Returns:
        dict: classification with status and disease label
    """

    # Default fallback
    if bpm <= 0 or age is None or gender not in ["Male", "Female"]:
        return {"status": "Unknown", "disease": None}

    # ECG BPM thresholds by age and gender (from 2nd–98th percentiles)
    bpm_ranges = {
        "Male": [
            (19, (49, 107)), (29, (45, 94)), (39, (46, 95)), (49, (47, 95)),
            (59, (48, 94)), (69, (48, 95)), (79, (50, 99)), (200, (40, 97))
        ],
        "Female": [
            (19, (47, 105)), (29, (48, 98)), (39, (47, 95)), (49, (47, 90)),
            (59, (52, 94)), (69, (53, 94)), (79, (55, 98)), (200, (50, 102))
        ]
    }

    # Find age group
    for max_age, (low_thresh, high_thresh) in bpm_ranges[gender]:
        if age <= max_age:
            if bpm < low_thresh:
                return {"status": "Low", "disease": "Bradycardia"}
            elif bpm > high_thresh:
                return {"status": "High", "disease": "Tachycardia"}
            else:
                return {"status": "Normal", "disease": None}

    # Fallback
    return {"status": "Normal", "disease": None}
