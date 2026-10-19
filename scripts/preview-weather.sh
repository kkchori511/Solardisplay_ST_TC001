#!/bin/sh
# 날씨 화면 배치를 시험 값으로 미리 본다. 실제 weather.be의 계산(compute)을 그대로 거친다.
# 사용법: scripts/preview-weather.sh <기온> <강수확률> [<최저> <최고>]   예: scripts/preview-weather.sh -23 89
#        최저/최고를 주면 가운데 버튼을 눌렀을 때의 최저/최고 화면을 보여준다 (예: ... 12 3 14). 시계 상태에 따라 첫 시도가 일반 화면으로 나올 수 있으니, 그럴 땐 재부팅 후 다시 한다
# 임시 앱(weather_test)을 올렸다가 끝나면 지운다. 시계 IP는 CLOCK_IP로 바꾼다.
set -eu
CLOCK_IP="${CLOCK_IP:-192.168.0.12}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="${1:?기온 (예: -23)}"
POP="${2:?강수확률 (예: 89)}"
MIN="${3:-}"
MAX="${4:-}"
TMP="$(mktemp -t weather_test).be"
trap 'rm -f "$TMP"; curl -s -m 8 -X DELETE "http://$CLOCK_IP/api/v1/apps/weather_test" >/dev/null 2>&1 || true' EXIT

python3 -I - "$DIR/scripts/weather.be" "$TEMP" "$POP" "$MIN" "$MAX" > "$TMP" <<'PY'
import re, sys
path, temp, pop, mn, mx = sys.argv[1:6]
s = open(path, encoding="utf-8").read()
# 설정(키)과 주기 갱신을 끄고, 시험 값을 넣어 compute()를 실행한다
s = re.sub(r'# @config .*\n', '', s)
s = s.replace('self.key = store.get("kma_key", "")', 'self.key = "x"')
s = s.replace("  def loop()\n    self.age_s += 1", "  def loop()\n    if true\n      return\n    end\n    self.age_s += 1")
m = re.search(r"    self\.mm_view_s = 0\n  end", s)
inject = m.group(0)[:-6] + '''
    var k = format("%%04d%%02d%%02d%%02d00", year(), month(), day(), hour())
    self.times = [k]
    self.vals = {"SKY": {k: 3}, "PTY": {k: 0}, "POP": {k: %s}, "LGT": {k: 0}}
    self.ncst_temp = %s.0
    self.compute()''' % (pop, temp)
if mn and mx:
    inject += '''
    self.mm_tmn = %s
    self.mm_tmx = %s
    self.mm_ready = true
    self.mm_view = true
    self.mm_view_s = 100000''' % (mn, mx)
inject += '''
  end'''
s = s.replace("  def on_hide()\n    self.mm_view = false\n  end", "  def on_hide()\n  end")  # 시험 화면이 꺼지지 않게
print(s.replace(m.group(0), inject, 1))
PY

RESULT="$(curl -sS -m 20 -X PUT "http://$CLOCK_IP/api/v1/apps/script/weather_test" -H "Content-Type: text/plain" --data-binary @"$TMP")"
echo "$RESULT" | python3 -I -c 'import json,sys; e=json.load(sys.stdin)["error"]; print("설치 오류:", e) if e else None'
curl -s -m 8 -X PUT "http://$CLOCK_IP/api/v1/apps/active" -H "Content-Type: application/json" -d '{"name":"weather_test","fast":true}' >/dev/null
sleep 2
echo "== 기온 $TEMP, 강수확률 $POP"
curl -s -m 8 "http://$CLOCK_IP/api/v1/display/screen" | python3 -I "$DIR/scripts/show-screen.py"
