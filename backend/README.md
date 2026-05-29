# Backend

This folder contains all the AI and recommendation logic for Capstone Glow.

## Files

- `recommendations.py` — makeup recommendation engine
- `skin_tone_detector.py` — detects skin tone from face image
- `main.py` — connects everything together
- `train_model.py` — trains the face shape classifier
- `recommendations.json` — recommendation rules for Flutter
- `models/` — trained model files go here

## How to run

py -3.12 backend/main.py

## For Member 2

You need these two files:
1. `recommendations.json`
2. `models/face_shape_model.tflite` (available after training)