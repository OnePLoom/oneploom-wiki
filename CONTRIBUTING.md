# WIKI 기여 안내

## 작업 위치와 작성 순서

OnepLoom의 요구사항, 설계, 토의, ADR과 검증 근거를 이 저장소에서 관리한다. 문서 내용의 기준은 [development/documentation.md](development/documentation.md), 브랜치, 커밋과 코드/WIKI PR 연계의 공통 기준은 [코드 저장소 CONTRIBUTING.md](https://github.com/OnePLoom/oneploom/blob/main/CONTRIBUTING.md)가 소유한다.

문서만의 작업은 이 저장소에 이슈를 등록한다. 제품 코드도 바뀌는 작업은 [코드 저장소의 이슈](https://github.com/OnePLoom/oneploom/issues)에 공통 범위를 적고 같은 이슈에 두 PR을 연결한다. 이미 같은 작업이 있으면 해당 이슈를 재사용한다.

## 공개 이슈 템플릿

GitHub의 New issue에서 해당 양식을 선택하고 문서 경로, 정확한 섹션 제목과 필요한 근거를 적는다. 선택 항목에 정보가 없으면 `_No response_`로 남길 수 있다.

| 작업 | 템플릿 |
| --- | --- |
| 문서 추가와 수정 | [docs.md](.github/ISSUE_TEMPLATE/docs.md) |
| 문서와 설계의 개선 제안 | [feature.md](.github/ISSUE_TEMPLATE/feature.md) |
| 문서 오류 제보 | [bug.md](.github/ISSUE_TEMPLATE/bug.md) |
| 확인한 오류의 수정 계획 | [fix.md](.github/ISSUE_TEMPLATE/fix.md) |
| 의미를 유지하는 구조 정리 | [refactor.md](.github/ISSUE_TEMPLATE/refactor.md) |
| 문서 관리와 운영 정리 | [chore.md](.github/ISSUE_TEMPLATE/chore.md) |
| 질문과 도움 | [help.md](.github/ISSUE_TEMPLATE/help.md) |

## PR 작성과 확인

기본 양식은 [.github/pull_request_template.md](.github/pull_request_template.md)다. Part는 Wiki로 두고, 변경한 문서와 결정, 근거, 문서 검증을 작성한다. 코드 변경의 상세는 상대 PR에 두고 실제 링크로 연결한다.

요구사항과 설계의 의미, 결정 상태, 파일 링크와 섹션 제목을 대조한다. 실제 확인한 항목만 체크하고 중요한 미실행이나 실패는 이유를 적는다. 문서 작업에 코드 실행 테스트를 수행했다고 표시하지 않는다. 이슈/PR과 관련 메타데이터는 관리자가 확인하며 작성 양식만으로 Project 등록이나 병합이 자동 실행되지는 않는다.

템플릿은 기본 브랜치에 병합된 뒤 GitHub 새 작성 화면에 적용된다. 기존 이슈/PR의 본문은 자동으로 바뀌지 않는다. CLI/API로 본문을 직접 작성하는 경우에도 공개 양식을 기준으로 내용을 채운다.

## 개발 검사

코드와 WIKI의 CI 범위, 환경 선택 이유와 실제 검증 상태는 [development/ci.md](development/ci.md)에서 확인한다. Windows에서 Git과 Node.js 22 계열을 준비한 뒤 저장소 루트에서 실행한다. 이 도구는 WIKI 개발용이며 제품 실행 의존성이 아니다.

```powershell
npm ci --ignore-scripts --no-audit --no-fund
npm test
npm run check:links
```

PowerShell에서 `npm.ps1` 실행 정책 오류가 나면 위 명령의 `npm`을 `npm.cmd`로 바꾼다. 전역 실행 정책을 바꿀 필요는 없다. 잠금 파일을 바꾸지 않는 평소 검사에는 `npm install` 대신 `npm ci`를 사용한다. `node_modules`는 Git에 올리지 않는다.

검사 대상은 Git이 공유하는 Markdown과 ignore되지 않은 새 문서다. 없는 파일/제목, 대소문자 오류와 저장소 밖 연결을 실패로 처리한다. 외부 URL에는 접속하지 않는다. 출력의 제목 원문 일치 수는 제목 존재 확인이며 GitHub와 Obsidian의 클릭 동작이 같다는 보장은 아니다. 자세한 지원 문법과 한계는 위 CI 문서의 「검사 범위와 실패 처리」를 따른다.

문서의 의미와 요구사항 대조는 자동 링크 검사와 별도로 유지한다. 현재 workflow는 작성 단계이며 실제 GitHub 성공과 필수 검사 등록은 아직 확인 전이다.
