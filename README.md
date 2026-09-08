# Secure Image Encryption & Watermarking Utilities

## Overview

The main intent of this application is to provide a fast and secure way to watermark sensitive images, such as passports or driving licenses. Numerous leaks on the internet have exposed sensitive identity documents; to prevent identity theft, this project provides a solution that allows users to store encrypted documents on a server and safely generate watermarked copies on demand. The web application offers a convenient interface accessible from smartphones, ensuring sensitive documents are always handy when needed.

The core part of this repository is the web application. The Python and PowerShell encryption scripts serve as utility tools so that the web application can host and serve encrypted images. The PowerShell watermarking script provides an offline alternative to watermark unencrypted images locally on a Windows machine.

## File Structure

- `app/`: Flask web application that serves, decrypts, and watermarks encrypted images.
  - `main.py`: Flask application logic.
  - `templates/index.html`: Web interface for selecting images and applying watermarks.
  - `Dockerfile`: Container definition for running the Flask app.
- `encrypt_tool.py`: Python utility script to encrypt images.
- `encrypt_tool.ps1`: PowerShell utility script to encrypt images.
- `watermark.ps1`: PowerShell script to apply custom watermarks locally.
- `docker-compose.yml`: Docker Compose configuration.

---

## Usage Instructions

### 1. Flask Web Application (`app/main.py`)

The Flask web application is the primary interface. To ensure only authorized persons can access sensitive documents, images hosted by the app must be encrypted using either `encrypt_tool.py` or `encrypt_tool.ps1`. When requesting a watermarked image via the UI, the user enters the encryption passphrase to decrypt the image in memory and apply the dynamic watermark.

#### How the App Locates Images
- The application scans a specific directory for encrypted image files ending in `.jpg`.
- By default, the application looks in the directory path defined by the `IMAGE_DIR` environment variable (defaults to `/images`).
- **Providing Images**: Place your `.jpg` files—which **must** be pre-encrypted using either `encrypt_tool.py` or `encrypt_tool.ps1`—into the directory specified by `IMAGE_DIR`.
- **Changing the Path**:
  - When running with Docker Compose, update the volume mapping or `IMAGE_DIR` environment variable in `docker-compose.yml`:
    ```yaml
    environment:
      - IMAGE_DIR=/images
    volumes:
      - /path/to/your/encrypted/images:/images
    ```
  - When running locally, export the `IMAGE_DIR` variable before starting the application:
    ```bash
    export IMAGE_DIR="/path/to/your/encrypted/images"
    python app/main.py
    ```

#### Running the Web Application
- **With Docker Compose**:
  ```bash
  docker-compose up --build
  ```
  Access the web interface at `http://localhost:5000`.

- **Directly with Python**:
  ```bash
  pip install flask pillow pycryptodome werkzeug
  export IMAGE_DIR="/path/to/your/encrypted/images"
  python app/main.py
  ```

---

### 2. Python Encryption Tool (`encrypt_tool.py`)

A command-line utility used to encrypt images prior to making them available in the web app.

#### Prerequisites
```bash
pip install pycryptodome
```

#### Usage
```bash
python encrypt_tool.py <input_jpg> <output_jpg> <passphrase>
```

#### Example
```bash
python encrypt_tool.py passport.jpg passport_encrypted.jpg mysecretpassphrase
```

---

### 3. PowerShell Encryption Tool (`encrypt_tool.ps1`)

A PowerShell equivalent utility to encrypt images before adding them to the web app image repository.

#### Prerequisites
PowerShell 7+ (`pwsh`) or Windows PowerShell 5.1+.

#### Usage
```powershell
pwsh encrypt_tool.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -Passphrase <passphrase>
```
Or run interactively (prompts for missing inputs):
```powershell
pwsh encrypt_tool.ps1
```

#### Example
```powershell
pwsh encrypt_tool.ps1 passport.jpg passport_encrypted.jpg mysecretpassphrase
```

---

### 4. PowerShell Watermark Tool (`watermark.ps1`)

An offline PowerShell utility script to apply custom watermarks directly on a local Windows machine without using the web app.

#### Usage
```powershell
pwsh watermark.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -ForUseWith <organization_or_person>
```

#### Example
```powershell
pwsh watermark.ps1 -InputPath photo.jpg -OutputPath watermarked.jpg -ForUseWith "ACME Corp"
```
