# Secure Image Encryption & Watermarking Utilities

This repository provides tools and a web application for securely encrypting, decrypting, and watermarking image files.

## Overview

The system allows users to encrypt images using AES-256 in CBC mode with a key derived from a passphrase using PBKDF2 (1,000,000 iterations). Encrypted images can then be decrypted and watermarked dynamically or via utility scripts.

## File Structure

- `encrypt_tool.py`: Python script to encrypt images.
- `encrypt_tool.ps1`: PowerShell script to encrypt images.
- `watermark.ps1`: PowerShell script to apply custom watermarks to images.
- `app/`: Flask web application that serves, decrypts, and watermarks encrypted images.
  - `main.py`: Flask application logic.
  - `templates/index.html`: Web interface for selecting images and applying watermarks.
  - `Dockerfile`: Container definition for running the Flask app.
- `docker-compose.yml`: Docker Compose configuration.

## Cryptographic Specification

- **Algorithm**: AES-256-CBC
- **Key Derivation Function**: PBKDF2 with HMAC-SHA1
- **KDF Iterations**: 1,000,000
- **Salt Length**: 16 bytes
- **Initialization Vector (IV)**: 16 bytes
- **Padding**: PKCS#7 (AES block size 16 bytes)
- **Output File Structure**: `[16-byte Salt] + [16-byte IV] + [AES Ciphertext]`

---

## Usage Instructions

### 1. Python Encryption Tool (`encrypt_tool.py`)

#### Prerequisites
Install required dependencies:
```bash
pip install pycryptodome
```

#### Usage
```bash
python encrypt_tool.py <input_jpg> <output_jpg> <passphrase>
```

#### Example
```bash
python encrypt_tool.py sample.jpg encrypted.jpg mysecretpassphrase
```

---

### 2. PowerShell Encryption Tool (`encrypt_tool.ps1`)

#### Prerequisites
PowerShell 7+ (`pwsh`) or Windows PowerShell 5.1+.

#### Usage
You can run the script with positional or named parameters:
```powershell
pwsh encrypt_tool.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -Passphrase <passphrase>
```
Or run interactively (you will be prompted for missing parameters):
```powershell
pwsh encrypt_tool.ps1
```

#### Example
```powershell
pwsh encrypt_tool.ps1 sample.jpg encrypted.jpg mysecretpassphrase
```

---

### 3. PowerShell Watermark Tool (`watermark.ps1`)

Applies a repeated transparent tiled watermark string (`for usage with <UseWith> only at <YYYY-MM-DD>`) to an unencrypted image.

#### Usage
```powershell
pwsh watermark.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -ForUseWith <organization_or_person>
```

#### Example
```powershell
pwsh watermark.ps1 -InputPath photo.jpg -OutputPath watermarked.jpg -ForUseWith "ACME Corp"
```

---

### 4. Flask Web Application (`app/main.py`)

The Flask web application lists encrypted JPEG images in a configured directory (`IMAGE_DIR`), prompts the user for a passphrase and usage intent, decrypts the image in memory, applies a watermark, and returns the watermarked JPEG.

#### Running with Docker
```bash
docker-compose up --build
```
The application will be available at `http://localhost:5000`.

#### Running directly with Python
```bash
pip install flask pillow pycryptodome werkzeug
export IMAGE_DIR="/path/to/encrypted/images"
python app/main.py
```
