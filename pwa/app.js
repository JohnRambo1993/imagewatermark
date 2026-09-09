document.getElementById('watermarkForm').addEventListener('submit', async function(e) {
    e.preventDefault();

    const fileInput = document.getElementById('imageFile');
    const useWithInput = document.getElementById('useWith');

    if (!fileInput.files || fileInput.files.length === 0) {
        alert('Please select an image file.');
        return;
    }

    const file = fileInput.files[0];
    const useWith = useWithInput.value.trim();

    if (!useWith) {
        alert('Please enter company/organization name.');
        return;
    }

    const reader = new FileReader();
    reader.onload = function(event) {
        const img = new Image();
        img.onload = function() {
            processWatermark(img, file.name, useWith);
        };
        img.src = event.target.result;
    };
    reader.readAsDataURL(file);
});

function processWatermark(img, originalFilename, useWith) {
    const width = img.width;
    const height = img.height;

    // Font size scaling: max(12, int(width * 0.025))
    const fontSize = Math.max(12, Math.floor(width * 0.025));

    // Date YYYY-MM-DD
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const dateStr = `${yyyy}-${mm}-${dd}`;

    const watermarkText = `for usage with ${useWith} only at ${dateStr}`;

    // Measure text size using temporary canvas context
    const tempCanvas = document.createElement('canvas');
    const tempCtx = tempCanvas.getContext('2d');
    const fontSpec = `${fontSize}px sans-serif, DejaVu Sans, Arial`;
    tempCtx.font = fontSpec;

    const textMetrics = tempCtx.measureText(watermarkText);
    const tw = Math.ceil(textMetrics.width);
    const th = fontSize; // Approximate text height

    // Padding
    const paddingX = 40;
    const paddingY = 40;
    const stampW = tw + paddingX;
    const stampH = th + paddingY;

    // Create text stamp canvas
    const stampCanvas = document.createElement('canvas');
    stampCanvas.width = stampW;
    stampCanvas.height = stampH;
    const stampCtx = stampCanvas.getContext('2d');

    stampCtx.font = fontSpec;
    stampCtx.fillStyle = 'rgba(128, 128, 128, 0.7)'; // RGBA 128, 128, 128 with ~178 alpha (178/255 ≈ 0.7)
    stampCtx.textBaseline = 'top';
    stampCtx.fillText(watermarkText, Math.floor(paddingX / 2), Math.floor(paddingY / 2));

    // Main Canvas
    const canvas = document.getElementById('hiddenCanvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Draw original image
    ctx.drawImage(img, 0, 0);

    // Tile stamp across image canvas
    for (let y = 0; y < height; y += stampH) {
        for (let x = 0; x < width; x += stampW) {
            ctx.drawImage(stampCanvas, x, y);
        }
    }

    // Output JPEG
    const dataUrl = canvas.toDataURL('image/jpeg', 0.92);

    const preview = document.getElementById('preview');
    const downloadLink = document.getElementById('downloadLink');
    const resultSection = document.getElementById('resultSection');

    preview.src = dataUrl;

    // Construct download filename
    const extIdx = originalFilename.lastIndexOf('.');
    const baseName = extIdx !== -1 ? originalFilename.substring(0, extIdx) : originalFilename;
    downloadLink.download = `watermarked_${baseName}.jpg`;
    downloadLink.href = dataUrl;

    resultSection.style.display = 'flex';
}
