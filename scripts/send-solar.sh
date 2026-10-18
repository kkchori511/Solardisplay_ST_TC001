#!/bin/sh
# 시계(AWTRIX NG)에 태양광 출력을 W 단위로 표시한다.
# 사용법: scripts/send-solar.sh 2300
#         CLOCK_IP=192.168.0.12 scripts/send-solar.sh 850
set -eu

CLOCK_IP="${CLOCK_IP:-192.168.0.12}"
WATTS="${1:?사용법: $0 <와트 정수>}"

curl -sS -m 8 -X PUT "http://${CLOCK_IP}/api/v1/apps/pushed/solar" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"${WATTS}W\",\"textColor\":\"#FFD700\",\"lifetimeMs\":120000,\"lifetimeExpiry\":\"mark\"}"
echo
