# 프로젝트 로컬 권한과 Git 제외의 부분 검증

자료명은 관측에 사용한 근거를 식별한다. 개별 파일의 제공 범위는 [기록 기준](../../recording.md)을 따른다.

> 검토와 관측 기록. 검토 당시의 후보와 관측을 보존한다. 현재 채택 범위는 결정 목록에서 확인하며, 미실행 계획이나 예비 시험을 제품 검증 완료로 해석하지 않는다.

사용자 작업일: 2026-11-18. Windows Codex 전역 설정을 수정하지 않고 프로젝트마다 외부 WIKI를 연결할 후보를 확인했다. 초기 설계 근거이며 배포 제품의 구현/전체 수용 검사가 아니다. 이전 사용자 설정 정의 방식의 실패는 [앞선 관측](2026-11-18_10-36-06-windows-config.md)에 보존한다.

## 입력과 실행

- Windows Codex `0.169.1`, 같은 vendor 실행 파일의 전후 SHA-256 일치. Windows Git/Python으로 실행했으며 [준비 당시 버전](2026-11-11_07-36-47-windows-readiness.md)은 Git `2.52.0.windows.1`, Python `3.13.9`다. 이번 제외 시험에서 이 둘의 버전 조회는 반복하지 않았다.
- 지속 시험 공간의 `permissions-local-20261118`에 빈 합성 Git 프로젝트 A/B/C/D/E와 WIKI를 만들었다. 현재 개발 프로젝트, 실제 WIKI, 계정 자격증명은 시험 입력으로 복사하지 않았다.
- local.py 기록은 probe.py 기록으로 별도 CODEX_HOME의 app-server 설정만 조회했다. 합성 trust 입력과 실제 사용자 설정 비변경을 구분한다. 제품이 전역 trust를 자동 등록하는 구현이 아니다.
- access.py 기록은 프로젝트 로컬 프로필을 명시하고 일회성 `-c windows.sandbox=mxc`로 실제 native sandbox의 파일 작업을 실행했다. 모델 요청은 0회이며 전역 sandbox 선택, 관리자 계정/방화벽 준비를 수행하지 않았다.
- exclude.py 기록은 별도 Windows Git 저장소 3개에서 제외/추적/충돌을 확인했다. 그 fixture 안의 stage만 사용했고 commit, remote, 실제 프로젝트 index 변경은 없다. Git 전역 설정은 자식 환경에서 읽지 않도록 격리했다.

## 확인한 결과

| 구간 | 관측 | 해석 범위 |
| --- | --- | --- |
| 프로젝트 로컬 설정 | 10개 조회 모두 exit 0. A/B/A와 A 하위 폴더는 해당 프로필 선택 | 같은 이름/경로를 모든 프로젝트에 전역 적용하지 않는 입력 확인 |
| 미사용 C와 연결 전/후 D | C 전후 config 동일. D는 연결 전 조회 가능하고 이름/정의를 함께 저장한 뒤 자기 설정 조회 | 앞선 C/D 시작 실패를 피하는 후보. 모든 상속/정책의 해결 증거는 아님 |
| 기존 legacy sandbox | C의 기존 루트/네트워크 값, E의 기존 루트 + WIKI-E 조회 | 기존 체계를 유지한 설정 조합의 관측. legacy의 실제 파일 접근은 별도 |
| 명시적 native sandbox | A는 자기 프로젝트/WIKI-A, B는 자기 프로젝트/WIKI-B, C는 자기 프로젝트에 쓰고 다시 읽음. 성공 5개, 상대 WIKI 또는 C의 외부 WIKI 쓰기 거부 4개 | 실제 sandbox 부분 확인. 일반 TUI의 자동 선택/세션 재개까지 검증한 것은 아님 |
| 보존 | 실제 사용자 config, 합성 base config와 Codex 실행 파일 전후 동일 | 전역 설정 비변경 관측. 제품 설치/변경/해제 전체 과정의 증거는 아님 |

설정의 원시 결과는 observed/report.json 기록과 `observed/result-*/`에 있다. 파일 접근은 observed/access-utf8/report.json 기록, 각 명령의 stdout/stderr 원문과 bytes로 보존한다. 각 자식은 종료됐으며 남겨 둔 요청/제품 timeout은 없다.

## 자동 제외 결과

`info/exclude` 위치를 Git으로 조회하고 새 로컬 config의 경로만 추가했다. 같은 처리를 두 번 실행했다. 원시 명령과 결과 기록은 아래 관측의 근거다.

| 입력 | 결과 |
| --- | --- |
| 새 config | 제외 항목 하나, 재실행 뒤 동일. `git status`에 config가 나오지 않으며 `git add .` 뒤 공유 skill과 기존 `.gitignore`만 stage됨 |
| 이미 stage한 config | 추적 상태를 감지해 제외 처리를 보류. config, index, 기존 exclude 바이트 동일 |
| `.gitignore`의 재포함 규칙 | 제외 실패를 감지. 개인 config를 만들지 않고 이번 exclude 변경을 복원 |

세 입력 모두 공유 `.gitignore`와 기존 제외 내용을 보존했다. 이는 연결 코드가 수동 exclude 편집을 대신할 수 있다는 부분 근거다. 제품의 중단/동시 편집 복원, linked worktree, 강제 stage와 저장소 변경까지 검증한 것은 아니다. 실제 구현은 Git이 반환한 메타데이터 범위와 기존 소유를 확인해야 한다.

## 실패와 보정

1. `observed/access/`: 자식 환경의 `SystemDrive` 누락으로 MXC 준비가 실패했다. 파일 작업 전 exit 1이며 stderr 기록과 당시 소스를 보존했다. 제품 권한 실패와 시험 입력 오류를 구분한다.
2. `observed/access-systemdrive/`: 환경을 보완한 다음 실행은 cp949 출력을 관측기가 UTF-8로 읽다가 실패했다. 원시 stdout/stderr를 저장하기 전에 예외가 발생했으므로 그 시도의 전체 접근 결과는 확인하지 못했다. 당시 실행 소스와 후속 파일 관측 기록만 남겼고 성공한 세 번째 결과로 덮지 않았다.
3. `observed/access-utf8/`: 자식 Python에 UTF-8을 명시하고 stdout/stderr bytes부터 저장하도록 보정했다. 새로운 출력 파일명으로 3개 명령을 실행했고 9개 파일 작업이 기대 결과와 일치했다.

재시도는 실패한 관측 구간만 수행했다. 앞선 10개 설정 조회를 반복하지 않았다. 두 번째 시도의 원시 출력 부재는 이 기록의 한계다.

## 남은 확인

일반 `codex` 진입과 같은 세션 재개에서 자동 권한 적용, 실제 AI의 필요한 문서 읽기/변경은 아직이다. 현재 파일 시험은 명시적 프로필과 일회성 MXC를 사용했으므로 제품이 기본으로 그 조합을 강제한다는 결정이 아니다. 기존 공유 config, 다른 관리 정책, 경로 변경/해제, 여러 작업 사본과 연결 도중 중단은 [수용 입력 — 「지속 권한 설정의 검증 입력」](../../../verification/acceptance.md)에 따라 검증한다. 토큰 비용, 성능 이득은 측정하지 않았다.

## 근거와 검사

[Codex 프로젝트 설정](https://learn.chatgpt.com/docs/config-file/config-basic), [권한 설정](https://learn.chatgpt.com/docs/permissions), [프로필의 적용 제한](https://learn.chatgpt.com/docs/config-file/config-advanced), [Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox)를 설계와 대조했다. [Git 로컬 제외](https://git-scm.com/docs/gitignore)와 [Git 메타데이터 위치 조회](https://git-scm.com/docs/git-rev-parse)는 자동 제외 후보의 근거다.

check.py 기록은 저장된 입력/출력의 대응을 검사하며 제품을 다시 실행하지 않는다. check.json 기록의 PASS는 그 자료 일치에 한정한다. SHA256SUMS 기록은 이 폴더의 보존 파일 무결성 목록이다. 새 정책과 동작 소유는 [진입 설계 — 「지속 권한 설정의 배치」](../../../design/runtime/entry.md)에 둔다.
