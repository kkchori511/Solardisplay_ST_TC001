# Solardisplay_ST_TC001

Ulanzi TC001 픽셀 시계에 SmartThings 태양광 출력(W)을 표시하기 위한 시계(펌웨어) 쪽 작업 레포.

## 구성
- 시계: Ulanzi TC001 + AWTRIX NG 펌웨어
- 태양광 계측: 시하스 PMM-300Z2 (SmartThings 허브에 엣지 드라이버로 연결)
- 짝 레포: [Solardisplay_ST_Edgedriver](https://github.com/kkchori511/Solardisplay_ST_Edgedriver) (허브 → 시계 전송)

## 진행 순서
1. [x] 순정 펌웨어 백업 (`tc001_factory.bin`, 레포에는 올리지 않음)
2. [x] AWTRIX NG 플래시
3. [x] 시계 Wi-Fi 연결, 공유기에서 IP 고정
4. [x] curl로 시계 API 테스트 (`scripts/send-solar.sh`)

자세한 내용은 [docs/handoff-tc001-solar.md](docs/handoff-tc001-solar.md) 참고.

## 현재 상태
- 시계 IP: `192.168.0.12` (공유기 DHCP 예약으로 고정)
- 펌웨어: AWTRIX NG 1.2.2 (`usb-awtrix-ng-4mb.bin`을 `0x0`에 115200으로 플래시)
- 표시 형식: W 단위 정수 (예: `2300W`)
- 테스트: `scripts/send-solar.sh 2300`
- 다음: 드라이버 레포에서 전송 코드 작성. API는 AWTRIX 3와 다르게 `PUT /api/v1/apps/pushed/solar`를 쓴다 ([조사 노트](docs/awtrix-ng-notes.md)).
