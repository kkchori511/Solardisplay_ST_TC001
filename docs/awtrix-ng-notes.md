# AWTRIX NG 조사 노트 (TC001)

조사일: 2026-10-18. 출처는 공식 문서(blueforcer.github.io/awtrix-ng)와 GitHub 릴리스(Blueforcer/awtrix-ng).
`확인`은 문서에서 직접 읽은 것, `미확인`은 아직 읽지 못했거나 시계에서 직접 시험하지 않은 것이다.

## 1. 지원 여부 (확인)
- AWTRIX NG는 AWTRIX 3의 후속 펌웨어이며 Ulanzi TC001을 공식 지원한다. AWTRIX 3 저장소는 "Discontinued"로 표시돼 있다.
- 최신 릴리스: **v1.2.2** (2026-10-06).
- TC001: ESP32(Classic), 플래시 4MB, 32x8 화면, 버튼 3개, 배터리.

## 2. 플래시 (확인)
- **USB 최초 설치 파일은 `usb-awtrix-ng.zip`** (v1.2.2 자산 확인). 압축 안에 TC001용 `usb-awtrix-ng-4mb.bin`이 있다는 것은 문서 설명이며, zip을 풀어서 확인해야 한다.
- `firmware-awtrix-ng.bin`은 이미 NG가 설치된 시계의 업데이트용이다. 최초 설치에 쓰지 않는다.
- `usb-awtrix-ng-tc002.zip`, `awtrix-ng-tc002.awup`은 TC002용이므로 쓰지 않는다.
- 쓰기 주소 `0x0`, TC001은 부트 버튼 불필요.
- 방법 1(권장): 데스크톱 Chrome/Edge/Opera 웹 플래셔의 **Fresh install**. 방법 2: esptool.

```
esptool --chip esp32 --port /dev/cu.usbserial-1240 --baud 115200 write-flash 0x0 usb-awtrix-ng-4mb.bin
```
- 성공하면 `Hash of data verified.`가 나온다.
- **921600 baud 금지** (TC001에서 쓰기가 중간에 멈출 수 있다고 문서에 명시). 이 맥에서도 921600은 실제로 실패했고 115200으로 성공했다.
- 쓰기가 계속 실패하면 `--no-stub` 추가.
- 플래시 후 기존 설정과 Wi-Fi 정보는 지워진다.
- 정상 확인: 시리얼 모니터(115200)에 `boot: AWTRIX NG ... on ESP32` 출력.
- 복원: `~/projects/backups/tc001_factory.bin`을 `0x0`에 쓴다. 복원 시험은 하지 않았다(미확인).

## 3. 첫 부팅과 Wi-Fi (확인)
1. 시계가 설정용 핫스팟을 연다. 이름은 `awtrixng-xxxxxx` 형식이고 **비밀번호가 없다**.
2. 핫스팟에 연결하면 설정 페이지가 열린다. 안 열리면 `192.168.4.1`.
3. 집 Wi-Fi 이름과 비밀번호를 입력(Scan으로 선택 가능), 호스트 이름 지정 가능, Save 후 재부팅.
4. 연결되면 시작할 때마다 화면에 IP가 몇 초 표시된다. 웹 UI는 그 IP 또는 `http://<호스트이름>.local`.
5. 공유기에서 IP 고정(DHCP 예약)을 해둔다. 드라이버가 이 IP로 전송한다.
- 공유기에 MAC 허용 목록이 있으면 먼저 등록해야 한다. 이 시계의 MAC은 `c8:85:41:0e:4d:9c` (칩 읽기 결과).
- 부팅음/소리 설정은 문서에서 못 읽었다 (Sound 가이드 미확인).

## 4. HTTP API (확인) — AWTRIX 3 형식과 다르다
핸드오프 문서의 `POST /api/custom?name=solar`는 **NG에서 쓰지 않는다.**

| 동작 | 요청 |
|---|---|
| 앱 생성/갱신 | `PUT /api/v1/apps/pushed/{name}` (같은 이름으로 다시 PUT하면 전체 교체) |
| 앱 삭제 | `DELETE /api/v1/apps/{name}` |
| 즉시 표시 | `PUT /api/v1/apps/active` 본문 `{"name":"solar"}` |
| 기기 정보 | `GET /api/v1/device` |

- `Content-Type: application/json` 필수 (없으면 415). 빈 본문/`{}`는 422.
- 앱 이름: `[A-Za-z0-9_-]`, 1~32자. 푸시 앱 최대 50개. 요청 본문 최대 8192바이트.
- 성공 응답: `200 {"ok":true}`. 오류 본문: `{"error":{"code":"...","message":"..."}}`.
- 인증: 기본은 꺼짐. 켜면 HTTP Basic (`authEnabled`, `authUser`, `authPass`). 켜지면 드라이버 요청에 `Authorization` 헤더 필요.
- 푸시 앱은 메모리에만 저장되어 **재부팅하면 사라진다.** 보내는 쪽이 다시 보내야 한다.
- 호출 빈도 제한은 문서에서 못 찾았다(Limits 페이지 미확인). 503이면 `Retry-After: 2`.

```bash
# 태양광 값 표시 (값이 2분 이상 갱신 안 되면 어두운 빨간 테두리로 표시)
curl -X PUT http://<시계IP>/api/v1/apps/pushed/solar \
  -H "Content-Type: application/json" \
  -d '{"text":"2.3kW","textColor":"#FFD700","lifetimeMs":120000,"lifetimeExpiry":"mark"}'
```
- 주요 필드: `text`, `icon`, `textColor`, `durationMs`(표시 시간, 기본 7000), `lifetimeMs`, `lifetimeExpiry`(`remove`/`mark`).
- 아이콘은 AWTRIX Hub에서 설치한 이름 또는 ID를 쓴다. 설치 없이 쓸 수 있는지는 미확인.
- 텍스트가 같으면 갱신해도 스크롤이 처음부터 다시 시작되지 않는다.

## 5. 엣지 드라이버에 미치는 영향
- Lua 전송 코드는 `POST`가 아니라 **`PUT`**, 경로는 `/api/v1/apps/pushed/solar`로 바꿔야 한다.
- `lifetimeMs`를 두면 허브나 드라이버가 멈췄을 때 오래된 값이 최신처럼 보이지 않는다.
- 시계가 재부팅되면 앱이 사라지므로, 전력값이 갱신될 때마다 계속 PUT하는 방식이 맞다.

## 6. 아직 못 읽은 것
- `esp32/reference/http/` 문서 뒷부분(약 41,000자), Errors, Limits, Sound 페이지
- v1.2.2 릴리스 노트 본문

## 7. 작업 기록 (2026-10-18)
- 순정 백업: `~/projects/backups/tc001_factory.bin` (4MB, SHA-256 앞 16자 `837bd6329dae6b53`). 레포에는 올리지 않는다.
- 플래시: `usb-awtrix-ng-4mb.bin` (v1.2.2), `0x0`, 115200, `Hash of data verified.` 확인.
- 시계가 부팅 직후 연결하면 부팅음이 멈추지 않는 경우가 있어, 플래시/읽기 전에 약 30초 대기한다.
- Wi-Fi: `DaDa 2.4G` 연결, IP `192.168.0.12` 고정. 호스트 이름 `tc001`.
- 신호 세기가 약했다(`wifiRssi` -84). 요청 실패가 잦으면 시계 위치를 조정한다.
- 표시 형식은 kW가 아니라 W 단위(`2300W`)로 결정.
- 전송 테스트 성공(`{"ok":true}`).
- 아이콘: `icon`의 data URL은 GIF/JPEG만 허용(PNG는 거부). 8x8 번개 GIF(`assets/bolt.gif`)를 `POST /api/v1/files?dir=/ICONS`로 업로드하고 `"icon":"bolt"`로 사용한다 (`scripts/upload-icon.sh`). 재플래시하면 지워진다.
- 빨간 테두리: `lifetimeExpiry:"mark"`가 갱신 없이 `lifetimeMs`가 지나면 켜는 "오래된 값" 표시다. 사용자 요청으로 수명 설정(`lifetimeMs`, `lifetimeExpiry`)을 전송에서 뺐다. 대신 허브가 멈춰도 마지막 값이 계속 보인다.
- 시간대: `PUT /api/v1/system` 본문 `{"tz":"KST-9","tzName":"Asia/Seoul"}` (부분 갱신, 재부팅 불필요). 기본값은 유럽(CET)이라 한국과 시각이 어긋난다.
- 메뉴 축소: 내장 앱을 끄고 `solar`만 남겼다. 본문은 객체가 아니라 `true`/`false` 값 자체다.
  ```
  curl -X PUT http://192.168.0.12/api/v1/apps/Time/enabled -H "Content-Type: application/json" -d false
  ```
  대상: `Time`, `Date`, `Temperature`, `Humidity`, `Battery`. 다시 켜려면 `-d true`.
- 푸시 앱 `solar`는 시계가 재부팅되면 사라진다. 드라이버가 15초마다 다시 보내므로 곧 복구된다. 내장 앱 끄기 설정이 재부팅 뒤에도 유지되는지는 확인하지 못했다.
