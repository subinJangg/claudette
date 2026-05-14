# Claudette

macOS 메뉴바에서 Claude.ai 사용량을 실시간으로 확인하는 앱.

> **타깃**: macOS 14 (Sonoma) 이상 / Claude Max 플랜 사용자

---

## 주요 기능

- 메뉴바에 현재 세션 사용률 항상 표시 (퍼센트 / 카운트다운)
- 클릭 시 세션 + 주간 한도 상세 확인
- 한도 도달 예측 (선형 회귀 기반)
- 임계치 도달 시 알림 (80% 등 사용자 설정)
- 알림 일시정지 (1시간 / 오늘 / 이번 세션)
- 메뉴바 아이콘 스타일 선택 (도넛 / 배터리)
- 자동 새로고침 (1분 ~ 10분, 사용자 선택)

---

## 설치

### DMG (배포)

1. `Claudette.dmg`를 열고 `Claudette.app`을 Applications로 드래그
2. 처음 실행 시 **우클릭 → 열기** (서명되지 않은 앱)
3. 키체인 팝업이 뜨면 **"항상 허용"** 클릭 (최초 1회)

### 전제 조건

- **Claude Desktop**이 설치되어 있고, 로그인된 상태여야 합니다
- Claudette는 Claude Desktop의 세션 쿠키를 읽어서 사용량 API를 호출합니다

---

## 빌드 & 실행 (개발)

```bash
# XcodeGen 필요
brew install xcodegen

# 빌드 & 실행
./run.sh
```

`run.sh`가 자동으로:
1. 기존 실행 중인 앱 종료
2. `xcodegen generate`로 프로젝트 생성
3. `xcodebuild`로 빌드
4. 빌드된 `.app` 실행

### DMG 만들기

```bash
xcodebuild -project Claudette.xcodeproj -scheme Claudette -configuration Release build
hdiutil create -volname "Claudette" -srcfolder ~/Library/Developer/Xcode/DerivedData/Claudette-*/Build/Products/Release/Claudette.app -ov -format UDZO Claudette.dmg
```

---

## 프로젝트 구조

```
claudette/
├── project.yml                    ← XcodeGen 설정
├── run.sh                         ← 빌드 & 실행 스크립트
└── Claudette/
    ├── ClaudetteApp.swift         # @main, MenuBarExtra
    ├── Info.plist
    ├── Models/
    │   ├── UsageResponse.swift    # API 응답 파싱 (UsageData, UsageBucket)
    │   ├── UsageLevel.swift       # 상태 단계 (normal/warning/danger)
    │   └── UsageSamples.swift     # 사용량 샘플 수집 & 한도 예측
    ├── Services/
    │   ├── UsageService.swift     # API 호출 + 상태 관리
    │   ├── CredentialsStore.swift # 세션키 + orgId 캐싱
    │   ├── DesktopSessionReader.swift  # Claude Desktop 쿠키 복호화
    │   ├── NotificationService.swift   # 임계치 알림
    │   └── ResetTimeFormatter.swift    # 재설정 시간 포맷
    ├── Views/
    │   ├── PopoverView.swift      # 메뉴바 클릭 시 메인 화면
    │   ├── SetupGuideView.swift   # 미연결 시 가이드
    │   ├── HeaderView.swift       # 플랜 + 상태 뱃지
    │   ├── SessionCard.swift      # 현재 세션 카드
    │   ├── WeeklyCard.swift       # 주간 한도 카드
    │   ├── WeeklyRow.swift        # 주간 행 (모델별)
    │   ├── ProgressBar.swift      # 커스텀 progress bar
    │   ├── FooterView.swift       # 마지막 업데이트 + 액션 버튼
    │   ├── ErrorCard.swift        # 에러 표시
    │   ├── MenuBarIconView.swift  # 도넛/배터리 아이콘
    │   └── SettingsView.swift     # 설정 화면
    └── Settings/
        └── AppSettings.swift      # UserDefaults 래퍼
```

---

## 동작 원리

1. Claude Desktop의 Cookies DB (`~/Library/Application Support/Claude/Cookies`)에서 암호화된 `sessionKey` 읽기
2. 키체인에서 `Claude Safe Storage` 비밀번호 가져오기 (`SecItemCopyMatching`)
3. PBKDF2 + AES-128-CBC로 세션키 복호화 (Chromium v10 포맷)
4. `claude.ai/api/organizations/{orgId}/usage` API 호출
5. 세션(5시간) + 주간 사용량 파싱 & 표시

---

## 기술 스택

- **Swift 5.9** / **SwiftUI** (`MenuBarExtra`)
- **macOS 14+** (Sonoma)
- **외부 라이브러리 없음** — Foundation, Security, SQLite3, CommonCrypto만 사용
- **XcodeGen** for project generation

---

## 라이선스

MIT
