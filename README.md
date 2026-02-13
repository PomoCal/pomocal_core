# 🍎 PomoCal (Core)

> **"집중의 기록을 자동화하다"**

PomoCal은 집중하는 시간조차 기록으로 남기고 싶은 '완벽주의자'들을 위한 macOS 네이티브 앱입니다.  
타이머를 마치는 순간, 당신의 집중 시간은 Apple 캘린더에 하나의 '이벤트'로 자동 기록됩니다.

[**공식 웹사이트**](https://pomocal.github.io/)

---

### ✨ 주요 기능

- **Calendar Sync**: `EventKit`을 통해 집중 세션이 종료되면 설정된 캘린더(iCloud 등)에 자동으로 일정이 생성됩니다.
- **Book Integration**: Naver Books API를 연동하여, 단순히 '공부'가 아닌 '어떤 책'을 보았는지 정확하게 기록할 수 있습니다.
- **Task Management**: 할 일 목록과 뽀모도로 타이머를 유기적으로 연결하여 관리합니다.
- **Native Experience**: SwiftUI로 개발되어 macOS 환경에 최적화된 퍼포먼스와 UI를 제공합니다.
- **Privacy First**: 별도의 외부 서버를 사용하지 않습니다. 모든 데이터는 사용자의 로컬 환경과 iCloud 내에서만 처리됩니다.

### 🛠 Tech Stack & Requirements

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum OS**: macOS 13.0 (Ventura) 이상
- **Main APIs**:
  - `EventKit`: 캘린더 읽기/쓰기 및 자동 동기화
  - `Combine`: 상태 관리 및 비동기 이벤트 처리
  - `Naver Search API`: 도서 정보 검색

### 🏗 빌드 및 실행 방법

이 프로젝트는 Swift Package Manager(SPM)를 기반으로 구성되어 있습니다.

1. **저장소 클론**
   ```bash
   git clone [https://github.com/PomoCal/pomocal_core.git](https://github.com/PomoCal/pomocal_core.git)
   cd pomocal_core
   ```

2. **의존성 확인 및 빌드**
   ```bash
   swift build
   ```

3. **앱 번들(.app) 및 DMG 생성**
   루트 폴더에 포함된 쉘 스크립트를 사용하여 직접 빌드하고 배포용 파일을 만들 수 있습니다.
   ```bash
   chmod +x create_app_bundle.sh
   ./create_app_bundle.sh
   ```

### 📝 프로젝트 구조

- `Sources/`: 앱의 메인 로직과 UI 컴포넌트
  - `CalendarManager.swift`: 캘린더 연동 및 이벤트 생성 로직
  - `BookAPIManager.swift`: 네이버 도서 검색 API 처리
  - `TimerManager.swift`: 뽀모도로 타이머 엔진
- `Entitlements.plist`: 캘린더 접근 권한 등 Sandbox 설정
- `create_app_bundle.sh`: macOS 앱 패키징 스크립트

---
*직접 쓰려고 만든 앱이라 부족한 점이 있을 수 있습니다. 개선 제안은 언제나 환영합니다!*