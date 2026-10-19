# Solardisplay_ST_TC001

**현재 버전: v1.2** (**이어가기 가이드: [docs/PROJECT-STATUS.md](docs/PROJECT-STATUS.md)**) — AWTRIX NG 설치, 시간대/메뉴 설정, 태양광 값 표시(번개, 구간별 색, 막대), 날씨 표시(기상청 초단기, 시계 스크립트), 가운데 버튼으로 오늘 최저/최고 기온 보기까지 완성한 안정 버전.

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

## 버전과 브랜치 규칙
- `main`: 안정 버전만 둔다. 현재 **v1.2** (git 태그 `v1.2`, 이전 `v1.1`, `v1.0`).
- 새 기능은 브랜치에서 작업한다. 예: `weather`(날씨 표시, v1.1에 합침), `weather-minmax`(최저/최고 기온, v1.2에 합침).
- 충분히 확인한 뒤에만 `main`에 합치고, 합칠 때 새 버전 태그를 붙인다.
- 브랜치 목록: `git branch`, 이동: `git checkout <이름>`, 새로 만들기: `git checkout -b <이름>`.

## 비밀 정보 보호
- 인증키는 `.env.local`에만 둔다. `.gitignore`가 `.env*`, `*.local`을 막는다.
- 커밋 직전 검사: `scripts/pre-commit-secrets.sh`를 `.git/hooks/pre-commit`에 복사해 설치한다 (`cp scripts/pre-commit-secrets.sh .git/hooks/pre-commit`). 비밀 파일 이름이나 키처럼 보이는 문자열이 있으면 커밋을 막는다. 새로 클론하면 다시 설치해야 한다.

## 날씨 표시 (v1.1) / 최저·최고 기온 (v1.2)
- 시계 스크립트(`scripts/weather.be`)가 기상청 초단기 날씨(김포시 마산동)를 매시 50분에 받아 아이콘, 기온, 우산, 강수확률을 표시한다.
- 표시 시간: 태양광 50초, 날씨 10초. 올리기: `scripts/deploy-weather.sh` (인증키는 `.env.local`에서 읽는다). 자세한 내용: [docs/kma-weather-notes.md](docs/kma-weather-notes.md)
