"""8x8 번개 PNG(검정 배경)를 assets/bolt.png로 만든다. GIF 변환은 sips로 한다. 사용법: python3 -I scripts/make-bolt-icon.py"""
import base64, struct, zlib

BOLT = [
    "....XX..",
    "...XX...",
    "..XX....",
    ".XXXXXX.",
    "....XX..",
    "...XX...",
    "..XX....",
    ".X......",
]
Y = (255, 215, 0, 255)
CLEAR = (0, 0, 0, 255)

raw = b"".join(
    b"\x00" + b"".join(bytes(Y if c == "X" else CLEAR) for c in row) for row in BOLT
)

def chunk(tag, data):
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

png = (
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", 8, 8, 8, 6, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(raw, 9))
    + chunk(b"IEND", b"")
)
open("assets/bolt.png", "wb").write(png)
print("assets/bolt.png 생성")
