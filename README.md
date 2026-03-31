# Repository: image-recognition-app
This is an end-to-end image classification system built around Edge Impulse (EI), a platform for training and deploying ML models on edge devices. The project covers the full ML pipeline: data preprocessing, model training, and serving predictions via a REST API.

## Top-Level Structure
```
image-recognition-app/
├── dsp-block/              # Custom Digital Signal Processing (preprocessing) block
├── learning-block/         # ML model training experiments (3 variants)
│   ├── baseline/
│   ├── aug/
│   └── finetune/
├── transformation-block/   # Placeholder EI transformation block
├── web-app/                # Django REST API for serving predictions
└── docker-compose.yml      # Runs the web-app in Docker
```
# Component Breakdown
## 1. dsp-block/ — Image Preprocessing Server

Language: Python | Key libs: NumPy, OpenCV

An Edge Impulse custom DSP block that acts as an HTTP server (port 4446). It receives raw image data and preprocesses it for the model:
- Accepts raw pixel arrays (handles packed 24-bit 0xRRGGBB integers, flat byte arrays, etc.)
- Auto-detects or is told the input shape (width, height, channels)
- Resizes images to a configurable target size (default 160×160)
- Converts between grayscale (1-channel) and RGB (3-channel) as needed
- Normalizes pixel values to [0, 1]
- Exposes `/run` (single image) and `/batch` (multiple images) POST endpoints, plus `/parameters GET`
## 2. learning-block/ — Model Training Scripts
Language: Python | Key libs: TensorFlow/Keras, NumPy
Three training variants, all using MobileNetV2 (160×160, pretrained on ImageNet) as a backbone with a custom classification head:

### Variant	Description
- `baseline/`	Simple warmup (frozen backbone) → fine-tune (75% unfrozen). Two-phase training.
- `aug/`	Same as baseline but with data augmentation layers built into the model
- `finetune/`	Most advanced: full hyperparameter config via JSON/CLI, configurable augmentation strength (off/light/medium/strong), optional class weights, cosine LR decay, early stopping, AdamW optimizer support

### All variants:
- Load .npy feature arrays produced by the DSP block
- Output a SavedModel + TFLite (float32) model file
- Save training history as JSON

## 3. transformation-block/ — EI Transformation Block
A minimal placeholder EI transformation block (hello.sh) — a Bash script that accepts `--name` and prints a greeting. This is a skeleton for future data transformation logic.

## 4. web-app/ — Django REST API
Language: Python | Key libs: Django, Django REST Framework, drf-spectacular, Pillow, tflite-runtime
A Django app that serves image classification predictions:

- `classifier/` — the Django app with `views.py, serializers.py, urls.py`
- Single endpoint: POST `/api/v1/classify/` — accepts an uploaded image, runs inference, returns `{prediction, confidence}`
- Currently uses a placeholder inference function (returns a fake "Mug" prediction); the real TFLite model integration is commented out
- `classifier_core/` — Django project settings (SQLite DB, REST framework, drf-spectacular for OpenAPI docs)
- Auto-generates an OpenAPI schema via drf-spectacular
- Runs on port 8000 via docker-compose

### Key Technologies
| Area                  | Technology                                                              |
|-----------------------|-------------------------------------------------------------------------|
| ML backbone           | MobileNetV2 (TensorFlow/Keras)                                          |
| Model export          | TFLite (float32)                                                        |
| Image preprocessing   | OpenCV, NumPy                                                           |
| Web API               | Django + Django REST Framework                                          |
| API docs              | drf-spectacular (OpenAPI/Swagger)                                       |
| Image handling        | Pillow                                                                  |
| Platform integration  | Edge Impulse (custom DSP, learning, transformation blocks)              |
| Containerization      | Docker + docker-compose                                                 |
| Data upload           | Edge Impulse CLI (`edge-impulse-uploader`)                              |

### Data Flow
```
Raw images
    │
    ▼ (Edge Impulse uploads via CLI)
Edge Impulse Platform
    │
    ▼ (DSP block — dsp-block/)
Preprocessed 160×160×3 feature arrays (.npy)
    │
    ▼ (Learning block — learning-block/)
Trained TFLite model
    │
    ▼ (Web app — web-app/)
REST API: POST /api/v1/classify/ → JSON prediction
```
## Current State / TODOs
- The web-app's inference logic is not yet wired up — the TFLite model call is commented out and replaced by a placeholder returning "Mug" with 85% confidence
- The aug/model.py file is the largest (27KB), it's the most developed training variant
- The transformation-block is a minimal placeholder shell script

## data upload
To upload data using the ingestion API from EI, navigate to the main dir were that data lives and run:
```
for dir in */; do \
    label=$(basename "$dir"); \
    echo "Uploading '$label' with automatic 80/20 splitting..."; \
    edge-impulse-uploader --label "$label" --category split "$dir"* ; \
done
```
