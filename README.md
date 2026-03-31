# Edge Impulse Custom DSP Block (Python) - AAU

This repository contains an example of a custom Digital Signal Processing (DSP) block for Edge Impulse, specifically configured for use within the **AAU (Aalborg University)** organization and DSP course.

---

## 🧠 Understanding v2 Custom Blocks vs. Standard Blocks

### What is a "v2" Custom Block?
The "v2" architecture (the current standard for custom processing blocks) allows you to inject your own proprietary algorithms into the Edge Impulse pipeline. 

- **How it works**: Your block acts as an HTTP server that the Edge Impulse Studio communicates with via specific endpoints (`/parameters`, `/run`, `/batch`).
- **Flexibility**: Unlike standard blocks, you have full control over the libraries (e.g., NumPy, SciPy) and the mathematical logic.
- **Deployment**: While standard blocks generate optimized C++ automatically, custom blocks require you to implement the equivalent logic in C++ for final on-device deployment.

### Comparison: Custom (v2) vs. Standard Spectral Analysis
The **Spectral Analysis** block is the most common built-in tool in Edge Impulse. Here is how they differ:

| Feature | Custom v2 Block (This Repo) | Standard Spectral Analysis |
| :--- | :--- | :--- |
| **Logic** | User-defined (Python/NumPy) | Pre-defined (Optimized C++) |
| **Use Case** | Specialized sensor fusion, custom math | Vibration, motion, simple audio |
| **Optimization** | Manual C++ implementation required | Automatic firmware generation |
| **Configuration** | Dynamic via `parameters.json` | GUI-based in Studio |

---

## 📉 Deep Dive: Digital Signal Processing in `dsp.py`

In an AAU DSP context, this block demonstrates the fundamental pipeline for sensor data transformation. The core logic resides in `generate_features`.

### 1. Data Representation & Reshaping
Edge Impulse transmits time-series data as a contiguous 1D array. To perform multi-axis analysis, we must first reconstruct the signal matrix:
```python
raw_data = raw_data.reshape(int(len(raw_data) / len(axes)), len(axes))
```
This transforms the input into a matrix of shape $(Samples, Axes)$, allowing for vectorized operations on specific sensor dimensions.

### 2. Signal Isolation & Processing
The algorithm iterates through each available sensor axis (e.g., $X, Y, Z$ accelerometry). For each axis, the signal is isolated into a 1D NumPy array:
```python
fx = np.array(X)
# Transformation
fx = fx * scale_axes
```
In this example, we apply a **linear scalar transformation**. In advanced AAU exercises, this is where you would implement FIR/IIR filters, FFTs, or wavelet transforms.

### 3. Feature Vectorization (Flattening)
The Edge Impulse ML pipeline expects a fixed-length 1D feature vector as input to the neural network or classifier. After processing each axis individually, the results are concatenated (flattened) back into a single array:
```python
for f in fx:
    features.append(f)
```
The resulting `features` array represents the final "feature vector" passed to the learning block.

---

## 🛠 Prerequisites

1. **Python 3.8+**
2. **Node.js v14+**
3. **Edge Impulse CLI**: Install via npm:
   ```bash
   npm install -g edge-impulse-cli
   ```

---

## 🚀 Local Development & Testing

### 1. Installation
Install the required Python dependencies in the related folder, e,g :
```bash
cd dsp-blcok
pip install -r requirements.txt
```

### 2. Run the Local DSP Server
Start the development server:
```bash
python dsp-server.py
```
The server will start on `http://localhost:4446`.

### 3. Verify Local Functionality
Test the block by sending a mock request to the `/run` endpoint:
```bash
curl -X POST http://localhost:4446/run \
  -H "Content-Type: application/json" \
  -d '{
    "features": [],
    "axes": ["image"],
    "sampling_freq": 0,
    "draw_graphs": false,
    "implementation_version": 1,
    "params": {
      "img-width": 160,
      "img-height": 160,
      "channels": 3,
      "out_channels": 3
    }
  }'
```

---

## 🏗 Deployment to AAU Organization

### 1. Secure Your Credentials
Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
# Add your Admin API Key to .env
```

### 2. Initialize and Push
**Organization ID**: `343435`

```bash
edge-impulse-blocks init
edge-impulse-blocks push
```

---

## 📚 Resources
- 🎥 [Tutorial: Building Custom Blocks (Video)](https://www.youtube.com/watch?v=7vr4D_zlQTE)
- 📖 [Edge Impulse Custom Blocks Overview](https://docs.edgeimpulse.com/docs/custom-blocks)

# Original Repository: image-recognition-app
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
