# Solardisplay_ST_TC001

Ulanzi TC001 픽셀 시계에 SmartThings 태양광 출력(W)을 표시하기 위한 시계(펌웨어) 쪽 작업 레포.

## 구성
- 시계: Ulanzi TC001 + AWTRIX NG 펌웨어
- 태양광 계측: 시하스 PMM-300Z2 (SmartThings 허브에 엣지 드라이버로 연결)
- 짝 레포: [Solardisplay_ST_Edgedriver](https://github.com/kkchori511/Solardisplay_ST_Edgedriver) (허브 → 시계 전송)

## 진행 순서
1. [ ] 순정 펌웨어 백업 (`tc001_factory.bin`, 레포에는 올리지 않음)
2. [ ] AWTRIX NG 플래시
3. [ ] 시계 Wi-Fi 연결, 공유기에서 IP 고정
4. [ ] curl로 시계 API 테스트 (`scripts/`)

자세한 내용은 [docs/handoff-tc001-solar.md](docs/handoff-tc001-solar.md) 참고.
