import os
import sys
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Random import get_random_bytes
from Crypto.Util.Padding import pad

def encrypt_image(input_path, output_path, passphrase):
    with open(input_path, 'rb') as f:
        data = f.read()

    salt = get_random_bytes(16)
    key = PBKDF2(passphrase, salt, dkLen=32, count=1000000)
    iv = get_random_bytes(16)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ciphertext = cipher.encrypt(pad(data, AES.block_size))

    with open(output_path, 'wb') as f:
        f.write(salt)
        f.write(iv)
        f.write(ciphertext)

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python encrypt_tool.py <input_jpg> <output_jpg> <passphrase>")
        sys.exit(1)

    encrypt_image(sys.argv[1], sys.argv[2], sys.argv[3])
    print(f"Encrypted {sys.argv[1]} to {sys.argv[2]}")
