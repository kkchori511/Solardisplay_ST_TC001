# 프로젝트 현황과 이어가기 가이드

작성: 2026-10-18, 2026-10-19 갱신 (TC001 v1.2, 드라이버 v1.1 기준). 다음에 이어서 작업할 때 이 문서를 먼저 읽는다.
이 문서는 두 레포 전체를 다룬다. 드라이버 쪽 요약은 `Solardisplay_ST_Edgedriver/docs/PROJECT-STATUS.md`.

## 1. 한눈에 보기
집 태양광 출력을 **Ulanzi TC001 픽셀 시계**에 표시하고, 같은 시계에 **날씨(기상청)** 도 번갈아 보여준다.

```
시하스 PMM-300Z2 (태양광 계측, Zigbee)
        │
SmartThings 허브 (4층)  ── 엣지 드라이버 "Solar Power Meter TC001" ──(15초마다 HTTP PUT)──▶ TC001 시계 (AWTRIX NG)
                                                                                         ▲   │  solar 앱 (푸시, 50초)
                                                                  기상청 API ◀──(시계 스크립트가 직접 호출, 매시 50분)──┘   │  weather 앱 (스크립트, 10초)
```

| 레포 | 역할 | 버전 |
|---|---|---|
| `Solardisplay_ST_TC001` (공개) | 시계 쪽: 펌웨어 설치/설정, 시계 API, 날씨 스크립트(가운데 버튼=최저/최고), 아이콘, 문서 | v1.2 |
| `Solardisplay_ST_Edgedriver` | 허브 쪽: 엣지 드라이버(시계로 값 전송, 추가 정보, 월 누적) | v1.1 |

- GitHub 계정 `kkchori511`. 로컬: `~/projects/Solardisplay_ST_TC001`, `~/projects/Solardisplay_ST_Edgedriver`.
- 프로젝트 밖 보관(깃에 없음): `~/projects/backups/tc001_factory.bin`(시계 순정 펌웨어 4MB 백업, SHA-256 앞 16자 `837bd6329dae6b53`), `~/projects/firmware/`(AWTRIX NG 1.2.2 압축 해제본, SmartThings 공식 드라이버 일부).
- 사용자: 개발과 깃은 처음. 모든 소통은 한국어. **push는 매번 먼저 확인받고**, 되돌리기 어려운 작업(force push, 기기 드라이버 교체 등)도 확인받는다.

## 2. 현재 상태 (모두 동작 확인)
**시계 (192.168.0.12)**
- AWTRIX NG 1.2.2, 내장 앱(시간, 날짜, 온도, 습도, 배터리)은 모두 꺼 둠. 켜진 앱은 `solar`, `weather` 둘.
- 시간 배분: 태양광 **50초**, 날씨 **10초**. 태양광은 푸시 앱이라 시계 전체 기본(`appDurationMs=50000`)을 따르고, 날씨 스크립트가 `duration()`으로 10초를 정한다.
- 시간대 `KST-9`(기본은 유럽이라 바꿈). 호스트 이름 `tc001`, Wi-Fi `DaDa 2.4G`(2.4GHz만), 공유기에서 IP 고정. 신호가 약한 편(-80dBm대).
- **태양광 화면**: 번개 아이콘(노랑) + 숫자 + 초록 `W`(가운데 기둥을 위로 늘린 모양, 숫자와 2칸 간격) + 맨 아래 막대.
  - 숫자/막대 색: 100W 이하 회색, 1500W 이하 노랑, 3000W 이하 주황, 3000W 초과 빨강. 막대는 3200W에서 가득(넘으면 100% 고정).
  - 값은 허브 드라이버가 15초마다 `PUT /api/v1/apps/pushed/solar`로 보낸다 (`clock.lua`).
- **날씨 화면**: `[날씨 아이콘 8x8] 기온(주황) 우산(파랑, 4칸) 강수확률(파랑)`. `°`, `%`는 공간 때문에 뺌. 확률 100%는 99로 표시. 영하는 마이너스를 2칸 선으로 그림.
  - 기상청 초단기실황/예보(김포시 마산동, 격자 nx=54 ny=128)를 시계 스크립트(`scripts/weather.be`)가 **매시 50분**에 받음(실황 1회 + 예보 4회). 실패하면 5분 뒤 재시도, 3시간 넘게 못 받으면 화면에서 뺌.
  - 아이콘 선택 순서: 낙뢰 > 강수형태(비/소나기/빗방울/진눈깨비/눈, 비온뒤갬) > 하늘상태(맑음/구름많음/흐림, 맑은뒤흐림). 낮/밤은 일출/일몰 근사식.

**허브/드라이버**
- 태양광 발전기(PMM-300Z2) 1대만 우리 드라이버를 쓴다. 같은 모델인 "전기차 충전기", "전체 전기 모니터"는 기존 시하스 V3 드라이버 그대로.
- 드라이버는 SmartThings 공식 `zigbee-power-meter`의 포크. 추가한 것: 시계 전송, 전압/전류/주파수/역률/온도 표시(시하스 V3와 같은 정보), **월 누적 전력량**(매월 1일 0부터 다시 측정; 처음 켠 2026년 10월은 켠 시점 2026-10-18 13:17부터 셈).
- 앱의 컴포넌트: `main`(전력, 전압, 전류, 주파수, 역률, 온도, 총 누적 등) + `monthly`("월 누적 전력량").

## 3. 기기/계정 식별 정보 (비밀 아님)
| 항목 | 값 |
|---|---|
| 시계 | Ulanzi TC001, ESP32-D0WD 4MB, MAC `c8:85:41:0e:4d:9c`, USB 시리얼 `/dev/cu.usbserial-1240`(바뀔 수 있음, CH340) |
| 허브(4층 SmartThings Station) | `430d54dc-aa95-4727-b270-a1a42c107ea2`, LAN `192.168.0.118` |
| 태양광 발전기 기기 | `39007be1-bf1e-40b2-9f34-9c9d318a6ce9` (PMM-300Z2, Zigbee `00158D008BC88E92`) |
| 전기차 충전기 / 전체 전기 모니터 | `9eb02429-6219-46e5-be42-ffd8590ab028` / `939beaf1-e58d-4934-a023-526f8f98606d` (둘 다 PMM-300Z2, 기존 드라이버) |
| 내 채널(비공개) | `Solardisplay Drivers` `40607751-7843-4d32-98b8-a1945b4cbc33` |
| 내 드라이버 | `Solar Power Meter TC001` `471c3cca-991d-4a2d-b2d9-797c4e3dd7bb` (v1.1 배포 버전 `2026-10-18T13:22:20`), 프로필 `sihas-solar-monthly-v2` |
| 원래 쓰던 시하스 드라이버(되돌릴 때) | `SiHAS Zigbee Power Meter Consumption V3(PMM-300-Z)` `0c975ca0-7645-4a43-89f2-4c80575cad78` |

되돌리기: `smartthings edge:drivers:switch 39007be1-bf1e-40b2-9f34-9c9d318a6ce9 --hub 430d54dc-aa95-4727-b270-a1a42c107ea2 --driver 0c975ca0-7645-4a43-89f2-4c80575cad78`

## 4. 자주 쓰는 작업
도구: `gh`(brew), `esptool`(brew), `smartthings` CLI(**npm** `@smartthings/cli`, brew 탭은 신뢰 문제로 거부됨), `lua`(brew, 로컬 시험). SmartThings CLI는 처음 한 번 브라우저 로그인이 필요하다.

**시계**
- 태양광 값 직접 보내 보기: `scripts/send-solar.sh 2300` (드라이버가 15초 안에 실제 값으로 덮어씀)
- 날씨 스크립트 올리기/키 설정/표시시간 적용: `scripts/deploy-weather.sh` (인증키는 `.env.local`에서 읽음)
- 날씨 배치 미리보기: `scripts/preview-weather.sh -23 89` (임시 앱을 올렸다가 지움). 화면을 문자로 그리는 `scripts/show-screen.py`는 `curl -s http://192.168.0.12/api/v1/display/screen | python3 -I scripts/show-screen.py`
- 번개 아이콘 업로드: `scripts/upload-icon.sh` (시계를 다시 플래시하면 아이콘이 지워지니 번개와 날씨 아이콘을 다시 올린다. 날씨 아이콘은 `deploy-weather.sh`가 함께 올림)
- 시계 상태/로그: `curl http://192.168.0.12/api/v1/device`, `curl http://192.168.0.12/api/v1/logs`(스크립트 로그 포함)
- 앱 켜고 끄기: `curl -X PUT .../api/v1/apps/<이름>/enabled -H 'Content-Type: application/json' -d false`(본문은 객체가 아니라 `true`/`false` 값 자체)

**허브/드라이버** (드라이버 레포에서)
- 배포: `smartthings edge:drivers:package drivers/solar-power-meter --channel 40607751-7843-4d32-98b8-a1945b4cbc33 --hub 430d54dc-aa95-4727-b270-a1a42c107ea2` (배포 전 `git branch --show-current`로 어느 브랜치인지 확인)
- 허브 로그: `smartthings edge:drivers:logcat 471c3cca-991d-4a2d-b2d9-797c4e3dd7bb --hub-address 192.168.0.118` (처음 접속할 때 허브 인증서를 믿을지 묻는다. **사람이 직접 y**)
- 기기 값: `smartthings devices:status 39007be1-bf1e-40b2-9f34-9c9d318a6ce9`
- 로컬 시험: `cd drivers/solar-power-meter && lua ../../tests/test_monthly.lua` (자세한 건 `tests/README.md`)

**깃**
- `main`은 안정 버전만. 새 기능은 `git checkout -b <이름>`에서 작업 → 확인 후 `main`에 합치고 새 태그(v1.2 등). 합친 브랜치는 `git branch -d`로 삭제.
- 새로 클론하면 비밀 검사 훅을 다시 설치: `cp scripts/pre-commit-secrets.sh .git/hooks/pre-commit`.

## 5. 겪은 함정 (같은 실수를 안 하려고)
**시계(AWTRIX NG)**
- AWTRIX 3의 `POST /api/custom`은 NG에서 안 된다. NG는 `PUT /api/v1/apps/pushed/<이름>`. 푸시 앱은 시계가 재부팅하면 사라진다(드라이버가 계속 다시 보냄).
- 플래시는 **115200**으로만(921600은 중간에 멈춤). 부팅 직후 연결하면 부팅음이 멈추지 않으니 약 30초 기다렸다 접속.
- 아이콘: `icon`의 데이터 URL은 GIF/JPEG만(PNG는 `415`). 8x8 GIF를 `POST /api/v1/files?dir=/ICONS`로 올리고 이름(`bolt`)으로 쓴다.
- `draw` 명령은 아이콘을 무시하고 x=0 기준. 글자 한 자는 폭 3+간격 1(피치 4), `W`는 5칸. 푸시 앱의 `draw`는 `text` y=1이 위쪽 행, 스크립트의 `text()` y=6이 같은 위치.
- 화면(`/api/v1/display/screen`)을 읽을 때 앱 전환 효과(비 내리는 애니메이션)와 겹치면 엉뚱한 모양이 나온다 → 활성화 후 2초 기다린다.
- 스크립트(Berry): `return` 다음 줄에 식이 오면 그 식을 반환값으로 읽는다. 파이썬식 `a if c else b`는 없다. 응답은 8KB까지만 받아서 기상청 응답은 `find`/`keep`으로 항목별로 받는다.
- 시계에 앱을 연달아 설치하면 여유 메모리가 줄어 첫 요청이 `status=0`으로 실패할 수 있다(5분 뒤 재시도로 복구).
- 스크립트의 설정값(`kma_key`)은 같은 Wi-Fi에서 `GET /api/v1/apps/weather/config`로 읽힌다(인증 미사용 결정).

**SmartThings 엣지 드라이버**
- 허브의 드라이버 실행 환경은 **외부 인터넷 주소를 못 찾는다**(DNS 불가, HTTP/HTTPS 모두 실패). 날씨를 시계 스크립트로 옮긴 이유. LAN 안(시계)으로 보내는 건 된다.
- 소켓을 쓰려면 `config.yml`에 `permissions: lan: {}`가 필요(없으면 `Permission Denied`). 이미 올린 `packageKey`는 권한을 바꿀 수 없다(`Permissions have been modified`) → `packageKey`를 바꿔 새 드라이버로 올린다. 지금 `solar-power-meter-lan`.
- 기기를 다른 드라이버로 바꿀 때는 `init`이 다시 불리지 않을 수 있어 `driverSwitched`에서도 시작 코드를 부른다.
- 같은 프로필 이름으로 내용(이름표)만 바꿔 올려도 **이미 등록된 기기에는 반영되지 않는다.** 새 프로필 이름으로 올리면 코드가 기기를 한 번 옮긴다(`try_update_metadata`, 저장 필드 `profile_requested:<이름>`).
- 이 기기의 배율은 기기에게 직접 읽어 확인한 값이다(전압 ÷10, 전류 ÷100, 온도 ÷100, 누적 ÷1000, 주파수 ÷10). 자세한 표는 드라이버 레포 `docs/v3-info-notes.md`.
- SmartThings 이력(`devices:history`)은 약 7일만 보관. 300개 넘게 요청하면 대화형 확인 질문이 떠서 멈춘다.
- 허브 로그의 `received Zigbee message`에서 기기가 보내는 속성과 값을 읽을 수 있다. 읽기 요청을 보내 배율/지원 여부를 알아내는 방법이 유효했다.

**깃/비밀 정보**
- `git add -A`가 `.env.local`까지 올릴 수 있다. 무시 규칙이 **그 브랜치에** 있어야 한다. 한 번 실제로 키가 공개 레포에 올라갔다(아래 6번).
- 쉘이 zsh라 `--include=*.yml`처럼 따옴표 없는 패턴은 오류가 난다. `sleep` 길게 쓰기와 `return` 다음 줄 식(Berry)도 주의.

## 6. 비밀 정보 사고와 현재 보호 (2026-10-18)
- 기상청 인증키 파일(`.env.local`)이 TC001 레포 `main`(공개)의 v1.0 커밋에 들어가 push됐다. `main`을 키 없이 다시 만들어 덮어썼고(`3a3a43d` → `e8b19ed`) `v1.0` 태그도 다시 만들었다. 새 키를 발급받아 교체했다.
- **남은 점**: GitHub는 예전 커밋(`3a3a43d`)을 SHA 주소로는 아직 보여준다(제거는 GitHub 지원팀 요청만 가능). 재발급 후에도 **예전 키가 여전히 응답**했고, 사용자가 확인하지 않기로 했다(무료 공공 날씨 키라 위험이 작다고 판단). 마음이 바뀌면 data.go.kr에서 예전 키를 폐기한다.
- 현재 보호: 두 레포 `.gitignore`가 `.env*`, `*.local`, `kma_key.lua` 등을 막고, 커밋 직전 검사(`scripts/pre-commit-secrets.sh`)가 비밀 파일 이름과 키처럼 보이는 문자열을 막는다. **훅은 `.git/hooks`에 복사해야 켜진다**(클론마다 다시).
- 인증키는 `~/projects/Solardisplay_ST_TC001/.env.local`의 `KMA_SERVICE_KEY=` 한 줄뿐. 시계에는 `deploy-weather.sh`가 앱 설정값으로 넣는다. 레포, 채팅, 로그, 문서에 값을 적지 않는다.

## 7. 남은 일과 아이디어
**확인이 필요한 것**
1. **월 누적 전력량**: 해가 뜬 뒤 값이 오르는지, **2026-11-01 00시 이후 0으로 리셋되는지**(로컬 시험 36개는 통과, 실제 월 전환은 처음). 11월 리셋이 이상하면 `docs/v3-info-notes.md`의 로직(`monthly_next`)과 저장 필드(`monthly_key`, `monthly_base`, `monthly_last`)를 본다.
2. **날씨 아이콘**: 지금까지 맑음/구름 계열만 실제 날씨로 봤다. 비, 눈, 낙뢰, "비온뒤갬", "맑은뒤흐림"은 해당 날씨가 올 때 맞게 바뀌는지 확인.
3. 새 우산/아이콘 모양이 마음에 드는지(4칸 우산, 영하 마이너스가 아이콘에 1칸 간격으로 붙는지).

**하고 싶을 수 있는 것**
- 시계에 **월 누적 전력량 표시**(지금은 SmartThings 앱에서만 보임). 푸시 앱을 하나 더 만들거나 태양광 화면에 합치는 방식.
- 다른 전력량계(전기차 충전기, 전체 전기 모니터)도 시계에 표시: 같은 드라이버로 바꾸면 기기를 구분해서 앱 이름/값을 나눠야 함.
- V3의 설정 3개(CT 설치 방향, 소비/생산 누적 리셋)는 기기에 쓰는 속성 번호를 몰라 미구현. 생산(역방향) 누적(`SimpleMetering 0x0001`)은 기기가 지원하지만 CT 방향이 자동이라 0이어서 쓰지 않음.
- 안개 아이콘은 만들었지만 기상청 데이터에 안개 항목이 없어 쓰이지 않음.
- 날씨 스크립트의 키를 시계 설정이 아니라 다른 방식으로 보호(시계에 인증 켜기 → `clock.lua`와 스크립트에 인증 정보 필요).
- 시계 Wi-Fi 신호가 약하다. 전송이 잦게 끊기면 시계 위치를 조정.

## 8. 문서 지도
| 파일 | 내용 |
|---|---|
| `docs/PROJECT-STATUS.md` | 이 문서 |
| `docs/handoff-tc001-solar.md` | 처음 받은 핸드오프(계획 단계). 일부는 틀렸다: `/api/custom`, 허브 소스 위치 등. 참고만 |
| `docs/awtrix-ng-notes.md` | AWTRIX NG 조사(플래시, Wi-Fi, HTTP API), 작업 기록 |
| `docs/kma-weather-notes.md` | 기상청 API 시험, 시계 스크립트 구현, 배치 조정 기록, 시간 배분 |
| 드라이버 레포 `docs/v3-info-notes.md` | V3 정보 표시와 월 누적 전력량 구현, 기기에서 확인한 배율 |
| 드라이버 레포 `tests/README.md` | 로컬 시험 방법 |

## 9. 이어서 시작하는 순서 (제안)
1. 두 레포에서 `git status`, `git branch`로 상태 확인 (`main`, TC001 v1.2 / 드라이버 v1.1).
2. 시계와 허브가 살아 있는지: `curl http://192.168.0.12/api/v1/device`, `smartthings devices:status 39007be1-bf1e-40b2-9f34-9c9d318a6ce9`.
3. 7번의 확인 항목(특히 11월 1일 이후 월 누적)부터 본다.
4. 새 작업은 브랜치를 만들어서 시작한다.
