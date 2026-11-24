# Windows 도구 확인과 독립 시험 사본 준비

> 검토와 관측 기록. 검토 당시의 후보와 관측을 보존한다. 현재 채택 범위는 결정 목록에서 확인하며, 미실행 계획이나 예비 시험을 제품 검증 완료로 해석하지 않는다.

사용자 작업일: 2026-11-11. UTC 실행 시각은 파일명, `execution.json`에 보존한다. 지원 방향과 검증 범위는 [ADR 0020](../../../decisions/runtime/0020-windows.md), 시험 운영은 [지속 시험 공간](../../../verification/acceptance.md)이 소유한다. 제품 설치나 AI 실행의 성공 기록은 아니다.

## 범위와 결과

사용자는 이번 시험에서 `codex.cmd`를 쓰고 `<WORKSPACE_PATH>`을 사용할 것을 수용했다. 다른 사용자에게 `.cmd`를 고정하지 않으며, 배포 준비에서 실제 실행 가능한 진입을 확인하고 정책 제약을 해결/안내해야 한다는 조건도 재확인했다. PowerShell 실행 정책, 원본 Git, 사용자 Codex 설정은 변경하지 않았다.

| 확인 | 관측 |
| --- | --- |
| Windows / PowerShell | OS build `10.0.26300.0`, PowerShell `5.1.26100.9818`, Desktop |
| Codex 진입 | `codex --version`은 Restricted 정책 때문에 `codex.ps1`에서 차단. `codex.cmd --version`은 `0.167.1`, 종료 0 |
| Windows Git / Python / Node | Git `2.52.0.windows.1`, `py`의 Python `3.13.9`, Node `22.12.0`, 버전 명령 종료 0 |
| Python 발견 | `python`의 첫 경로는 WindowsApps 별칭. 실제 실행 확인에는 `py` 사용. 별칭의 Python 실행은 미시험 |
| 코드 기준 | `f6e33dd56baa2a651a70d7d0b2cc3ebde6575153`, tree `38f19ee9ec69cfcfb5308dedc93a59491cad3f78` |
| clone 입력/결과 | 현재 feature 브랜치와 도달 가능한 조상 이력 137개, 추적 파일 382개. Windows Git clone에서 HEAD, tree, 이력 수, 파일 수 일치, status 깨끗함 |
| Git 독립성 | bundle에서 객체를 풀었고 alternates 없음. clone의 remote 제거. 원본 HEAD, refs, index/config 해시와 status 유지 |

| 시험 WIKI | 별도 빈 폴더. Windows Python으로 한글, 공백 이름과 UTF-8 본문 생성, 읽기 확인 후 자신이 만든 파일만 제거 |

현재 도구 관측은 제품 최소 지원 버전이나 모든 Windows 환경의 지원 확정이 아니다. WSL에서 Windows PowerShell을 호출하고 실제 Windows Git/Python이 작업했다. Windows Codex의 interactive 입력, 모델, sandbox, hook, compact는 실행하지 않았다.

## 보존 자료와 실패 처리

- `check.ps1`, `stdout.json`, `stderr.txt`, `execution.json`: 도구 발견, 정책, 버전 명령과 출력. 개별 실패를 수집하므로 조사 명령의 종료 0을 모든 진입 방식의 PASS로 해석하지 않는다. 응답 시간은 개별 실행값이며 성능 비교 실험이 아니다.
- `source.json`: 원본 커밋, 브랜치, 파일/객체 수의 읽기 관측. 기존 `.gitattributes`는 gradlew LF, bat CRLF, jar binary를 지정하며 Git submodule, symlink는 없었다.
- `prepare.py`, `bootstrap.py`, `clone.py`, `prepare-commands.json`, `prepared.json`: 이번에 승인된 경로에 한정한 일회성 준비 소스, 실행 결과. 배포 모듈의 설치기로 재사용하지 않는다. 이미 존재하는 시험 폴더를 덮어쓰는 재실행은 허용하지 않는다.
- `failed-command/`: 최초 준비의 소스, 출력. PowerShell 5.1을 거쳐 Python `-c` 코드를 전달할 때 문자열 따옴표가 사라져 `NameError: win32`가 났다. 폴더 생성 전 실패했고 Python 파일 실행으로 보정해 같은 준비 단위를 완료했다. 제품 runbook은 변경 범위 밖이어서 여기서 원인, 재개, 예방을 기록한다. 긴 코드를 여러 셸의 문자열 인자로 중첩 전달하지 않는다.
- `reference-check.json`: 위 개인 경로 네 가지의 정적 대조. Git 자체 격리와 AI의 읽기 권한 격리는 별도다.
- `SHA256SUMS`: 이 실행 기록의 무결성 대조 목록.

현재 WSL sandbox 안의 첫 Windows 호출은 `UtilBindVsockAnyPort ... socket failed 1`로 실패했고 승인된 sandbox 밖 호출에서는 성공했다. 이 접근 차이를 Windows 제품 실패나 사용자 CLI의 기본 timeout으로 분류하지 않는다. 실패 자료를 확인한 뒤 수정한 명령만 재개했으며 기존 버전 확인을 반복하지 않았다.

## 남은 시험

시험 코드와 기존 docs/.codex는 `lab\app`, 외부 문서 자리는 `lab\wiki`, 기준 bundle, 결과는 `lab\records`에 있다. clone의 Git hook은 외부 전역 hook 실행을 피하도록 빈 시험 디렉토리로 지정했다. `.codex`의 기존 Codex hook은 그대로이며 둘을 혼동하지 않는다. Git hook, 설정 변경 자체를 시험할 때는 별도 사례에서 활성 조건을 다시 정한다.

현재 app의 기존 docs는 유지했고 외부 WIKI 연결, 이동, 내용 복원은 하지 않았다. 원격 저장소, 테스트 커밋, PR, CI, Gradle, DB/Compose도 실행하지 않았다. 다른 브랜치에만 있는 이력, 미커밋/무시 파일은 현재 bundle에 없다. 문서 없는 사례, 이력 없는 사례를 이 기준 clone에서 자동으로 만들지 않는다.

다음에는 테스트 작성 절차와 검증 계약을 구체화한다. 이 시험 사본을 사용할 실제 Codex 진입, 문서 접근, 중단/재개 시험은 인증, 허용 범위, 모델/비용을 정하고 수행한다. 동일 Windows 계정의 전역 설정, 인증, 서비스까지 독립 clone이 격리해 주지는 않는다.

## 공식 근거

- [PowerShell 실행 정책](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1): Restricted는 개별 명령은 허용하지만 `.ps1` 스크립트를 제한한다. 본인 장비의 정책 관측과 구분한다.
- [Git bundle](https://git-scm.com/docs/git-bundle): refs/객체를 오프라인 전달하고 bundle에서 clone할 수 있다. 현재 준비에서는 한 브랜치와 조상 이력만 지정했으며 원본 worktree, index, 저장소 설정은 가져오지 않았다.
- [OpenAI Windows 안내](https://learn.chatgpt.com/docs/windows/windows-sandbox): Windows native 실행과 sandbox 조건. 일반 버전 명령 성공은 sandbox 또는 모델 작업의 성공을 증명하지 않는다.
