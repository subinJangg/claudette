# Claudette — 기획안

macOS 상단 메뉴바에 상주하면서 Claude.ai 사용량을 실시간으로 보여주는 네이티브 앱.

> **관련 문서**
> - 📄 `SPEC.md` (이 문서) — 무엇을 만들지: 기능, 기술 스택, API, 로드맵
> - 🎨 `BRANDING.md` — 정체성: 이름, 톤, 보이스, 로고 컨셉, 브랜드 컬러
> - 🧩 `DESIGN.md` — UI 디자인 시스템: 컬러 토큰, 컴포넌트, 레이아웃, 애니메이션, 접근성

---

## 1. 배경 & 목표

### 문제

Claude Max 플랜을 쓰다 보면 "지금 내가 한도 얼만큼 썼지?" 가 궁금한데, 매번 claude.ai → 설정 → 사용량 페이지에 들어가서 확인해야 함. 한 번 들어가면 깊이 5단계.

### 목표

상단 메뉴바에 항상 떠 있어서 한눈에 확인 가능하고, 클릭하면 더 자세한 정보가 나오는 가벼운 네이티브 앱. **외부 의존성 없이 자체 완결적으로 동작.**

### 비목표 (Non-goals)

- 사용량을 줄여주거나 제한 거는 기능 → 단순 모니터링 앱
- Windows/Linux 지원 → macOS 전용
- Claude Code 사용량 추적 → 본 앱은 claude.ai (웹/데스크탑) 사용량만 다룸

### 타깃 사용자

Claude Max 플랜 사용 중인 macOS 사용자. 작업 중 한도 임박 여부를 자주 체크하고 싶은 사람.

---

## 2. 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| 언어 | Swift 5.9+ | macOS 네이티브, 작은 번들 |
| UI | SwiftUI (`MenuBarExtra`) | macOS 14+ 표준 메뉴바 API |
| 로그인 | `WKWebView` + `WKHTTPCookieStore` | 진짜 Safari 엔진, 봇 감지 안 걸림 |
| 최소 OS | macOS 14 (Sonoma) | `MenuBarExtra` 요구사항 |
| 외부 의존성 | 없음 | URLSession, WebKit, Codable 모두 표준 |
| 빌드 | Xcode 15+ | |
| 배포 | `.app` 번들 → `.dmg` | 추후 단계 |

---

## 3. 핵심 기능 (MVP, v0.1)

### 3.1 메뉴바 상태 표시

상단 메뉴바 우측에 아이콘 + 현재 세션 사용률을 항상 표시.

예시:
- `🟢 24%` (저사용)
- `🟡 58%` (중간)
- `🔴 85%` (한도 임박)

색상 임계값 (사용자가 v0.2 부터 변경 가능):
- **0 ~ 49%**: 초록
- **50 ~ 79%**: 주황
- **80 ~ 100%**: 빨강

자세한 컬러 토큰은 `DESIGN.md` §2 참고.

### 3.2 Popover 상세 화면

메뉴바 아이콘 클릭 시 나타나는 카드형 UI. 폭 320pt.

구성 (위에서 아래로):
1. **헤더**: "CLAUDE.AI / Max plan" + 상태 아이콘
2. **현재 세션 카드**: 큰 퍼센트 + Progress bar + "N분 후 재설정"
3. **주간 한도 카드**: 헤더 + 재설정 시각 + 모델별 항목 리스트
4. **푸터**: 마지막 업데이트 + 새로고침 / 설정 / 종료 버튼

레이아웃 / 타이포 디테일은 `DESIGN.md` §3-§7 참고.

### 3.3 자동 새로고침

설정에서 주기 선택 가능: 30초, 1분, 3분, **5분 (기본)**, 10분, 30분.
설정 변경 즉시 새 주기 적용.

### 3.4 수동 새로고침

푸터의 새로고침 버튼 → 즉시 API 호출. 호출 중에는 비활성화.

### 3.5 설정창

톱니바퀴 아이콘 클릭 → 인라인 설정 화면. 포함 내용:
- 새로고침 주기 선택 (1분 / 3분 / 5분 / 10분)
- 메뉴바 아이콘 스타일 (도넛 / 배터리)
- 메뉴바 표시 모드 (퍼센트 / 카운트다운)
- 주간 한도 모델 표시/숨김/순서 변경
- 알림 on/off + 임계치 선택 (50~90%, 중복 가능) + 스누즈 상태 표시

### 3.6 에러 처리

- 로그인 안 됨 → onboarding 화면
- HTTP 401/403 → "세션 만료. 재로그인 필요" + 버튼
- HTTP 5xx 또는 네트워크 오류 → "claude.ai 접속 불가. 잠시 후 재시도"
- 응답 파싱 실패 → "응답 형식이 바뀌었습니다"

에러 UI 패턴은 `DESIGN.md` §13 참고.

### 3.7 인증 플로우

**Claude Desktop 쿠키 자동 감지 방식.** 사용자가 별도 로그인할 필요 없음.

#### 동작 흐름

1. 앱 실행 → `DesktopSessionReader`가 Claude Desktop의 Cookies DB에서 암호화된 `sessionKey` 읽기
2. 키체인에서 `Claude Safe Storage` 비밀번호로 복호화 (PBKDF2 + AES-128-CBC, Chromium v10)
3. `sessionKey` + `orgId` 추출 → `CredentialsStore`에 캐싱
4. 세션 유효 → 사용량 표시 시작

#### 미연결 시

- Claude Desktop이 없거나 로그인 안 된 상태 → SetupGuideView 표시
- 세션 만료 (HTTP 401/403) → 에러 카드 + "다시 확인" 버튼

---

## 4. API 명세

### 4.1 인증

`sessionKey` 쿠키를 HTTP 헤더에 실음.

```
Cookie: sessionKey=sk-ant-sid01-...
```

Claude Desktop의 Cookies DB에서 자동 추출 (Chromium v10 암호화 포맷, Chrome 146+ nonce 대응).

### 4.2 엔드포인트

```
GET https://claude.ai/api/organizations            # org_id 조회
GET https://claude.ai/api/organizations/{org_id}/usage   # 사용량 조회
```

`org_id` = `/api/organizations` 응답의 `[0].uuid`.

### 4.3 응답 구조 (`/usage`)

```json
{
  "five_hour": {
    "utilization": 83.0,
    "resets_at": "2026-05-13T05:40:00.571478+00:00"
  },
  "seven_day": {
    "utilization": 8.0,
    "resets_at": "2026-05-20T01:00:00.571499+00:00"
  },
  "seven_day_sonnet": { "utilization": 0.0, "resets_at": null },
  "seven_day_opus": null,
  "seven_day_haiku": null,
  "seven_day_omelette": { "utilization": 0.0, "resets_at": null },
  "seven_day_cowork": null,
  "extra_usage": {
    "is_enabled": false,
    "monthly_limit": null,
    "used_credits": null,
    "utilization": null
  }
}
```

### 4.4 필드 의미

| 키 | 한국어 표시명 | 설명 |
|----|--------------|------|
| `five_hour` | 현재 세션 | 5시간 rolling 사용량 |
| `seven_day` | 모든 모델 | 7일 rolling 전체 |
| `seven_day_sonnet` | Sonnet만 | Sonnet 한정 |
| `seven_day_opus` | Opus만 | Opus 한정 |
| `seven_day_haiku` | Haiku만 | Haiku 한정 |
| `seven_day_omelette` | Claude Design | 내부 코드명 → "Claude Design" |
| `seven_day_cowork` | Cowork | Cowork 모드 |
| `extra_usage` | 추가 사용량 | 유료 크레딧 (MVP 비표시) |

`null` 키는 화면에 표시 안 함. 미래 호환성: 모르는 `seven_day_*` 키는 `seven_day_foo_bar` → `Foo Bar` 자동 변환.

### 4.5 시간 파싱

`resets_at` 은 ISO 8601. 현재 시각과의 차이로:
- 1일+: "N일 N시간 후 재설정"
- 1시간+: "N시간 N분 후 재설정"
- 1시간-: "N분 후 재설정"
- 0이하: "곧 재설정"

---

## 5. 데이터 저장

### 5.1 인증 정보

**기본**: macOS Keychain.

- Service: `com.{your-handle}.pulse`
- Account: `claude.ai`
- Value (JSON):
```json
{
  "session_key": "sk-ant-sid01-...",
  "org_id": "uuid-..."
}
```

**Fallback**: `~/.config/claude-usage/config.json` (퍼미션 `0600`).

### 5.2 사용자 설정 (Preferences)

`UserDefaults` (`@AppStorage`).

| 키 | 타입 | 기본값 | 도입 버전 |
|----|------|--------|----------|
| `refreshIntervalSeconds` | `Int` | `300` | v0.1 |
| `menuBarDisplayMode` | `String` (`percent`/`countdown`) | `percent` | v0.1 |
| `menuBarIconStyle` | `String` (`donut`/`battery`) | `donut` | v0.1 |
| `notificationsEnabled` | `Bool` | `false` | v0.2 |
| `notificationThresholds` | `[Int]` | `[80]` | v0.2 |
| `notifiedThresholds` | `[Int]` | `[]` | v0.2 |
| `lastSessionResetId` | `String?` | `nil` | v0.2 |
| `snoozeUntilTimestamp` | `Double` | `0` | v0.2 |
| `snoozeDurationType` | `String?` | `nil` | v0.2 |
| `weeklyModelOrder` | `[String]` | `[]` (API에서 자동) | v0.2 |
| `hiddenWeeklyModels` | `[String]` | `[]` | v0.2 |

### 5.3 WKWebView 쿠키 저장소

별도 `WKWebsiteDataStore` (앱 격리). 사용자의 Safari 쿠키와 분리됨.

---

## 6. UI/UX 개요

자세한 디자인 시스템은 `DESIGN.md` 참고. 여기서는 SPEC 수준의 개요만:

- **Popover 폭**: 320pt 고정
- **카드 모서리**: 10pt radius, 배경 `Color(NSColor.windowBackgroundColor)`
- **상태색**: 시스템 컬러 (`.green`/`.orange`/`.red`) 자동 다크 모드 적응
- **타이포**: SF Pro 시스템 폰트, 숫자는 monospaced digit
- **아이콘**: 전부 SF Symbols (외부 아이콘셋 없음)

---

## 7. 파일 구조 제안

```
ClaudeUsageMenuBar/
├── ClaudeUsageMenuBarApp.swift   # @main App entry
├── Models/
│   ├── UsageResponse.swift       # Codable types
│   └── Credentials.swift         # session_key + org_id
├── Services/
│   ├── UsageService.swift        # API 호출 + 상태 관리
│   ├── CredentialsStore.swift    # Keychain 읽기/쓰기
│   ├── LoginCoordinator.swift    # WKWebView 로그인 흐름
│   └── ResetTimeFormatter.swift  # 시간 차이 포맷
├── Views/
│   ├── MenuBarLabel.swift
│   ├── PopoverView.swift
│   ├── OnboardingView.swift
│   ├── LoginWebView.swift        # NSViewRepresentable wrapper
│   ├── ManualKeyInputView.swift
│   ├── HeaderView.swift
│   ├── SessionCard.swift
│   ├── WeeklyCard.swift
│   ├── ProgressBar.swift
│   ├── FooterView.swift
│   ├── ErrorCard.swift
│   └── SettingsView.swift
├── Settings/
│   └── AppSettings.swift         # @AppStorage 래퍼
└── Info.plist                    # LSUIElement = YES
```

### Info.plist 핵심
```xml
<key>LSUIElement</key>
<true/>
```
→ Dock 아이콘 숨김, 메뉴바 전용.

---

## 8. 로드맵

### v0.1 — MVP

- [x] WKWebView 인앱 로그인 (메인)
- [x] 수동 sessionKey 붙여넣기 (fallback)
- [x] Keychain 저장
- [x] `GET /api/organizations/{org_id}/usage` 호출
- [x] 메뉴바 상태 표시
- [x] Popover 상세 (세션 + 주간)
- [x] 자동 + 수동 새로고침
- [x] 설정창 (주기 변경)
- [x] 에러 표시
- [x] 재로그인 / 로그아웃
- [x] 종료 버튼

### v0.2 — 폴리싱 & 커스터마이징

- [x] 메뉴바 아이콘 애니메이션 (새로고침 중 회전)
- [ ] Popover 등장 / 사라짐 애니메이션
- [ ] 키보드 단축키 (`Cmd+R`, `Cmd+,`)
- [x] VoiceOver 접근성 라벨
- [ ] 다국어 (한국어 / 영어)
- [x] Claude Desktop 앱 쿠키 자동 감지
- [ ] **사용자 정의 색상 임계값** — 두 슬라이더 (warning / danger), 미리보기 progress bar 실시간 반영
- [x] **세션 종료 카운트다운 모드** — 퍼센트 / 카운트다운 전환
- [x] **메뉴바 아이콘 스타일** — 도넛 / 배터리 선택
- [x] **주간 한도 모델 필터/순서** — 설정에서 표시할 모델 선택 + 순서 변경 (API 동적 반영)

### v0.3 — 알림 & 예측

- [x] 임계값 도달 시 macOS notification
- [x] 임계값 커스터마이즈 (50~90%, 중복 선택 가능)
- [x] 알림 중복 방지 (동시 여러 임계치 초과 시 최고값만 발송)
- [x] 시스템 알림 권한 체크 + 안내 UI
- [ ] 한도 임박 시 메뉴바 아이콘 흔들기
- [x] **사용 속도 예측** — 선형 회귀 기반 한도 도달 시간 예측
- [x] **알림 Snooze** — "1시간 끄기 / 오늘 그만 / 이번 세션 끄기" 액션
  - `UNNotificationAction` 커스텀 액션
  - 스누즈 타입 + 만료 시각 UserDefaults 저장
  - 만료 시각 도달하면 자동 해제
  - 메인 화면 + 설정에서 스누즈 타입/시각 표시 + 해제 버튼
- [x] **앱 아이콘** — 라벤더 펄스 디자인 (Asset Catalog)

### v0.4 — 히스토리

- [ ] 일/주별 사용량 추이 그래프 (Swift Charts)
- [ ] CoreData 또는 SQLite 로컬 저장
- [ ] Popover 안에 mini chart
- [ ] CSV 내보내기

### v0.5 — 편의 기능

- [ ] 시스템 로그인 시 자동 시작 (`SMAppService.mainApp.register`)
- [ ] **메뉴바 표시 템플릿 (placeholder 시스템)** — `{icon}`, `{session}`, `{weekly}`, `{reset}`, `{plan}` 등 placeholder. 설정창에 textfield + 실시간 미리보기. 프리셋 드롭다운도 제공. 자세한 placeholder 명세는 `DESIGN.md` §12.
- [ ] 플랜 자동 감지
- [ ] 다중 계정 지원

### v1.0 — 배포

- [ ] App Sandbox 활성화
- [ ] Code signing
- [ ] Notarization
- [ ] `.dmg` 패키징
- [ ] GitHub Releases / Homebrew Cask
- [ ] README + 스크린샷

---

## 9. 결정해야 할 것들

### 9.1 플랜 이름 표시

`/usage` 응답에 플랜 정보 없음 → `/api/organizations` 의 `settings` 또는 `subscription` 필드 별도 조회 필요.

**임시 (v0.1)**: 헤더에 "Max plan" 하드코딩. v0.5 자동 감지.

### 9.2 정확한 omelette 매핑

`seven_day_omelette` = claude.ai UI 의 "Claude Design". 향후 키 추가 가능성 있음.

**결정**: 알려진 매핑 + 모르는 키는 자동 변환 fallback.

### 9.3 WKWebView 로그인 성공 감지 방법

옵션:
- a) URL 변화 감지 (`/login` → 다른 곳)
- b) sessionKey 쿠키 존재 감지 (polling)
- c) "완료" 버튼 명시적 클릭

**결정**: (b) 우선. 1초마다 cookie store 체크, sessionKey 발견 시 자동 닫힘. SSO 리다이렉트로 URL 이 여러 번 바뀌어 (a)는 불안정.

### 9.4 알림 임계값 기본값 (v0.3)

80% 한 번? 80% + 95% 두 번?

**결정 보류**: v0.3 진입 시 사용자 피드백.

### 9.5 히스토리 보관 기간 (v0.4)

영구? 30일? 90일?

**결정 보류**: v0.4 설계 시.

---

## 10. 부록

### 10.1 WKWebView 로그인 구현 노트

```swift
let dataStore = WKWebsiteDataStore.default()
let config = WKWebViewConfiguration()
config.websiteDataStore = dataStore
let webView = WKWebView(frame: .zero, configuration: config)
webView.load(URLRequest(url: URL(string: "https://claude.ai/login")!))

// 쿠키 polling
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    dataStore.httpCookieStore.getAllCookies { cookies in
        if let session = cookies.first(where: { $0.name == "sessionKey" }) {
            CredentialsStore.save(sessionKey: session.value)
            closeWindow()
        }
    }
}
```

### 10.2 Keychain 접근 예제

```swift
struct CredentialsStore {
    static let service = "com.yourname.pulse"
    static let account = "claude.ai"

    static func save(_ json: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: json
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
}
```

### 10.3 sessionKey 수동 추출 안내 (앱 안 ManualKeyInputView 용)

1. 브라우저에서 https://claude.ai 로그인
2. `F12` → Application 탭 (Chrome) / 저장 공간 탭 (Safari)
3. Cookies → `https://claude.ai`
4. `sessionKey` 항목 Value 복사
5. 앱에 붙여넣기

### 10.4 MenuBarExtra 가이드

Apple 공식: https://developer.apple.com/documentation/swiftui/menubarextra
- `.menuBarExtraStyle(.window)` 로 popover 스타일

---

## 11. 빌드 & 실행

```bash
open ClaudeUsageMenuBar.xcodeproj
# Cmd+R
```

첫 실행:
- 메뉴바 우측 아이콘 등장
- 클릭 → Onboarding → "Claude에 로그인" → WKWebView 로그인
- 자동으로 사용량 표시 시작

Dock 미표시 (`LSUIElement = YES`).
