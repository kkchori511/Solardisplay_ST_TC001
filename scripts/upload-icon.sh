#!/bin/sh
# 번개 아이콘(assets/bolt.gif)을 시계의 /ICONS에 업로드한다. 한 번만 하면 된다.
# 시계 펌웨어를 다시 플래시하면 지워지므로 그때 다시 실행한다.
set -eu
CLOCK_IP="${CLOCK_IP:-192.168.0.12}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
curl -sS -m 15 -X POST "http://${CLOCK_IP}/api/v1/files?dir=/ICONS" -F "file=@${DIR}/assets/bolt.gif"
echo
