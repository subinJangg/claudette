# Claude Code 작업 가이드

이 프로젝트의 컨벤션과 주의사항.

---

## 빌드 & 실행

```bash
./run.sh
```

코드 변경 후엔 항상 `./run.sh`로 빌드 통과 확인.

---

## 절대 하지 말 것

- 외부 의존성 추가 금지 (SwiftPM, CocoaPods 등). 표준 라이브러리만 사용.
- 하드코딩 컬러(hex) 금지. 시스템 컬러 사용 (다크 모드 자동 적응).
- `print()` 디버그 코드 커밋 금지.
- Force unwrap (`!`) 금지.
- 메인 스레드 블록 금지. API 호출은 `async/await`.
- `project.pbxproj` 직접 수정 금지. `project.yml` 수정 후 `xcodegen generate`.

---

## 컨벤션

### 코딩 스타일

- Swift 표준 스타일, 들여쓰기 4 spaces
- 한 파일에 한 주된 type

### 네이밍

- 타입: `PascalCase`, 변수/함수: `camelCase`
- 파일명 = 타입명

### 폴더 분류

- `Models/` — 데이터 타입
- `Services/` — API, 키체인, 비즈니스 로직
- `Views/` — SwiftUI 뷰
- `Settings/` — UserDefaults 래퍼

---

## 핵심 아키텍처

### 인증 흐름

1. `DesktopSessionReader` — Claude Desktop 쿠키 SQLite에서 암호화된 sessionKey 읽기
2. `SecItemCopyMatching`으로 키체인에서 복호화 비밀번호 가져오기
3. PBKDF2 + AES-128-CBC로 복호화 (Chromium v10 포맷, Chrome 146+ nonce 대응)
4. `CredentialsStore`가 sessionKey + orgId 캐싱

### 데이터 흐름

- `UsageService` → `claude.ai/api/organizations/{orgId}/usage` 호출
- `UsageSamples` — 사용량 샘플 수집, 선형 회귀로 한도 도달 시간 예측
- `NotificationService` — 임계치 도달 시 알림

### 주의사항

- 키체인 접근 시 `NSLock`으로 동시 호출 방지 (팝업 중복 방지)
- Chrome 146+ (Electron 41+)에서 v10 포맷에 nonce가 추가됨. CBC 복호화 후 `sk-ant` 패턴으로 세션키 추출.
- API 레이트 리밋: claude.ai는 여유로움. 사용자 설정 새로고침 간격 존중.

---

## 언어 정책

- UI 텍스트: 한국어
- 코드/주석: 자유롭게 한/영 혼용
