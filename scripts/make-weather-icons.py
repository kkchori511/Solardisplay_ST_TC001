"""날씨 아이콘 8x8을 assets/weather/*.png로 만든다. GIF 변환은 sips로 한다.
사용법: python3 -I scripts/make-weather-icons.py
"""
import os, struct, zlib

PAL = {
    ".": (0, 0, 0),
    "Y": (255, 215, 0),    # 햇살
    "O": (255, 165, 0),    # 해
    "M": (245, 230, 160),  # 달
    "W": (200, 210, 225),  # 구름
    "D": (120, 130, 145),  # 어두운 구름
    "B": (60, 140, 255),   # 비
    "X": (255, 255, 255),  # 눈
    "F": (150, 165, 180),  # 안개
    "T": (255, 235, 0),    # 번개
}

ICONS = {
    # 맑음 (낮)
    "sunny": [
        "...YY...",
        ".Y.YY.Y.",
        "..OOOO..",
        "YOOOOOOY",
        "YOOOOOOY",
        "..OOOO..",
        ".Y.YY.Y.",
        "...YY...",
    ],
    # 맑음 (밤)
    "clear_night": [
        "..MMM...",
        ".MM.....",
        "MM......",
        "MM......",
        "MM......",
        "MM......",
        ".MM..MM.",
        "..MMMM..",
    ],
    # 구름조금/구름많음 (낮)
    "partly_day": [
        "..Y.Y...",
        "...OO...",
        ".YOOWWW.",
        "..OWWWWW",
        "..WWWWWW",
        "..WWWWWW",
        "...WWWW.",
        "........",
    ],
    # 구름조금/구름많음 (밤)
    "partly_night": [
        "..MM....",
        ".M.WWW..",
        ".M.WWWWW",
        "..WWWWWW",
        "..WWWWWW",
        "..WWWWWW",
        "...WWWW.",
        "........",
    ],
    # 흐림
    "cloudy": [
        "........",
        "..WWW...",
        ".WWWWWW.",
        ".WWWWWWW",
        "WWWWWWWW",
        "WWWWWWWW",
        ".WWWWWW.",
        "........",
    ],
    # 맑은뒤흐림: 왼쪽에 해, 오른쪽이 구름으로 덮임
    "clear_to_cloudy": [
        "Y..Y....",
        ".OOO..WW",
        "YOOO.WWW",
        ".OOO.WWW",
        "Y..WWWWW",
        "...WWWWW",
        "....WWW.",
        "........",
    ],
    # 비온뒤갬: 왼쪽 비구름, 오른쪽 위에 해
    "rain_to_clear": [
        "....Y.Y.",
        ".....OO.",
        "DDD.YOOY",
        "DDDD.OO.",
        "DDDD..Y.",
        ".B.B....",
        "B.B.....",
        ".B......",
    ],
    # 약한 비/이슬비
    "drizzle": [
        "..WWW...",
        ".WWWWW..",
        "WWWWWWW.",
        ".WWWWW..",
        "........",
        ".B...B..",
        "...B....",
        "B...B...",
    ],
    # 비
    "rain": [
        "..DDD...",
        ".DDDDD..",
        "DDDDDDD.",
        "DDDDDDDD",
        ".DDDDDD.",
        "B.B.B.B.",
        ".B.B.B.B",
        "B.B.B.B.",
    ],
    # 소나기 (구름 아래 굵은 빗줄기)
    "shower": [
        "..WWW...",
        ".WWWWW..",
        "WWWWWWW.",
        ".WWWWWW.",
        "..B..B..",
        ".B..B..B",
        ".B..B..B",
        "B..B....",
    ],
    # 천둥번개
    "thunder": [
        "..DDD...",
        ".DDDDD..",
        "DDDDDDD.",
        ".DDDDDD.",
        "...TT...",
        "..TT....",
        "...TT...",
        "..T.....",
    ],
    # 눈
    "snow": [
        "..WWW...",
        ".WWWWW..",
        "WWWWWWW.",
        ".WWWWW..",
        "........",
        ".X...X..",
        "...X....",
        "X...X...",
    ],
    # 비/눈 (진눈깨비)
    "sleet": [
        "..DDD...",
        ".DDDDD..",
        "DDDDDDD.",
        ".DDDDD..",
        "........",
        "B.X..B.X",
        ".X.B.X..",
        "B..X..B.",
    ],
    # 안개
    "fog": [
        "........",
        "FFFFFFF.",
        "........",
        ".FFFFFFF",
        "........",
        "FFFFFFF.",
        "........",
        ".FFFFFFF",
    ],
}

def png(rows):
    raw = b"".join(b"\x00" + b"".join(bytes(PAL[c] + (255,)) for c in row) for row in rows)
    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 8, 8, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "weather")
os.makedirs(out, exist_ok=True)
for name, rows in ICONS.items():
    assert len(rows) == 8 and all(len(r) == 8 for r in rows), name
    assert all(c in PAL for r in rows for c in r), name
    open(os.path.join(out, name + ".png"), "wb").write(png(rows))
print(len(ICONS), "개 생성:", ", ".join(ICONS))
