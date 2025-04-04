
def classify_temp(tempF):
    if tempF == -100.0:
        return {"status": "Sensor Disconnected", "disease": None}
    if tempF < 95.0:
        return {"status": "Low", "disease": "Hypothermia"}
    if tempF < 96.8:
        return {"status": "Below Normal", "disease": None}
    if tempF <= 99:
        return {"status": "Normal", "disease": None}
    if tempF < 100.4:
        return {"status": "Elevated", "disease": None}
    if tempF < 104.0:
        return {"status": "High", "disease": "Fever"}
    if tempF < 107.0:
        return {"status": "Very High", "disease": "Hyperthermia"}
    return {"status": "Critical", "disease": "Hyperpyrexia"}

def classify_respiration(resp):
    if resp <= 0:
        return {"status": "Sensor Disconnected", "disease": None}
    if resp < 12:
        return {"status": "Slow", "disease": "Bradypnea"}
    if 12 <= resp <= 20:
        return {"status": "Normal", "disease": None}
    if resp > 20:
        return {"status": "Rapid", "disease": "Tachypnea"}
    return {"status": "Unknown", "disease": None}
