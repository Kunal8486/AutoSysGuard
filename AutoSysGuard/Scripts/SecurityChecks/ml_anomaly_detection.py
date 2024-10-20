import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import sys

def load_data(file_path):
    try:
        data = pd.read_csv(file_path)
        print(f"Loaded data shape: {data.shape}")  # For debugging
        return data
    except Exception as e:
        print(f"Error loading data: {e}")
        sys.exit(1)

def detect_anomalies(data):
    # Select only numerical columns
    numeric_data = data.select_dtypes(include=[np.number])
    
    if numeric_data.empty:
        print("No numerical data found for scaling.")
        return None  # No anomalies to report

    # Preprocess the data (standardize)
    scaler = StandardScaler()
    scaled_data = scaler.fit_transform(numeric_data)

    # Create Isolation Forest model
    model = IsolationForest(contamination=0.1, random_state=42)
    model.fit(scaled_data)

    # Predict anomalies
    predictions = model.predict(scaled_data)
    
    # -1 indicates anomaly, 1 indicates normal
    data['Anomaly'] = predictions
    anomalies = data[data['Anomaly'] == -1]

    return anomalies  # Return the detected anomalies

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the path to the CSV file.")
        sys.exit(1)

    csv_file_path = sys.argv[1]
    data = load_data(csv_file_path)
    anomalies = detect_anomalies(data)

    if anomalies is not None and not anomalies.empty:
        print("Anomalies detected:")
        print(anomalies)
    else:
        print("No anomalies detected. All data is normal.")
