#!/bin/sh
# 날씨 스크립트(scripts/weather.be)를 시계에 올리고 인증키를 설정값으로 넣는다.
# 인증키는 .env.local의 KMA_SERVICE_KEY에서 읽으며 출력하지 않는다.
set -eu
CLOCK_IP="${CLOCK_IP:-192.168.0.12}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY="$(grep '^KMA_SERVICE_KEY=' "$DIR/.env.local" | cut -d= -f2- | tr -d '\r\n" ')"
[ -n "$KEY" ] || { echo "KMA_SERVICE_KEY가 .env.local에 없습니다" >&2; exit 1; }
mask() { sed "s/$KEY/[KEY]/g"; }

echo "1) 아이콘 업로드"
for f in "$DIR"/assets/weather/*.gif; do
  curl -sS -m 15 -X POST "http://$CLOCK_IP/api/v1/files?dir=/ICONS" -F "file=@$f" >/dev/null
done
echo "   $(ls "$DIR"/assets/weather/*.gif | wc -l | tr -d ' ')개"

echo "2) 스크립트 설치"
curl -sS -m 20 -X PUT "http://$CLOCK_IP/api/v1/apps/script/weather" -H "Content-Type: text/plain" --data-binary @"$DIR/scripts/weather.be" | mask; echo

echo "3) 인증키 설정"
printf '{"kma_key":"%s"}' "$KEY" | curl -sS -m 20 -X PATCH "http://$CLOCK_IP/api/v1/apps/weather/config" -H "Content-Type: application/json" --data-binary @- | mask; echo

echo "4) 앱 표시 시간 기본 50초 (태양광), 날씨는 스크립트에서 10초"
curl -sS -m 10 -X PATCH "http://$CLOCK_IP/api/v1/settings" -H "Content-Type: application/json" -d '{"appDurationMs":50000}' | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print("   appDurationMs =", d.get("appDurationMs", d))'
