"""시계 화면(GET /api/v1/display/screen의 JSON)을 문자로 그린다.
사용법: curl -s http://192.168.0.12/api/v1/display/screen | python3 -I scripts/show-screen.py
같은 색은 같은 글자(Y, R, G, B, W...)로 나오고 마지막 줄에 색 범례가 나온다.
"""
import json
import sys

data = json.load(sys.stdin)
width = data["width"]
letters = {0: "."}
pool = "YRGBWOCMPSTKQ"


def letter(value):
    if value not in letters:
        index = len(letters) - 1
        letters[value] = pool[index] if index < len(pool) else "?"
    return letters[value]


for y in range(data["height"]):
    print("".join(letter(data["pixels"][y * width + x]) for x in range(width)))
print({"%06X" % color: char for color, char in letters.items() if color})
