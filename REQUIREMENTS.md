# 요구사항

상태: 개발 요구와 상세 설계 연결. 아래 필수 범위는 설계 목표이며 구현/검증 완료 목록이 아니다.

## 제품의 목적

OnepLoom의 핵심은 조건부 하네스다. 작업의 성격과 위험에 따라 필요한 지침, 문서와 검증을 선택하고, 같은 프로젝트의 WIKI를 계속 참조/갱신하게 한다. 코드와 Git 이력에서 WIKI를 복원하는 기능은 기존 프로젝트가 이 구조를 도입하도록 돕는 필수 제공 기능이다. 신규 프로젝트에서 근거 없는 과거 WIKI를 먼저 생성하도록 요구하지 않는다.

## 첫 배포의 필수 범위

| 영역 | 요구 |
| --- | --- |
| 도입 | 기존 프로젝트와 신규 프로젝트에 필요한 구조를 설치하고 프로젝트 값에 연결한다. 기존 AGENTS, skill, hook과 사용자 문서를 보존한다. |
| 조건부 실행 | 간단한 요청은 최소 맥락으로 처리하고 실제 변경/위험에 필요한 검사만 연다. 필요한 검사 생략으로 비용을 줄이지 않는다. |
| WIKI 연결 | 프로젝트 내부 또는 별도 로컬 Git WIKI를 연결한다. 외부 경로와 개인 실행 선택은 작업 사본별 로컬 기록에 둔다. |
| 평소 사용 | oneploom 또는 oneploom start로 연결된 Codex를 연 뒤 평소 요청으로 작업한다. 기존 충분한 권한의 Codex 사용도 유지한다. |
| 상세 복원 | 코드, 커밋과 제공된 기록을 근거로 요구, 구조, 계약, 결정과 변경 흐름을 상세히 생성/보강한다. 사실, 추론, 미확인을 구분한다. |
| 반복 실행 | 완료된 복원 범위에 같은 요청이 오면 기존 근거/결과와 현재 변경을 대조하고 필요한 보강을 제안한다. 기존 문서를 자동 덮지 않는다. |
| 검증 | 변경에 관련된 검사, 확대 조건과 필수 CI를 구분하고 실패한 검사를 다른 성공 검사로 바꾸지 않는다. |
| 복구 | 세션 문맥 복구와 설치/기능 작업 재개를 구분한다. 중단된 외부 효과를 확인한 뒤 안전하게 이어 간다. |
| 업데이트 | 공식 배포 변경과 사용자 수정의 충돌을 검사한다. 실패 시 재시도 또는 이번 업데이트 전체를 이전 구성으로 복원/검증하는 선택을 지원한다. |
| 원격 연계 | 첫 범위는 GitHub 코드 저장소 하나와 WIKI 저장소 하나의 PR 생성/재사용/연결/상태 검사다. 승인/병합은 사람이 맡는다. |
| 안내 | 배포 README의 필수 준비물과 실제 명령만으로 설치, 기기별 연결, 사용과 실패 대응을 따라갈 수 있어야 한다. |

## 지원과 배포

첫 제품 지원은 Windows의 로컬 프로젝트/WIKI, Git, Python과 Codex다. Codex는 공식 npm 설치와 공식 Windows 설치를 지원 대상으로 하며 특정 관측 버전을 제품 고정값으로 삼지 않는다. 정확한 Python/OS/설치 조합은 구현 후보에서 확인해 공개한다.

Git Release + Python 관리 도구로 제공하고, 사용자별 시작 명령은 공식 배포 자료의 wheel과 격리 환경으로 준비한다. 프로젝트에는 편집 가능한 하네스 적용본을 두며, 기기 실행 환경이나 wheel을 프로젝트 Git에 기본 포함하지 않는다. 공식 버전 발행은 배포 원본에서 관리한다.

## 사용자 자료와 권한

- 설치/변경 전에 실제 대상과 영향 범위를 확인한다. 필요한 선택만 요구하며 같은 유효 조건의 승인/경로를 반복 입력하게 하지 않는다.
- Codex 전역 설정, 인증, 모델과 셸 보안 정책을 임의 변경하지 않는다. 호스트나 조직 정책의 제한, 만료와 실제 권한은 별도로 확인한다.
- 공유 파일에 기기별 WIKI 절대 경로를 넣지 않는다. 로컬 상태는 코드 작업 공간의 .harness 아래에 두고 전체 폴더를 Git에서 제외한다.
- 비밀번호, 토큰, API 키와 개인키를 문서/예시/로그/커밋에 남기지 않는다. 삭제된 문서나 읽지 못한 근거를 확인 완료로 처리하지 않는다.
- 기존 사용자 수정, 다른 작업과 저장소를 덮지 않는다. 후보 결과와 실제 원본의 현재성을 대조한 뒤 요청한 범위만 반영한다.

## 선택 기능과 후속 범위

첫 선택 기능은 설명/학습 문서 확장이다. 최초 설치 때 또는 나중에 추가할 수 있어야 한다. 커밋 보조, MCP, 로컬 AI 보조, 다른 AI 플랫폼과 WSL/Linux 제품 지원은 후속 검토다. 후속 기능을 선행 조건으로 추가하거나 필수 상세 복원 목표를 축소하지 않는다.

## 품질과 완료

작업 단위로 정상, 입력 경계, 누락, 오류, 취소/중단, 재시도, 기존 변경 보존과 실제 사용을 검증한다. 테스트 개수나 커버리지의 보편적 숫자를 합격 기준으로 삼지 않는다. 토큰, 시간과 유지보수 비용은 품질이 같은 조건에서 비교하고 미측정 효과를 성과로 적지 않는다.

필수 기능과 설치/갱신/복구 및 실행 안내가 실제 배포 환경에서 검증된 상태를 첫 정식 배포 기준으로 삼는다. [검증 계획](verification/README.md)의 미완료 항목을 남기고 기능 일부가 동작했다는 이유로 전체 배포 완료를 선언하지 않는다.

## 상세 요구와 검증 연결

| 요구 묶음 | 상세 계약 | 판단과 검증 |
| --- | --- | --- |
| 조건부 실행과 검증 | [검증 계약](design/workflow/verification.md) | [검증 ADR](decisions/README.md), [수용 입력](verification/acceptance.md) |
| 연결/선택/명령 | [실행](design/runtime/entry.md), [프로젝트 목록](design/runtime/project-selection.md), [인계](design/runtime/project-entry.md) | [설치 도구 토의](discussions/runtime/distribution.md) |
| 설치/갱신/기기 관리 | [설치](design/runtime/install.md), [갱신](design/runtime/update.md), [관리](design/runtime/management.md) | [역사적 대안](discussions/history/install.md) |
| 복원/문서/위치표 | [WIKI](design/knowledge/wiki.md), [문서](design/knowledge/documents.md), [위치표](design/knowledge/map.md) | [품질과 실행 토의](discussions/knowledge/reconstruction.md) |
| 상태/재개/정리 | [복구](design/workflow/recovery.md), [기록](design/workflow/records.md), [저장](design/workflow/storage.md), [유지 관리](design/workflow/maintenance.md) | [SQL 초안](design/workflow/schema.sql), [수용 입력](verification/acceptance.md) |
| 코드/WIKI 연계 | [동기화](design/sync.md) | [작업 연계 결정](decisions/integration/0017-work-sync.md) |
| 후속 AI/연결 | [로컬 보조](design/integration/local-ai.md), [MCP](design/integration/mcp.md) | [도구 토의](discussions/integration/ai-tools.md), [비교 사례](evidence/cases/mcp-cost.md) |
