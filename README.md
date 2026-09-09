# Secure Image Encryption & Watermarking Utilities

## Overview

The main intent of this application is to provide a fast and secure way to watermark sensitive images, such as passports or driving licenses. Numerous leaks on the internet have exposed sensitive identity documents; to prevent identity theft, this project provides solutions that allow users to safely generate watermarked copies on demand across multiple deployment models.

## Deployment Options & Architecture Alternatives

Depending on your environment and security requirements, choose one of the following deployment options:

1. **Primary Solution: Docker/Flask Server (`app/`)**
   - **Use case**: Best when you have a virtual server (VPS, cloud instance) and can deploy Docker containers.
   - **Features**: Stores encrypted images server-side (AES-256-CBC with PBKDF2). Decryption occurs in-memory on demand when requested via the web UI.

2. **First Alternative: Progressive Web App (PWA) (`pwa/`)**
   - **Use case**: Best when you have a simple static webserver without Docker and need quick access on mobile devices (Android or iPhone).
   - **Hosting**: Can be deployed on free static hosting providers such as **GitHub Pages**, **Google Firebase Hosting / Cloud Storage**, **Vercel**, **Netlify**, or **Cloudflare Pages**.
   - **Features**: Installable directly on Android or iOS homescreens. The user provides an unencrypted image directly from their device (file upload input), and all watermarking is processed client-side via HTML5 Canvas—no image data is uploaded to any backend. Works offline via Service Worker.

3. **Third Alternative: PowerShell Script (`watermark.ps1`)**
   - **Use case**: Best when you don't have a webserver at all or don't need watermarking on your phone.
   - **Features**: Standalone, offline PowerShell utility to watermark local images directly on Windows machines or systems with PowerShell Core installed.

---

## File Structure

- `app/`: Flask web application that serves, decrypts, and watermarks encrypted images.
  - `main.py`: Flask application logic.
  - `templates/index.html`: Web interface for selecting images and applying watermarks.
  - `Dockerfile`: Container definition for running the Flask app.
- `pwa/`: Progressive Web App for static webservers & mobile devices.
  - `index.html`: PWA user interface with local file picker and company input.
  - `app.js`: Client-side HTML5 canvas watermarking logic.
  - `sw.js`: Service worker for offline caching.
  - `manifest.json`: Web App Manifest for mobile installation.
- `encrypt_tool.py`: Python utility script to encrypt images.
- `encrypt_tool.ps1`: PowerShell utility script to encrypt images.
- `watermark.ps1`: PowerShell script to apply custom watermarks locally.
- `docker-compose.yml`: Docker Compose configuration.

---

## Usage Instructions

### 1. Primary App: Flask Web Application (`app/main.py`)

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

### 2. First Alternative: Progressive Web App (`pwa/`)

The PWA allows users to watermark photos directly from their phone or browser without needing a Docker server or server-side decryption.

#### Deploying to Static Hosting
Simply deploy the contents of the `pwa/` directory to any static web host:
- **GitHub Pages**: Upload `pwa/` files to a repository branch and enable GitHub Pages in repository settings.
- **Google Firebase Hosting / Cloud Storage**: Deploy static content via `firebase deploy` or host from Google Cloud Storage static website endpoint.
- **Vercel / Netlify / Cloudflare Pages**: Connect your git repository and set the publish directory to `pwa`.

#### Usage on Mobile (Android / iPhone)
1. Open the hosted PWA URL in Chrome (Android) or Safari (iPhone).
2. Tap **"Add to Home Screen"** or **"Install App"**.
3. Launch the app from your home screen.
4. Select an image file from your device, type the company name ("for use with"), and click **Generate Watermark**.
5. Download or save the watermarked image.

---

### 3. Third Alternative: PowerShell Watermark Tool (`watermark.ps1`)

An offline PowerShell utility script to apply custom watermarks directly on a local Windows machine without using a web server.

#### Usage
```powershell
pwsh watermark.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -ForUseWith <organization_or_person>
```

#### Example
```powershell
pwsh watermark.ps1 -InputPath photo.jpg -OutputPath watermarked.jpg -ForUseWith "ACME Corp"
```

---

### Encryption Utility Tools (`encrypt_tool.py` & `encrypt_tool.ps1`)

Command-line utilities used to encrypt images prior to hosting them in the primary Flask web app.

#### Python Encryption Tool
```bash
python encrypt_tool.py <input_jpg> <output_jpg> <passphrase>
```

#### PowerShell Encryption Tool
```powershell
pwsh encrypt_tool.ps1 -InputPath <input_jpg> -OutputPath <output_jpg> -Passphrase <passphrase>
```
