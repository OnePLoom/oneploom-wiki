# 결정 기록

결정의 전체 번호와 최초 날짜를 보존한다. 현재 상태, 대안과 변경 이유는 각 ADR이 소유한다. proposed/부분 채택/대체/accepted를 구현 또는 검증 완료와 혼동하지 않는다.

## 상태를 읽는 방법

`accepted`는 그 문서에 명시한 설계 방향을 채택했다는 뜻이다. 구현 완료, 테스트 통과나 PR 승인을 뜻하지 않는다. `proposed`는 아직 선택이 끝나지 않은 안, `superseded`는 후속 결정으로 대체된 과거 결정이다. 부분 채택 문서는 적용할 범위와 남은 선택을 본문에서 나눈다. [ADR 원문의 상태 정의](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions)와 [MADR의 결정/확인 구분](https://adr.github.io/madr/)을 따른다.

2026-11-24에 기존 합의와 본문을 대조해 상태를 정리했다. 새 안을 일괄 승인한 것이 아니다. 이후 MIT 적용 결정 0025를 추가해 현재 25개 중 채택 22개, 부분 채택 1개, 제안 1개, 대체 1개다.

| 구분 | 해당 결정 | 남은 내용 |
| --- | --- | --- |
| 부분 채택 | [0004](architecture/0004-portability.md) | 문서 역할/위치 연결은 채택. 자동 탐지, 보정과 초기화의 상세 처리 방식은 더 구체화해야 함 |
| 도입 판단 보류 | [0006](integration/0006-local-assist.md) | 로컬 AI의 품질, 재검토/재시도를 포함한 전체 비용을 비교한 뒤 채택 여부 결정. 첫 배포 필수 기능 아님 |
| 후속 결정으로 대체 | [0013](runtime/0013-platform-history.md) | 초기 WSL 우선안의 이력. 현재 환경은 [0020 Windows 우선](runtime/0020-windows.md) |
| 채택 후 구현/검증 대기 | 나머지 채택 결정 | 방향은 정해졌지만 각 ADR에 적힌 제품 구현, 실제 환경 검사와 세부 계약 작업은 별도로 남음 |

구현 중 새로운 정책 선택이나 기존 결정의 변경이 필요하면 근거와 영향 범위를 확인해 다시 결정한다. 구현 전이라는 이유만으로 채택된 방향 전체를 `proposed`로 표시하지 않는다.

## 번호와 분류

현재 번호는 **이 WIKI 전체에서 부여한 결정 식별자**다. 폴더 안의 순번이 아니다. 예를 들어 0003은 workflow, 0004는 architecture, 0005는 다시 workflow에 있으므로 한 폴더에서만 보면 번호가 건너뛴다. 아래 전체 목록에는 0001부터 0025까지 누락이나 중복이 없다.

architecture는 구조와 이식, development는 개발 운영, integration은 연계, knowledge는 WIKI 지식, runtime은 설치와 실행, workflow는 검증과 복구 결정을 모은다. 이 분류와 전체 번호순 목록을 함께 사용한다.

## 전체 번호순 목록

| 번호 | 결정 | 설계 상태 |
| --- | --- | --- |
| 0001 | [ADR 0001 — 최초 검증과 재시도의 동일성](workflow/0001-verification-identity.md) | `accepted` |
| 0002 | [ADR 0002 — PASS 재사용의 책임과 조건](workflow/0002-pass-validity.md) | `accepted` |
| 0003 | [ADR 0003 — 계획, 비활성 상태와 실행 결과의 구분](workflow/0003-plan-and-result.md) | `accepted` |
| 0004 | [ADR 0004 — 프로젝트 종속성 분리와 근거 기반 초기화](architecture/0004-portability.md) | 부분 `accepted` |
| 0005 | [ADR 0005 — 검증 대상 선택과 실행 재사용의 분리](workflow/0005-verification-selection.md) | `accepted` |
| 0006 | [ADR 0006: 로컬 AI의 첫 적용 범위](integration/0006-local-assist.md) | `proposed` |
| 0007 | [ADR 0007: 첫 배포 범위와 기술 검토 실증](architecture/0007-release-scope.md) | `accepted` |
| 0008 | [ADR 0008: 배포에 필요한 문서 범위](knowledge/0008-document-scope.md) | `accepted` |
| 0009 | [ADR 0009: 모듈 원본과 적용 프로젝트 분리](architecture/0009-repositories.md) | `accepted` |
| 0010 | [ADR 0010: 모듈 배포와 설치 방식](runtime/0010-distribution.md) | `accepted` |
| 0011 | [ADR 0011: 기존 문서와 기록 보존](runtime/0011-preservation.md) | `accepted` |
| 0012 | [ADR 0012: 개발 브랜치와 통합 기준](development/0012-branches.md) | `accepted` |
| 0013 | [ADR 0013: 첫 실행 환경과 프로젝트 위치](runtime/0013-platform-history.md) | `superseded` |
| 0014 | [ADR 0014: 필수 기반과 선택 기능](knowledge/0014-features.md) | `accepted` |
| 0015 | [ADR 0015: AI 도구 지원 범위](integration/0015-agent-support.md) | `accepted` |
| 0016 | [ADR 0016: WIKI 저장과 편집](knowledge/0016-storage.md) | `accepted` |
| 0017 | [ADR 0017: 앱과 WIKI의 작업별 버전 연결](integration/0017-work-sync.md) | `accepted` |
| 0018 | [ADR 0018: WIKI 분석의 실행 방식](knowledge/0018-reconstruction.md) | `accepted` |
| 0019 | [ADR 0019: 하네스 실행 구성의 프로젝트 내 설치](runtime/0019-project-install.md) | `accepted` |
| 0020 | [ADR 0020: Windows 직접 실행 우선](runtime/0020-windows.md) | `accepted` |
| 0021 | [ADR 0021: 복구 기록의 저장 수단](workflow/0021-recovery-storage.md) | `accepted` |
| 0022 | [ADR 0022: WIKI 연결의 기본 진입](runtime/0022-wiki-entry.md) | `accepted` |
| 0023 | [ADR 0023: Python 표준 규격을 이용한 기기 명령 등록](runtime/0023-command-registration.md) | `accepted` |
| 0024 | [ADR 0024: 현재 프로젝트 우선과 실행별 프로젝트 선택](runtime/0024-project-selection.md) | `accepted` |
| 0025 | [ADR 0025: 코드와 개발 WIKI의 MIT 라이선스](development/0025-license.md) | `accepted` |

[토의](../discussions/README.md)에서 검토 근거를, [검증 기록](../evidence/README.md)에서 실제 확인 범위와 한계를 찾는다.
