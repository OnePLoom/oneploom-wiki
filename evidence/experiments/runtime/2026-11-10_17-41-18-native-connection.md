# 외부 설치본의 Codex 연결 관측

> 검토와 관측 기록. 검토 당시의 후보와 관측을 보존한다. 현재 채택 범위는 결정 목록에서 확인하며, 미실행 계획이나 예비 시험을 제품 검증 완료로 해석하지 않는다.

사용자 작업일: 2026-11-10. 설치 [최소 검증 4 — 「B안의 최소 검증」](../../../design/runtime/install.md)에 해당한다. 기존 Git/Python 14개 검사를 반복하지 않고 Codex 발견, 신뢰, 이벤트 경계를 추가로 확인했다.

## 입력과 실행 경계

- WSL Linux, Codex CLI 0.167.0, 별도 임시 Codex 상태와 두 예제 Git 프로젝트를 사용했다. 실제 기존 시험 프로젝트, 사용자 전역 설정은 변경하지 않았다.
- 공통 소스의 두 실제 commit을 외부 `store/<commit>`에 두고 각 프로젝트의 `.agents/skills` 링크와 `.codex/hooks.json`으로 연결했다. 상대 경로/기기별 설정의 최종 제품 인터페이스를 채택한 것은 아니다.
- 같은 이름의 skill 본문, 배포본을 구별하는 hook, 서로 다른 프로젝트 이름, 내부/외부 WIKI를 입력으로 사용했다. 기능 검증에는 합성 입력을 사용했다.
- `plan.json`은 실행 전 조건이다. `fixture.json`, `input/`, `source.bundle`, `source/`, `schema/`에 재현 입력, 프로토콜, 코드를 보존했다. 설치 도구나 배포 후보 코드가 아니다.
- 실제 계정 인증을 복사하지 않았다. 연결 불가능한 `127.0.0.1:0` provider에만 요청하고 명시적으로 중단했다. 로컬 연결 시도, Codex 초기화와 실제 AI 추론을 구별하며 이 기록의 실제 모델 추론은 0회다.

## 관측 결과

`summary.json`의 17개 대조 항목은 모두 예상 관측과 일치했다. 판정은 `PASS_WITH_ENVIRONMENT_LIMIT`이며 중첩 sandbox의 native 시간 초과가 해소됐다는 뜻은 아니다.

| 대상 | 결과와 근거 |
| --- | --- |
| 두 프로젝트의 skill | `before-project-trust/`: 루트, 하위 폴더에서 각자 선택한 commit의 skill 하나를 발견 |
| 프로젝트 신뢰 | `before-project-trust/`, `after-project-trust/`: 프로젝트 hook 부재 → 발견되지만 개별 `untrusted` |
| native 시작, 재개 | `native-outside-sandbox/`, `native-resume-outside/`: 같은 시험 세션을 새 프로세스에서 재개. 각각 정확히 한 hook 완료, 정확한 프로젝트/WIKI 기록 |
| 다른 프로젝트 | `native-beta-outside/`: 두 번째 프로젝트의 배포본과 외부 WIKI를 읽고 native 완료 |
| A 갱신 | `after-alpha-update/`: A skill은 새 commit, A hook은 `modified`, B는 기존 경로, 신뢰 유지 |
| 재신뢰 전 실행 | `native-modified-untrusted/`: 요청은 offline provider까지 도달했지만 hook 시작/완료, 파일 기록은 없음 |
| 재신뢰 후 실행 | `ui/tui-alpha-update.txt`, `native-alpha-updated/`: Codex 화면에서 해당 정의를 검토, 신뢰한 뒤 새 배포본의 native 완료 |
| 중복 등록 | `duplicate-connections/`: 같은 이름 skill과 같은 hook을 각각 두 개로 발견. 자동 통합되지 않음 |
| 정리 | `after-duplicate-removal/`, `after-alpha-removal/`: 중복 제거 후 각각 하나, A 연결 제거 후 A는 0, B는 1 |
| 보존 | `protected-before.json`, `release-checks.json`, `summary.json`: AGENTS, WIKI, 프로젝트 입력, 실사용 설정, 공통 commit 내용 보존 |

Codex UI의 세 번 신뢰는 새로 만든 시험 hook에만 수행했다. `--dangerously-bypass-hook-trust`를 사용하거나 제품 설치기가 사용자 신뢰를 대신한 것은 아니다. 중복 두 hook을 모두 신뢰해 실행하는 시험은 하지 않았으며 발견 개수만 확인했다.

## 실패와 진단

1. 최초 TUI의 background server는 이 sandbox에서 socket을 준비하지 못했다. `attempt-daemon/`에 원래 실패를 보존하고, 오류 안내의 `--no-daemon`으로 같은 UI 검토를 이어갔다. 실제 사용자 daemon을 종료하거나 고치지 않았다.
2. `thread/start`와 `hooks/list` 응답만으로는 hook 실행 기록이 없었다. 명시한 시작 source, 짧은 대기, 고정 `pwd` 명령, 새 프로세스의 재개도 기록을 만들지 않았다. 이 관측을 native 성공으로 세지 않았다.
3. 실제 모델 연결 없는 `turn/start`로 이벤트를 발생시켰다. 처음에는 전체 요청 완료를 기다렸지만 관측 시간이 끝났고, native hook의 timeout과 반복되는 offline 재연결을 확인했다. `offline-trusted-start/`, `offline-trusted-completion/`에 실패를 보존했다. 최종 관측기는 hook 결과 뒤 `turn/interrupt`를 보냈다.
4. `native-timeout-diagnosis/`에서는 본문 기록은 맞았지만 종료한 자식이 zombie로 남았고 native 결과가 10초 timeout이었다. `direct-diagnostic.json`의 직접 호출은 종료 0이었으나 native 성공으로 대체하지 않았다.
5. 승인받아 같은 hook, 프로젝트, Codex 상태를 sandbox 밖에서 실행하니 `hook/completed`의 상태가 `completed`였다. 네 완료의 관측 시간은 20, 19, 22, 20ms다. 성능 비교 통계가 아니며 정확한 내부 원인이나 모든 sandbox 호환성을 입증하지 않는다.

실패를 버리고 성공만 집계하지 않는다. 준비 중 schema 이름 오기와 관측기 수정 이유도 `preparation-notes.json`, 원래 소스 사본과 출력에 남겼다. 최초 단순 세션 생성은 모델 요청 전 hook 발동을 보장하는 API라는 가정의 근거가 될 수 없다.

## 해석과 남은 범위

B의 고정 외부 배포본, 프로젝트 연결은 이번 native 발견/시작/재개에서 동작했다. 업데이트 뒤 hook 재신뢰, 중복 연결 확인, native 완료 확인은 기존 설계의 필수 조건으로 유지한다. [E-021 — 「E-021 — native hook의 완료와 격리 환경 차이」](../../issues.md)과 [설치 문서 — 「Codex 연결 시험 결과」](../../../design/runtime/install.md)에 연결했다.

실제 AI의 skill 선택, 절차 준수, 문서 품질, compact 후 작업 복구, Windows 파일 반영/권한, 팀원별 설치, 원격 인증/배포, 사용자 변경을 포함한 제품 전체 설치는 미검증이다. offline 요청을 성공한 AI 응답으로 계산하지 않는다. 중첩 실행을 지원하려면 해당 환경에서 시간 초과, 프로세스 종료, 진단을 따로 검증해야 한다.

재현할 때는 새 `/tmp` 작업 공간, 별도 Codex 상태, 새 결과 폴더와 포인터를 준비한다. `source/setup.py`의 fixture 준비 → `source/client.py` 발견 → Codex UI의 해당 hook 검토 → `source/observe.py` 시작/재개 → 연결 변경/목록 대조 순서다. `source/verify.py`는 저장된 결과를 대조한다. 이 폴더를 실행 출력으로 다시 사용하거나 실제 계정 설정을 복사하지 않는다.

공식 비교 근거는 [skill 탐색, 링크](https://learn.chatgpt.com/docs/build-skills), [hook 로드, 신뢰, 출력](https://learn.chatgpt.com/docs/hooks)다. 실제 관측과 공식 지원 설명을 구별한다. `SHA256SUMS`로 원시 자료 무결성을 확인할 수 있으며 평가의 충분성은 별도 판단한다.
