# 이 레포에서 작업할 때 (Claude용)

먼저 읽기: `docs/PROJECT-STATUS.md` (두 레포 전체 현황, 기기 ID, 명령어, 함정, 남은 일).

- 사용자는 개발/깃 초보, 모든 소통은 한국어. **push, force push, 기기 드라이버 교체는 먼저 확인받는다.**
- `main`은 안정 버전(현재 v1.1)만. 새 기능은 브랜치에서 작업, 확인 후 합치고 태그, 합친 브랜치는 삭제.
- **이 레포는 공개다. 비밀 정보를 커밋하거나 출력하지 않는다.** 기상청 키는 `.env.local`(깃 무시)의 `KMA_SERVICE_KEY` 한 줄뿐. 새로 클론하면 `cp scripts/pre-commit-secrets.sh .git/hooks/pre-commit`. 값 비교는 해시로만 한다.
- 시계는 `192.168.0.12`. 화면은 `scripts/preview-weather.sh`와 `scripts/show-screen.py`로 실제 시계에서 확인한다 (앱 전환 효과 때문에 활성화 후 2초 대기).
- 드라이버 쪽 작업은 `~/projects/Solardisplay_ST_Edgedriver`.
