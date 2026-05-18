# Claudette

macOS 상단 메뉴바에서 Claude.ai 사용량을 실시간으로 확인할 수 있는 네이티브 앱입니다.

Claude Code 터미널을 여러 개 켜고 사용하다 보면 사용량 합산 확인이 어렵습니다. Claudette는 메뉴바에 항상 떠 있으면서 현재 세션과 주간 한도를 한눈에 보여줍니다.

> **macOS 14 (Sonoma) 이상** / **Claude Max 플랜** 사용자 대상

---

## 스크린샷

<!-- 스크린샷 추가 예정 -->

---

## 주요 기능

### 메뉴바 상시 표시
- 현재 세션 사용률을 메뉴바에 항상 표시
- 표시 모드 선택: 퍼센트(%) 또는 카운트다운(재설정까지 남은 시간)
- 아이콘 스타일 선택: 도넛 또는 배터리

### 상세 사용량 확인
- 메뉴바 클릭 시 팝오버로 상세 정보 표시
- **현재 세션**: 5시간 rolling 사용량 + 재설정까지 남은 시간
- **주간 한도**: 모델별(모든 모델, Sonnet, Claude Design 등) 7일 rolling 사용량

### 한도 도달 예측
- 최근 사용 추세를 선형 회귀로 분석하여 한도 도달 시점 예측
- 세션 리셋보다 예측이 길면 "이번 세션 한도 여유로움" 표시
- 세션 내 한도 도달이 예상되면 "약 N시간 N분 후 한도 도달 예상" 경고
- 예측 조건: 최소 샘플 3개, 최근 30분 내 5분 이상 간격, 사용량 0.5%p 이상 변화

### 알림
- 사용량 임계치 도달 시 macOS 알림 발송
- 임계치: 50%, 60%, 70%, 80%, 90% 중 중복 선택 가능 (기본값: 80%)
- 동시에 여러 임계치를 넘은 경우 가장 높은 값 하나만 알림
- 알림 일시정지(스누즈): 1시간 끄기 / 오늘 그만 / 이번 세션 끄기
- 스누즈 상태는 메인 화면과 설정에서 타입 + 만료 시각 확인 가능

### 설정
- **새로고침 주기**: 1분 / 3분 / 5분(기본) / 10분
- **메뉴바**: 아이콘 스타일, 표시 모드 선택
- **주간 한도 모델**: 표시할 모델 선택, 순서 변경, 숨기기 (API에서 동적 반영, 설정 유지)
- **알림**: on/off, 임계치 선택, 시스템 알림 권한 상태 안내, 스누즈 해제

---

## 설치

### DMG

1. `Claudette.dmg`를 열고 `Claudette.app`을 Applications로 드래그
2. 키체인 팝업이 뜨면 **"항상 허용"** 클릭 (최초 1회)

> 실행이 안 되는 경우 우클릭 → 열기 (서명되지 않은 앱)

### 전제 조건

- **Claude Desktop**이 설치되어 있고, 로그인된 상태여야 합니다
- Claudette는 Claude Desktop의 세션 쿠키를 복호화하여 사용량 API를 호출합니다
- 복호화를 위해 macOS 키체인 접근이 필요하며, "항상 허용"을 하지 않으면 실행할 때마다 팝업이 뜹니다

---

## 동작 원리

```
Claude Desktop (Cookies DB)
    ↓ SQLite에서 암호화된 sessionKey 읽기
macOS Keychain (Claude Safe Storage)
    ↓ PBKDF2 + AES-128-CBC 복호화 (Chromium v10 포맷)
sessionKey + orgId 추출
    ↓
claude.ai/api/organizations/{orgId}/usage API 호출
    ↓
세션(5시간) + 주간 사용량 파싱 & 표시
```

- Claude Desktop은 Chromium 기반(Electron)으로, 쿠키를 AES-128-CBC로 암호화하여 SQLite에 저장합니다
- 암호화 키는 macOS 키체인의 `Claude Safe Storage` 항목에 있습니다
- Chrome 146+ (Electron 41+)에서 추가된 nonce 포맷도 대응합니다

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
# Release 빌드
xcodebuild -project Claudette.xcodeproj -scheme Claudette -configuration Release build

# DMG 생성 (Applications 바로가기 포함)
mkdir -p /tmp/claudette-dmg
cp -R ~/Library/Developer/Xcode/DerivedData/Claudette-*/Build/Products/Release/Claudette.app /tmp/claudette-dmg/
ln -s /Applications /tmp/claudette-dmg/Applications
hdiutil create -volname "Claudette" -srcfolder /tmp/claudette-dmg -ov -format UDZO Claudette.dmg
```

---

## 프로젝트 구조

```
claudette/
├── project.yml                    ← XcodeGen 설정
├── run.sh                         ← 빌드 & 실행 스크립트
├── branding/icons/                ← 앱 아이콘 원본 (SVG, iconset, icns)
└── Claudette/
    ├── ClaudetteApp.swift         # @main, MenuBarExtra, 의존성 주입
    ├── Assets.xcassets/           # 앱 아이콘 (Asset Catalog)
    ├── Info.plist
    ├── Models/
    │   ├── UsageResponse.swift    # API 응답 파싱 (UsageData, UsageBucket)
    │   ├── UsageLevel.swift       # 상태 단계 (normal/warning/danger)
    │   └── UsageSamples.swift     # 사용량 샘플 수집 & 선형 회귀 예측
    ├── Services/
    │   ├── UsageService.swift     # API 호출 + 상태 관리 + 알림/샘플 트리거
    │   ├── CredentialsStore.swift # 세션키 + orgId 캐싱
    │   ├── DesktopSessionReader.swift  # Claude Desktop 쿠키 복호화
    │   ├── NotificationService.swift   # 임계치 알림 + 스누즈 + 시스템 권한
    │   └── ResetTimeFormatter.swift    # 재설정 시간 포맷
    ├── Views/
    │   ├── PopoverView.swift      # 메뉴바 클릭 시 메인 화면
    │   ├── SetupGuideView.swift   # 미연결 시 가이드
    │   ├── HeaderView.swift       # 플랜 + 상태 뱃지
    │   ├── SessionCard.swift      # 현재 세션 카드 + 한도 예측
    │   ├── WeeklyCard.swift       # 주간 한도 카드 (설정 기반 필터/순서)
    │   ├── WeeklyRow.swift        # 주간 행 (모델별)
    │   ├── ProgressBar.swift      # 커스텀 progress bar
    │   ├── FooterView.swift       # 마지막 업데이트 + 스누즈 상태 + 액션 버튼
    │   ├── ErrorCard.swift        # 에러 표시
    │   ├── MenuBarIconView.swift  # 도넛/배터리 아이콘
    │   └── SettingsView.swift     # 설정 (새로고침/메뉴바/주간모델/알림)
    └── Settings/
        └── AppSettings.swift      # UserDefaults 래퍼 + 모델 관리
```

---

## 기술 스택

| 항목 | 선택 | 비고 |
|------|------|------|
| 언어 | Swift 5.9 | |
| UI | SwiftUI (`MenuBarExtra`) | macOS 14+ 표준 메뉴바 API |
| 최소 OS | macOS 14 (Sonoma) | |
| 외부 의존성 | 없음 | Foundation, Security, SQLite3, CommonCrypto만 사용 |
| 프로젝트 생성 | XcodeGen | `project.yml` → `.xcodeproj` |
| 쿠키 복호화 | PBKDF2 + AES-128-CBC | Chromium v10 포맷 + Chrome 146+ nonce 대응 |

---

## 라이선스

MIT
