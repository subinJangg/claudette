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

톱니바퀴 아이콘 클릭 → 시트(sheet) 등장. 포함 내용:
- 새로고침 주기 선택
- "Claude.ai 재로그인" 버튼
- "로그아웃" 버튼

### 3.6 에러 처리

- 로그인 안 됨 → onboarding 화면
- HTTP 401/403 → "세션 만료. 재로그인 필요" + 버튼
- HTTP 5xx 또는 네트워크 오류 → "claude.ai 접속 불가. 잠시 후 재시도"
- 응답 파싱 실패 → "응답 형식이 바뀌었습니다"

에러 UI 패턴은 `DESIGN.md` §13 참고.

### 3.7 Onboarding & 로그인 플로우 ⭐

**v0.1 MVP 의 핵심.** 사용자가 터미널이나 DevTools 만질 일 없이 한 번의 로그인으로 끝나도록 함.

#### 첫 실행 흐름

1. 앱 실행 → 저장된 세션 없음 감지
2. 메뉴바 아이콘 클릭 시 popover 대신 **Onboarding 화면** 표시
3. "Claude에 로그인" 큰 버튼 + 보조 텍스트
4. 클릭 → `NSWindow` + `WKWebView` 에 `https://claude.ai/login` 로드
5. 사용자가 평소처럼 로그인 (Google SSO 등 무관)
6. 로그인 성공 감지 → `WKHTTPCookieStore` 에서 `sessionKey` 추출
7. `GET /api/organizations` 로 `org_id` 가져옴 → Keychain 에 저장
8. Onboarding 창 닫고 popover 로 전환

#### Fallback: 수동 sessionKey 붙여넣기

Onboarding 화면 하단 "고급: sessionKey 직접 입력" 링크 → 회사 SSO 환경 등 WKWebView 로그인이 막힐 때 대비.

#### 재로그인

- 세션 만료 (HTTP 401/403) → popover 에 "재로그인" 버튼 표시 → 클릭 시 WKWebView 다시 띄움
- 설정의 "로그아웃" → Keychain + cookie store 클리어 → onboarding 복귀

---

## 4. API 명세

### 4.1 인증

`sessionKey` 쿠키를 HTTP 헤더에 실음.

```
Cookie: sessionKey=sk-ant-sid01-...
```

WKWebView 로그인 후 `WKHTTPCookieStore` 에서 자동 추출.

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
| `useFallbackFileStorage` | `Bool` | `false` | v0.1 |
| `warningThresholdPercent` | `Int` | `50` | v0.2 |
| `dangerThresholdPercent` | `Int` | `80` | v0.2 |
| `menuBarDisplayMode` | `String` (`percent`/`countdown`/`auto`) | `auto` | v0.2 |
| `predictionEnabled` | `Bool` | `true` | v0.3 |
| `predictionWindowMinutes` | `Int` | `30` | v0.3 |
| `snoozeUntil` | `Date?` | `nil` | v0.3 |
| `notificationThresholds` | `[Int]` | `[80]` | v0.3 |
| `menuBarTemplate` | `String` | `"{icon} {session}%"` | v0.5 |

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

- [ ] 메뉴바 아이콘 애니메이션 (새로고침 중 회전)
- [ ] Popover 등장 / 사라짐 애니메이션
- [ ] 키보드 단축키 (`Cmd+R`, `Cmd+,`)
- [ ] VoiceOver 접근성 라벨
- [ ] 다국어 (한국어 / 영어)
- [ ] Claude Desktop 앱 쿠키 자동 감지
- [ ] **사용자 정의 색상 임계값** — 두 슬라이더 (warning / danger), 미리보기 progress bar 실시간 반영
- [ ] **세션 종료 카운트다운 모드** — 사용량 80% 이상일 때 메뉴바를 `🔴 RESET 13m` 으로 자동 전환. "항상 퍼센트 / 항상 카운트다운 / 자동" 세 모드

### v0.3 — 알림 & 예측

- [ ] 임계값 도달 시 macOS notification
- [ ] 임계값 커스터마이즈 (예: 80%, 95%)
- [ ] 알림 빈도 제한
- [ ] 한도 임박 시 메뉴바 아이콘 흔들기
- [ ] **사용 속도 예측** — 최근 30분 추세를 선형 외삽 → "현재 페이스로 약 47분 후 한도 도달"
  - 데이터: 60분 ring buffer, 30초 간격 (120 samples)
  - 알고리즘: linear regression on (timestamp, utilization)
  - 표시 조건: 최근 5분 안에 1%p+ 증가했을 때만
  - Popover 세션 카드 하단 + 예측 알림 발송
- [ ] **알림 Snooze** — "1시간 끄기 / 오늘 그만 / 이번 세션 끄기" 액션
  - `UNNotificationAction` 옵션 첨부
  - `snoozeUntil: Date?` 를 UserDefaults 에 저장
  - 만료 시각 도달하면 자동 해제
  - Snooze 중에는 popover 푸터에 "🔕 알림 일시정지 중 (HH:MM 까지)"

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
