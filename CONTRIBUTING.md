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

코드와 WIKI의 CI 범위, 환경 선택 이유와 실제 검증 상태는 [development/ci.md](development/ci.md)에서 확인한다. 현재 WIKI 내부 링크 검사는 후속 구현 단계이며, 아직 실행 가능한 명령이나 필수 검사로 안내하지 않는다. 문서의 의미와 요구사항 대조는 자동 링크 검사와 별도로 유지한다.
