# 디자인 시스템

앱 UI 의 시각적 일관성을 위한 토큰, 컴포넌트, 패턴 정의서.
브랜드 정체성/톤은 `BRANDING.md`, 기능 명세는 `SPEC.md` 참고.

---

## 1. 디자인 원칙

1. **System-native first** — 가능한 한 macOS 시스템 컬러/폰트/컴포넌트 사용. 다크 모드 자동 대응.
2. **Quiet by default** — 항상 메뉴바에 떠 있는 도구. 시선을 빼앗지 않음.
3. **Information density, not visual density** — 정보는 많이, 시각적 요소는 적게.
4. **One screen, one action** — popover 안에서 시선 흐름이 자연스러워야 함 (상단 → 하단).
5. **Accessibility first** — VoiceOver, Dynamic Type, 색상 외 시각 단서 등 기본 탑재.

---

## 2. 컬러 시스템

시스템 컬러를 최대한 활용 → 다크/라이트 모드 자동 적응. 임계값별 상태색만 hardcode.

### 2.1 시스템 컬러 (참조용 — 직접 hex 박지 말 것)

| 토큰 | SwiftUI 값 | 용도 |
|------|-----------|------|
| `text.primary` | `.primary` | 본문 텍스트 |
| `text.secondary` | `.secondary` | 보조 텍스트, 캡션 |
| `text.tertiary` | `Color(NSColor.tertiaryLabelColor)` | 흐릿한 메타 정보 |
| `background.window` | `Color(NSColor.windowBackgroundColor)` | popover 카드 배경 |
| `background.control` | `Color(NSColor.controlBackgroundColor)` | 입력 필드 배경 |
| `separator` | `Color(NSColor.separatorColor)` | 구분선 |

### 2.2 상태 컬러 (사용량 임계값)

`warningThresholdPercent` / `dangerThresholdPercent` (사용자 설정) 에 따라 동적 결정.

| 상태 | 조건 | 색 |
|------|------|----|
| `normal` | `0 ≤ x < warning` | `.green` (시스템) |
| `warning` | `warning ≤ x < danger` | `.orange` (시스템) |
| `danger` | `x ≥ danger` | `.red` (시스템) |
| `neutral` | 데이터 없음 / 미로그인 | `.secondary` |

색맹 사용자 배려 — 색만으로 의미 전달 X. 항상 아이콘 모양 또는 텍스트도 함께 변경.

### 2.3 액센트 컬러

브랜드 액센트는 시스템 `.accentColor` 사용. 사용자가 시스템 설정에서 액센트 컬러 바꾸면 자동 반영됨.

링크/주요 버튼: `.accentColor`

---

## 3. 타이포그래피

기본 폰트: **SF Pro** (시스템). 숫자는 가능한 **`monospacedDigit()`** 또는 `design: .rounded` 적용.

### 3.1 텍스트 스타일 카탈로그

| 스타일 | 사이즈 | weight | design | tracking | 용도 |
|--------|--------|--------|--------|----------|------|
| `eyebrow` | 10pt | `.medium` | `.default` | 0.6 | "CLAUDE.AI" 같은 라벨 |
| `title` | 14pt | `.medium` | `.default` | – | "Max plan" 헤더 |
| `subtitle` | 13pt | `.medium` | `.default` | – | 카드 제목 ("현재 세션", "주간 한도") |
| `body` | 12pt | `.regular` | `.default` | – | 모델 이름 등 본문 |
| `mega-number` | 20pt | `.semibold` | `.rounded` | – | 현재 세션 큰 퍼센트 |
| `inline-number` | 12pt | `.medium` | `.rounded` | – | 주간 행의 퍼센트 (tabular numerals) |
| `caption` | 11pt | `.regular` | `.default` | – | 리셋 시각, 마지막 업데이트 등 |
| `caption-bold` | 11pt | `.medium` | `.default` | – | 푸터 버튼 라벨 |
| `mono-snippet` | 11pt | `.regular` | `.monospaced` | – | sessionKey 입력 안내 등 |
| `onboarding-title` | 18pt | `.semibold` | `.default` | – | Onboarding 화면 제목 ("Claude.ai 에 연결") |

### 3.2 텍스트 컬러 매핑

- 메인 정보: `text.primary`
- 메타/보조: `text.secondary`
- 흐릿한 디테일: `text.tertiary`
- 강조/링크: `.accentColor`
- 상태 표현: 위 §2.2 의 상태 컬러

---

## 4. 스페이싱

8pt 그리드 기반. 미세 조정 시 4pt 단위까지 허용.

| 토큰 | 값 | 용도 |
|------|-----|------|
| `space.xs` | 4pt | 인라인 요소 사이 (icon + text) |
| `space.sm` | 6pt | 카드 내부 행 간격 |
| `space.md` | 8pt | 일반 컴포넌트 사이 |
| `space.lg` | 12pt | 카드 사이 |
| `space.xl` | 16pt | popover padding |
| `space.2xl` | 24pt | 섹션 간 큰 분리 |
| `space.3xl` | 32pt | onboarding 화면 padding |

### 4.1 popover 레이아웃

- 폭: 320pt 고정
- 외부 padding: 16pt
- 카드 사이 간격: 12pt
- 카드 내부 padding: 가로 14pt, 세로 12pt

---

## 5. 컴포넌트

### 5.1 Card

```swift
.padding(.horizontal, 14)
.padding(.vertical, 12)
.background(Color(NSColor.windowBackgroundColor))
.clipShape(RoundedRectangle(cornerRadius: 10))
```

용도: 정보 그룹화 (현재 세션, 주간 한도 등).

### 5.2 ProgressBar (커스텀)

| 사이즈 | height | radius | 용도 |
|--------|--------|--------|------|
| `large` | 6pt | 3pt | 현재 세션 카드 |
| `small` | 4pt | 2pt | 주간 한도 항목 행 |

레일 색: `Color.primary.opacity(0.08)`
채워진 색: 상태 컬러 (§2.2)
애니메이션: 값 변경 시 `withAnimation(.easeOut(duration: 0.4))`

```swift
GeometryReader { geo in
    ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.primary.opacity(0.08))
        RoundedRectangle(cornerRadius: height / 2)
            .fill(stateColor)
            .frame(width: max(0, min(1, value)) * geo.size.width)
    }
}
.frame(height: height)
```

### 5.3 Badge / Status Pill

popover 헤더 우측의 상태 뱃지.

```swift
Image(systemName: badgeIcon)
    .font(.system(size: 14))
    .foregroundStyle(stateColor)
    .frame(width: 28, height: 28)
    .background(stateColor.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 6))
```

### 5.4 Footer Button

```swift
Button { action } label: {
    Image(systemName: iconName)
        .font(.system(size: 12))
}
.buttonStyle(.plain)
.help(tooltipText)  // hover tooltip
```

푸터의 새로고침/설정/종료 버튼. 라벨 없이 아이콘만, hover 시 tooltip.

### 5.5 Primary Button (Onboarding CTA)

```swift
Button("Claude에 로그인") { action }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
```

크고 명확한 main action 용. Onboarding 외엔 안 씀.

### 5.6 Segmented Picker (설정)

새로고침 주기, 임계값 모드 선택 등.

```swift
Picker("", selection: $value) {
    ForEach(options, id: \.self) { Text($0) }
}
.pickerStyle(.segmented)
.labelsHidden()
```

---

## 6. 아이콘

**모든 아이콘은 SF Symbols** (외부 아이콘셋 사용 금지). macOS Sonoma+ 기준.

### 6.1 자주 쓰는 SF Symbol

| 용도 | Symbol |
|------|--------|
| 메뉴바 (normal) | `circle.fill` |
| 메뉴바 (warning) | `circle.lefthalf.filled` |
| 메뉴바 (danger) | `exclamationmark.circle.fill` |
| 메뉴바 (neutral/로딩) | `gauge.medium` |
| 새로고침 | `arrow.clockwise` |
| 설정 | `gear` |
| 종료 | `power` |
| 시계 (마지막 업데이트) | `clock` |
| 에러 | `exclamationmark.triangle.fill` |
| Onboarding 로고 | `gauge.high` |
| Snooze 활성 | `bell.slash.fill` |
| 차트 (v0.4) | `chart.xyaxis.line` |
| 카운트다운 모드 | `timer` |

### 6.2 아이콘 사이즈

| 위치 | 크기 |
|------|------|
| 메뉴바 라벨 | 시스템 자동 (height ~14pt) |
| 헤더 뱃지 | 14pt |
| 푸터 버튼 | 12pt |
| 인라인 (텍스트 옆) | 11pt |
| Onboarding 로고 | 64pt |

---

## 7. 레이아웃 패턴

### 7.1 Popover 구조

수직 스택, 위에서 아래로:

```
┌─────────────────────────┐
│  HeaderView             │  ← 플랜 정보 + 상태 뱃지
├─────────────────────────┤
│  SessionCard            │  ← 현재 세션 (큰 progress)
├─────────────────────────┤
│  WeeklyCard             │  ← 주간 한도 리스트
├─────────────────────────┤
│  PredictionView (v0.3)  │  ← 페이스 예측 (조건부 표시)
├─────────────────────────┤
│  FooterView             │  ← 마지막 업데이트 + 액션 버튼
└─────────────────────────┘
```

### 7.2 Onboarding 구조

수직 스택, 가운데 정렬:

```
┌─────────────────────────┐
│         (logo)          │
│   Claude.ai 에 연결      │
│   한 번만 로그인하면 됨   │
│                         │
│  [  Claude에 로그인  ]   │
│                         │
│   고급: sessionKey 입력  │  ← 작은 링크
└─────────────────────────┘
```

### 7.3 메뉴바 라벨

수평 스택, `space.xs` 간격:
- 좌: 상태 아이콘 (상태색)
- 우: 텍스트 (모드에 따라 `{session}%`, `RESET {N}m`, `{session}/{weekly}%` 등)

기본 모드 = `{icon} {session}%`
v0.5 부터 사용자가 템플릿 직접 정의 가능 (SPEC.md §8 v0.5)

---

## 8. 다크 모드

**전략**: 시스템 컬러 (`Color(NSColor.windowBackgroundColor)`, `.primary`, `.secondary` 등) 사용으로 자동 적응. hex 하드코드 금지.

검수 체크리스트:
- [ ] 모든 텍스트가 다크/라이트 모두에서 충분한 대비 (WCAG AA: 4.5:1)
- [ ] progress bar 의 레일이 양쪽 모드에서 보이는가
- [ ] 카드 배경이 popover 배경과 구분되는가
- [ ] 상태 컬러 (red/orange/green) 가 다크 모드에서도 채도가 적절한가

---

## 9. 애니메이션

**원칙**: 짧고 부드럽게. 사용자가 "움직임을 느끼지 못해도 만족도가 올라가는 정도".

| 시나리오 | 동작 | duration | curve |
|---------|------|----------|-------|
| Progress bar 값 변경 | width 보간 | 400ms | `.easeOut` |
| 새로고침 중 메뉴바 아이콘 | 360° 회전 반복 | 1.2s/회전 | `.linear` |
| Popover 등장 | scale 0.95 → 1.0 + opacity | 200ms | `.easeOut` |
| Popover 사라짐 | opacity 1 → 0 | 150ms | `.easeIn` |
| 상태색 전환 | color blend | 300ms | `.easeInOut` |
| 알림 아이콘 흔들기 (v0.3) | -8° / +8° 4회 | 600ms | spring (response 0.3, damping 0.4) |

`UIAccessibility.isReduceMotionEnabled` 가 true 면 모든 애니메이션 즉시 완료 (no-op).

---

## 10. 접근성 (a11y)

### 10.1 VoiceOver

모든 인터랙티브 요소에 명확한 label:

| 요소 | VoiceOver 텍스트 |
|------|-----------------|
| 메뉴바 아이콘 | "Claudette, 현재 세션 {N}%, 주간 {N}%. 클릭하여 상세 보기" |
| Progress bar | "{label}, {N}퍼센트 사용됨" |
| 새로고침 버튼 | "지금 새로고침" + hint: "사용량을 즉시 갱신합니다" |
| 설정 버튼 | "설정 열기" |
| 종료 버튼 | "Claudette 종료" |

### 10.2 키보드 네비게이션 (v0.2)

- Popover 열림 시 `Cmd+R`: 새로고침
- `Cmd+,`: 설정 열기
- `Cmd+Q`: 앱 종료
- Onboarding 의 "로그인" 버튼: 기본 키 (Enter)

### 10.3 Dynamic Type

대부분의 텍스트가 시스템 폰트 스타일 사용 → 사용자 폰트 크기 설정 자동 반영. 단, 메뉴바 라벨은 macOS 시스템이 강제하는 사이즈이므로 제외.

### 10.4 색맹 배려

상태 표현은 **색 + 아이콘 모양** 둘 다 변경 (§6.1). 빨강만으론 위험 신호 못 알아채는 사용자도 형상 차이로 인지 가능.

---

## 11. 사용자 정의 임계값과 UI 반영 (v0.2)

`warningThresholdPercent` / `dangerThresholdPercent` 가 변경되면 즉시:

1. 메뉴바 라벨의 아이콘/색상 재평가
2. 모든 progress bar 의 색상 재계산
3. 헤더 뱃지의 아이콘/색상 재평가
4. (v0.3) 알림 트리거 임계값 재설정

설정 화면에서 두 슬라이더 (warning 0~99, danger 50~100) + 그 옆에 미니 progress bar 미리보기. 슬라이더 끌면 미리보기 색이 실시간으로 바뀜.

---

## 12. 메뉴바 표시 템플릿 시스템 (v0.5)

### 12.1 사용 가능한 placeholder

| 토큰 | 의미 | 예시 출력 |
|------|------|-----------|
| `{icon}` | 상태 아이콘 (색 포함) | 🟢 / 🟡 / 🔴 |
| `{session}` | 현재 세션 % (숫자만) | `52` |
| `{session_label}` | "Session N%" | `Session 52%` |
| `{weekly}` | 주간 % (숫자만) | `8` |
| `{weekly_label}` | "Weekly N%" | `Weekly 8%` |
| `{reset}` | 세션 리셋까지 남은 시간 | `13m` / `1h 23m` |
| `{plan}` | 플랜 이름 | `Max` |
| 리터럴 문자 | 그대로 출력 | `· ` `%` `/` 등 |

### 12.2 기본 프리셋

```
{icon} {session}%                  ← 기본
{session}% / {weekly}%             ← 컴팩트
{icon} {session}% · {reset}        ← 풍부
{icon}                             ← 아이콘만
{plan} {session}%                  ← 플랜 강조
```

### 12.3 fallback 규칙

- 데이터 없음 (`null`) 인 placeholder 는 자체 + 인접한 separator 까지 제거
- 사용량 < warningThresholdPercent 일 때 `{reset}` 도 자동 숨김 (충분히 여유 있어 표시 의미 없음)
- 메뉴바 폭이 시스템 한계 (~12자) 넘으면 뒤쪽 placeholder 부터 잘림

---

## 13. 빈 상태 & 에러 상태

### 13.1 빈 상태

| 시나리오 | 표시 |
|---------|------|
| 로그인 안 됨 | Onboarding 화면 |
| 사용량 0% (오랜만에 들어옴) | "Claude 안 쓰고 계시네요. 평화롭네요 ☕️" (`BRANDING.md` §5.2) |
| 첫 로드 중 | Spinner + "불러오는 중..." |

### 13.2 에러 카드

```swift
VStack(alignment: .leading, spacing: 6) {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
        Text("문제 발생")
            .font(.system(size: 12, weight: .medium))
    }
    Text(message)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
}
.padding(.horizontal, 14)
.padding(.vertical, 12)
.background(Color.orange.opacity(0.08))
.clipShape(RoundedRectangle(cornerRadius: 10))
```

에러 메시지는 항상:
1. **무슨 일이 일어났는지** (객관적 사실)
2. **다음에 무엇이 일어날지** 또는 **사용자가 할 수 있는 일** 한 줄

---

## 14. 디자인 결정 로그

추후 결정 사항이 생기면 여기 누적:

- (2026-05) 초기 디자인 시스템 작성. 상태 컬러는 시스템 색 사용.
- (2026-05) Popover 폭 320pt 결정 (스크린샷의 claude.ai 사용량 페이지보다 좁지만, 메뉴바 앱 표준 폭과 일관).
