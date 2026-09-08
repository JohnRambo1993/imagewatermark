import os
import io
import datetime
from flask import Flask, render_template, request, send_file, abort
from werkzeug.utils import secure_filename
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Util.Padding import unpad
from PIL import Image, ImageDraw, ImageFont

app = Flask(__name__)

IMAGE_DIR = os.environ.get('IMAGE_DIR', '/images')

def decrypt_image(file_path, passphrase):
    with open(file_path, 'rb') as f:
        salt = f.read(16)
        iv = f.read(16)
        ciphertext = f.read()

    key = PBKDF2(passphrase, salt, dkLen=32, count=1000000)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    decrypted_data = unpad(cipher.decrypt(ciphertext), AES.block_size)
    return decrypted_data

def add_watermark(image_bytes, use_with):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    width, height = image.size

    # Font size scaling
    font_size = max(12, int(width * 0.025))

    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", font_size)
    except:
        font = ImageFont.load_default()

    date_str = datetime.date.today().strftime("%Y-%m-%d")
    watermark_text = f"for usage with {use_with} only at {date_str}"

    # Measure text size
    temp_draw = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    text_bbox = temp_draw.textbbox((0, 0), watermark_text, font=font)
    tw = text_bbox[2] - text_bbox[0]
    th = text_bbox[3] - text_bbox[1]

    # Padding
    padding_x = 40
    padding_y = 40
    stamp_w, stamp_h = tw + padding_x, th + padding_y

    # Create the text stamp (horizontal)
    txt_stamp = Image.new("RGBA", (stamp_w, stamp_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(txt_stamp)
    d.text((padding_x//2, padding_y//2), watermark_text, font=font, fill=(128, 128, 128, 178))

    # Create the watermark layer
    watermark_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    # Tile the stamp across the image
    for y in range(0, height, stamp_h):
        for x in range(0, width, stamp_w):
            watermark_layer.paste(txt_stamp, (x, y), txt_stamp)

    combined = Image.alpha_composite(image, watermark_layer)

    output = io.BytesIO()
    combined.convert("RGB").save(output, format="JPEG")
    output.seek(0)
    return output

@app.route('/')
def index():
    try:
        files = sorted([f for f in os.listdir(IMAGE_DIR) if f.endswith('.jpg')])
    except Exception as e:
        files = []
        print(f"Error listing images: {e}")
    return render_template('index.html', files=files)

@app.route('/process', methods=['POST'])
def process():
    filename = secure_filename(request.form.get('filename', ''))
    use_with = request.form.get('use_with')
    passphrase = request.form.get('passphrase')

    if not filename or not passphrase:
        return "Missing parameters", 400

    file_path = os.path.join(IMAGE_DIR, filename)
    if not os.path.exists(file_path):
        return "File not found", 404

    try:
        decrypted_data = decrypt_image(file_path, passphrase)
        watermarked_io = add_watermark(decrypted_data, use_with)
        return send_file(watermarked_io, mimetype='image/jpeg', as_attachment=True, download_name=f"watermarked_{filename}")
    except Exception as e:
        import traceback
        traceback.print_exc()
        return f"Error: {str(e)}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
