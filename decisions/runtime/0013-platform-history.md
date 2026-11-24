# ADR 0013: 첫 실행 환경과 프로젝트 위치

- 날짜: 2026-10-29
- 채택: 2026-10-29 A, 2026-11-05 외부 문서의 Windows 파일시스템 지원 방향 보완
- 설계 상태: `superseded` — 첫 제품 실행, 저장 범위는 2026-11-11 [ADR 0020](0020-windows.md)으로 대체. 아래는 당시 판단, 비교, 개인 검증 기록이다.
예비 도구와 격리 hook 관측은 제품 검증과 구분한다. 제품 설치, IDE, skill/복구의 실사용 및 Windows 직접 실행, 환경별 성능 비교는 미검증
- 확정된 입력: 현재 사용자 환경부터 동작시키고 다른 환경 확대는 후속 유지보수, 고도화로 둔다. 배포 README에 사용 순서와 명령을 설명한다.
- 당시 채택 범위: WSL2 Ubuntu 실행 + Linux 코드 프로젝트, Windows 외부 문서 지원. 현재 첫 배포는 ADR 0020의 Windows 직접 실행이며 WSL/Linux는 후속이다.
- 미정: 정확한 도구 버전, 설치 인터페이스와 후속 지원의 구체 버전, 시점. 실제 개발 시작은 별도 요청 뒤 진행한다.
- 11/11 변경: 사용자가 Windows 직접 실행 우선, WSL/Linux 후속을 수용했다. 아래 재검토는 결정에 이른 이력이며 최신 실행 안내는 [ADR 0020](0020-windows.md)을 따른다.
- 상세: [실행 환경과 사용 안내](../../design/runtime/install.md)

11/04에는 Windows 앱의 WSL vault 오류를 고려해 [외부 문서 배치 — 「Windows 앱과 vault 배치 보정」](../knowledge/0016-storage.md)를 제안했고, 11/05 사용자가 배치 1을 검증 후보로 삼아 Windows 문서 지원을 추가하는 방향을 수용했다. 코드, 빌드는 WSL에 유지하고, Windows Obsidian과 WSL Codex가 같은 Windows 문서 원본을 사용한다. 작은 시험의 정확한 경로, 권한, 변경 반영, 재실행 확인을 먼저 구체화하며, 실제 이전, 호환성 검증이 완료됐다는 뜻은 아니다. Git 운영, 작업별 버전 연결 수단은 별도 협의다.

## 문제와 관측

IntelliJ 터미널, Windows Terminal은 명령을 입력하는 창이고 Bash, PowerShell, CMD는 그 안에서 실행하는 셸이다. 같은 창에서도 Windows 도구 또는 WSL의 Linux 도구를 호출할 수 있다. 프로젝트가 어디에 저장됐는지도 별도 조건이다. 터미널 제품 이름이나 `.sh` 확장자만으로 실행 환경을 확정하면 설치는 성공했지만 hook, 검증이 다른 환경에서 동작하는 문제가 생길 수 있다.

이번 읽기 전용 확인 결과는 다음과 같다.

| 항목 | 관측 | 한계 |
| --- | --- | --- |
| 호스트 | Windows 11 — 사용자 제공 | Windows 설정을 직접 조회한 결과는 아님 |
| 실행 환경 | WSL2 커널 `5.15.167.4-microsoft-standard-WSL2`, Ubuntu 22.04.5 LTS, Bash | 다른 배포판, WSL 버전 미시험 |
| 관측 파일시스템 | WSL 로컬 작업 폴더의 ext4 | 개별 절대경로를 배포 기본값으로 사용하지 않음 |
| Windows 드라이브 접근 | `/mnt/c`의 `findmnt` 결과 9p | 설치, 성능, 권한 시나리오를 실행한 결과는 아님 |
| 도구 | WSL 경로의 Bash, Git, Python, Codex, Codex npm 메타데이터 `0.165.0` | 지원 최소/최대 버전 확정이나 native hook 시험이 아님 |
| Windows에서의 경로 표현 | WSL 경로를 UNC 형태로 변환 | 해당 관측 시점의 실제 앱 열기는 미수행 |

## 근거

- [Microsoft 파일시스템 안내](https://learn.microsoft.com/en-us/windows/wsl/filesystems)는 Linux 명령으로 작업할 때 Linux 파일시스템에 파일을 둘 것을 권장한다. Windows 드라이브를 WSL에서 접근할 수 있으나 성능, 대소문자 차이를 고려해야 한다.
- [WSL 파일 권한](https://learn.microsoft.com/en-us/windows/wsl/file-permissions)은 Windows 파일 접근 시 Windows 권한과 선택적 WSL 메타데이터가 적용됨을 설명한다. 경로를 바꾸는 것만으로 Linux 파일 권한과 같아지지 않는다.
- [OpenAI Docs의 WSL 안내](https://learn.chatgpt.com/docs/windows/wsl)는 WSL2에서 Linux 실행, sandbox를 사용하며 Linux 홈 경로를 권장한다. WSL1과 Windows 직접 실행을 같은 환경으로 취급하지 않는다.
- [IntelliJ WSL](https://www.jetbrains.com/help/idea/how-to-use-wsl-development-environment-in-product.html)과 [터미널 설정](https://www.jetbrains.com/help/idea/settings-tools-terminal.html)은 Windows IDE에서 WSL 프로젝트를 열고 WSL 셸을 사용할 수 있음을 설명한다. IDE 자체를 Linux용으로 바꾸는 것이 필수는 아니다.

공식 문서가 이 모듈의 호환성을 보장한 것은 아니다. 아래 비교와 A 채택은 이 근거와 현재 일정, 검증 비용에 대한 판단이며 실제 동작 확인은 남아 있다.

## 대안

| 안 | 사용 방식 | 장점 | 비용, 한계 |
| --- | --- | --- | --- |
| A — 채택 | WSL2 Ubuntu에서 실행, 배포판의 Linux 파일시스템에 둔 프로젝트부터 지원 | 현재 작업 환경과 일치. 실행기, 파일 처리의 검증 조합이 작음 | `C:\...` 프로젝트는 별도 작업 사본, 이전 협의가 필요. 다른 환경은 후속 |
| B | 실행은 WSL2로 통일하고 Linux, Windows 드라이브 프로젝트 모두 지원 | 기존 C드라이브 작업 위치를 유지 가능 | 권한, 대소문자, 경로, 줄바꿈, 성능, 복구를 파일시스템별로 확인해야 함 |
| C | WSL과 Windows 직접 실행을 함께 지원 | Git Bash, PowerShell/CMD 사용자의 진입이 편함 | 실행기, 명령, hook, 설치/복구 시험이 늘어 현재 환경 우선 목표에 불리 |

## 채택 범위와 남은 설계

A를 채택했다. IntelliJ, Windows Terminal, CMD 중 하나의 창을 강제하지 않고, 실제 작업은 같은 WSL 배포판의 셸, 도구로 실행하도록 안내한다. 설치 후 Codex CLI도 WSL에서 실행해야 같은 실행 조건을 유지할 수 있다. 사용자가 현재처럼 프로젝트를 열고 그 안의 터미널을 쓰는 흐름을 원하므로 WSL 셸, 프로젝트 루트, WSL 도구 확인을 사용 안내에 포함한다.

사용자는 C드라이브 프로젝트 지원을 v1 후속 버전 또는 v2의 개발 대상으로 명시했다. 특정 버전에서 반드시 출시한다고 확약한 것은 아니며 해당 작업 때 파일시스템별 검증 범위를 정한다. Windows 직접 실행은 이 후속 항목과도 구분한다. 이번 채택은 환경 경계를 정한 것이고 설치 구현, IDE 설정 변경, 프로젝트 이동을 승인한 것은 아니다.

Windows의 `C:`에 WSL 가상디스크가 놓인 것과 `C:\work\repo`를 직접 사용하는 것은 다르다. WSL2는 Windows 디스크 위의 가상디스크에 Linux 파일시스템을 담는다. 따라서 판정 기준은 물리적 드라이브 문자보다 실행 환경과 대상 파일시스템이다. [WSL 디스크 설명](https://learn.microsoft.com/en-us/windows/wsl/disk-space).

프로젝트 독립성은 유지한다. 사용자 이름, 배포판 이름, 현재 프로젝트 절대 경로, 모듈명은 공통 코드에 고정하지 않는다. Windows 직접 실행을 후속으로 두더라도 설치, 파일 처리의 환경 의존 부분을 업무 규칙과 뒤섞지 않는다. 첫 버전부터 범용 OS 계층이나 별도 설치기 여러 개를 만드는 것은 채택하지 않았다.

기존 프로젝트는 자동 이동, 재복제하지 않는다. 이동이 필요하면 미커밋, 미추적, ignored 자료와 로컬 설정을 확인하고, 원본 보존, 작업 사본 전환 범위를 먼저 협의한다. Git clone만으로 개인 파일까지 옮겨진다고 안내하지 않는다.

## Windows 직접 실행 재검토

11/11 사용자가 WSL의 성능상 이점과 Windows 직접 실행의 단순성을 재확인하고, 일반 Windows 사용자도 프로젝트를 WSL로 옮겨야 하는 부담을 지적했다. **최신 추천은 초기 설계 환경을 유지하면서 배포물은 Windows 직접 실행부터 구현, 검증하는 것이다. 기존 A를 변경하는 사용자 확인은 아직이다.** 사용자가 수용한 [지속 시험 공간](../../verification/acceptance.md)의 준비는 이 환경 논의를 마친 뒤 진행한다.

현재 [OpenAI Docs의 Windows 안내](https://learn.chatgpt.com/docs/windows/windows-sandbox)는 Windows에서 Codex CLI를 직접 실행하는 경로와 Windows sandbox를 제공한다. WSL은 필수가 아니다. Windows 빌드, 정책, 사용 도구에 맞는 동작 확인은 별도이며, Windows Codex 지원을 곧 이 하네스의 Windows 호환 완료로 해석하지 않는다. [WSL 안내](https://learn.chatgpt.com/docs/windows/wsl)는 Linux 도구가 필요하거나 이미 WSL에 개발 흐름이 있는 경우 WSL2를 선택하도록 설명한다.

성능 판단에서는 도구의 실행 위치와 파일의 저장 위치를 함께 비교한다. [Microsoft 파일시스템 안내](https://learn.microsoft.com/en-us/windows/wsl/filesystems)는 Linux 도구에는 Linux 파일시스템을, Windows 도구에는 Windows 파일시스템을 권장한다. 이는 WSL이 Windows 직접 실행보다 언제나 빠르다는 비교 결과가 아니다.

| 구성 | 파일 접근과 호환성 | 이번 판단 |
| --- | --- | --- |
| WSL 도구 + Linux 코드 경로 | Linux 파일에 직접 접근하고 Bash 기반 작업을 이어갈 수 있음 | 현재 코드, 실행 흐름과 일치 |
| Windows 도구 + Windows 코드 경로 | Windows 파일에 직접 접근. Linux 명령을 그대로 실행할 수 있다고 가정하면 안 됨 | 정상적인 대안. 현재 하네스의 명령, 권한, hook, 복구 검증 필요 |
| WSL 도구 + Windows 코드 경로 | OS 경계를 넘는 파일 접근. 경로 변환만으로 Linux 파일시스템이 되지 않음 | 첫 코드 지원에서는 계속 제외하는 추천 |

Microsoft의 [상호 운용 성능 안내](https://learn.microsoft.com/en-us/windows/dev-environment/wsl-interop#performance-considerations)는 `/mnt/c`와 `\\wsl$`를 통한 교차 파일 접근의 비용을 설명한다. 작은 Markdown 읽기와 다수 파일 탐색, Git, 빌드를 같은 부하로 비교하지 않는다. 현재 Windows WIKI도 이 경계를 넘으므로 비용이 없다고 주장하지 않는다. Windows Obsidian과 같은 원본을 사용하기 위한 절충이며, 현재 문서 작업에서의 지연 크기는 미측정이다.

이번 로컬 읽기 확인에서는 Codex npm 패키지 `0.167.0`이 Linux 경로에 있고, 코드 경로는 ext4, Windows WIKI는 9p였다. 추적 중인 scripts/hooks의 `.sh` 파일은 5개이며 확인한 검증 스크립트에는 Bash의 `mapfile`과 `./gradlew` 등이 있다. `gradlew.bat`도 존재하므로 Java 프로젝트 자체가 Windows에서 불가능하다는 뜻은 아니다. 이 관측은 현재 자산의 전환 비용을 보여줄 뿐, 앞으로 만들 공통 모듈을 Bash나 WSL에 영구 종속시킬 이유는 아니다.

사용자가 체감하는 총시간은 로컬 파일/명령, 빌드/검사 시간, 네트워크/모델 응답 대기, 실패 후 재시도 등으로 나눠 판단한다. 클라우드 모델의 서버측 추론을 로컬 프로젝트 위치 변경으로 가속한다고 설명하지 않는다. 현재 두 환경의 동일 작업을 비교 실행하지 않았으므로 속도 차이, 토큰 절감, 동등 성능 수치는 제시하지 않는다. Windows에서 Linux 명령이 맞지 않아 실패했다면 명령/도구 호환 문제부터 확인해야 하며 Windows 파일 읽기 자체가 느리다는 증거로 쓰지 않는다.

11/11 첫 답변은 기한과 기존 작업 흐름을 고려해 첫 배포까지 WSL 범위를 유지하도록 추천했다. 후속 질문에서는 배포받는 사용자의 진입 비용을 보강했다. Windows 파일시스템에서 Windows 도구로 개발하는 것은 공식 지원되는 흐름이며 모든 Windows 개발자가 WSL에 프로젝트를 둔다는 관례는 근거가 없다. [Microsoft 개발 도구 안내](https://developer.microsoft.com/en-us/windows/dev-tools)도 Windows 도구와 Linux 연동을 함께 제시한다. 실제 저장 위치의 사용 비율은 확인하지 않았으며 대다수의 관행을 단정하지 않는다.

**현재 개발은 WSL에서 계속하되, 배포 대상의 Windows 직접 실행은 별도로 판단하는 것이 추천이다.** 개발자의 OS가 배포 모듈의 지원 OS를 결정하지 않으며 Windows 지원을 검토하기 위해 현재 설계 위키나 코드 원본을 먼저 옮길 필요도 없다. WSL 전용 첫 배포는 사용자에게 WSL 도구 준비와 Linux 코드 작업 사본을 요구하는 제한이다. 개인 검증 중심의 초기 제공에는 가능한 선택이지만 일반 Windows 사용자에게 가장 편한 방식으로 설명하지 않는다.

기존 Bash 자산을 모두 그대로 재사용해야 한다고 전제하지 않으며, 이미 선택한 Python 제공 수단만으로 전체 Windows 호환이 해결됐다고도 판단하지 않는다. 공통 정책과 환경별 실행 경계는 기존 [확장 원칙 — 「확장을 위한 경계」](../../design/architecture.md)을 유지한다. 아래 최신 추천은 방향을 지금 정하고 초기 호환성 확인과 기능별 실제 검증을 뒤따르게 하는 안이다.

Windows로 통일하면 WSL 경로 변환은 줄지만, 사용자가 요구한 코드/WIKI 저장소 분리, 접근 권한, 작업 버전 연결은 그대로 필요하다. 현재 `C:\...`와 `/mnt/c/...`는 같은 Windows 문서 원본의 다른 표기이며 별도 사본 간 동기화나 심볼릭 링크가 필수인 구성이 아니다. Git remote 관리 자체도 WSL 때문에 추가된 요구가 아니다.

속도가 환경 선택을 바꿀 핵심 조건이면 같은 코드 SHA, 도구 버전, 명령, 입력과 캐시 조건으로 Windows 직접 실행과 WSL/Linux 실행을 비교하는 작은 시험을 별도로 정한다. 결과의 정확성과 로컬 수행 시간부터 대조하고 모델 응답 시간과 분리한다. 이번에는 Windows 도구 설치, 이전, 벤치마크, 모델 호출을 수행하지 않았다.

### 지금 정할 시작 환경

기존 경로 변환, Codex 연결 도구와 격리 실험은 있었지만 새 배포 모듈의 설치, 갱신과 상세 복원은 본 구현 전이었다. 예비 도구의 존재를 완성된 WSL 전용 제품의 전환 비용으로 계산하지 않는다.

이 구분과 사용자 진입 부담을 근거로 **Windows 직접 실행을 첫 배포 기준으로 바꾸는 안을 추천한다.** 앞선 WSL 유지 추천은 개발 작업 환경의 재사용에 무게를 두었으나, 그 이유만으로 배포받는 사용자의 프로젝트 이동을 요구하기에는 부족하다. 지금 정하면 환경 전제를 명세, 구현, 검증에 함께 반영할 수 있다. 실제 공수의 최소값이나 Windows 기능 성공을 입증한 것은 아니다.

| 방향 | 이점 | 비용, 판단 |
| --- | --- | --- |
| Windows 우선 — 추천 | Windows 사용자가 기존 로컬 프로젝트와 도구를 유지. 코드/WIKI 사이의 WSL 경로 변환 불필요 | Windows 실행, 권한, 중단/복구 확인 필요. 첫 필수 검증 대상을 하나로 좁힘 |
| WSL 한정 유지 | 현재 개인 흐름을 활용하며 Windows 제품 시험을 후속으로 둘 수 있음 | 사용자가 WSL 도구와 Linux 작업 사본을 준비해야 함. 제한된 초기 제공에는 가능 |
| Windows, WSL 동시 정식 지원 | 두 사용자 환경을 첫 배포에서 수용 | 실제 설치와 갱신, 복구 조합이 늘어 현재 첫 배포 범위로는 비추천 |

추천 범위는 Windows 11의 PowerShell에서 Windows용 Git, Python, Codex를 실행하고 Windows 로컬 코드 경로를 사용하는 것이다. 정확한 도구/셸 버전과 파일시스템 조건은 준비 확인 후 명세한다. PowerShell은 진입 셸이고 공통 로직은 기존 Git 릴리스 + Python 방향을 유지한다. 문서는 프로젝트 내부와 별도 로컬 WIKI 모두 연결하며 Obsidian을 필수로 만들지 않는다. 사용자의 기존 skill, 문서, Git 정책과 `.harness/`의 로컬 상태 경계도 유지한다.

WSL/Linux 확장을 위한 책임 분리는 유지하되, 이 안에서는 첫 배포의 동시 정식 지원을 약속하지 않는다. 개발 작업이 WSL에서 된다는 이유로 배포물의 WSL 검증이 끝났다고 표시하지 않는다. 모든 환경의 코드를 먼저 만들거나 사용자별 Windows 경로를 공통 코드에 고정하지 않는다.

사용자가 방향을 확인하면 진행 순서는 다음과 같다.

1. 기존 WSL 우선 채택을 변경한 이유, 새 지원 범위, 후속 지원을 프로필, 설치 안내, 수용 기준, 진행표에 동기화한다. 과거 관측은 당시 환경의 근거로 보존한다.
2. Windows 도구, 버전, sandbox와 시험 경로를 확인하고 원본과 분리한 Windows 앱 clone, 시험 WIKI를 준비한다. 원격은 실제 PR 시험 시점에만 연결한다.
3. 실제 Windows 실행, 문서 접근, 권한, 상태 연결의 작은 호환성 확인을 먼저 한다. 필요한 모델 호출, 설정 변경은 구체 범위로 정하며, 도구 인자/파일 확인을 전체 제품 성공으로 확대하지 않는다. 큰 제약이 확인되면 비용과 대안을 다시 협의한다.
4. 남아 있던 테스트 작성 절차, 검증 계약 → 복구 계약 → 파일별 명세 → 개발 준비로 복귀한다. 기능 구현마다 같은 Windows 시험 공간에서 실제 설치, 사용, 실패, 복원을 검증한다. 완성되지 않은 제품 기능의 성공을 지금 선언하지 않는다.

현재는 추천 작성, 기존 파일 읽기만 수행했다. 첫 지원 변경 채택이나 Windows 도구 설치, 시험 공간 생성, 모델 실행은 아직이다.

### Windows 지원의 변경과 검증

11/11 후속 질문은 Windows를 선택했을 때의 수정 난이도, 연관 영향과 Windows 시험 clone의 활용이다. 아직 제품 본 구현 전이므로 완성된 Linux 전용 제품을 옮기는 경우보다 환경 의존을 줄일 여지가 있다. 다만 아래는 설계와 공식 자료에 근거한 예상이며 변경 공수나 Windows 동작을 실측한 결과가 아니다. 단순 경로 교체만으로 완료되는 작업으로 평가하지 않는다.

| 영역 | 유지하거나 바꿀 내용 | 중요한 확인 |
| --- | --- | --- |
| WIKI, 공통 정책 | 정보 역할, 라우팅, 근거, 단일 반영, 검사/보존 기준 유지 | OS별로 다른 정책 사본을 만들지 않고 같은 완료 기준 적용 |
| 경로, 명령 | 실제 Windows 경로와 도구 발견, 인자 전달을 지원 | 공백/한글, 대소문자, 경계 밖 경로, 줄바꿈. Bash 명령을 문자열 치환으로 옮기지 않음 |
| AI 실행, 중단 | 실제 Windows Codex 실행과 결과 수집, 중단 처리를 연결 | 사용 중인 실행 파일/진입 스크립트, 출력 인코딩, 종료 상태, 잔여 프로세스, 재실행 중복 |
| skill, hook, 상태 | 도구가 발견하는 위치, 이벤트와 프로젝트별 로컬 상태 연결 | 실제 이벤트 뒤 올바른 상태 읽기, 중단/재개, 외부 WIKI 쓰기 권한. 기존 WSL PASS로 대체하지 않음 |
| 갱신, 복원 | 승인한 단위별 반영, 원문 보호 원칙 유지 | 사용 중인 파일, 권한 부족, 다른 드라이브, 동시 편집, 부분 적용과 복원 중 재중단 |
| Git, 작업 연계 | 코드/WIKI의 작업별 커밋, PR 연계 원칙 유지 | 줄바꿈 차이를 사용자 편집으로 오인하는지, 잘못된 루트/remote 연결, private 자료와 로컬 상태 제외 |

[Python subprocess](https://docs.python.org/3/library/subprocess.html#security-considerations)는 Windows의 `.bat`/`.cmd` 인자 해석과 [종료 처리](https://docs.python.org/3/library/subprocess.html#subprocess.Popen.terminate)의 차이를 설명한다.

[파일 삭제](https://docs.python.org/3/library/os.html#os.remove)와 [교체](https://docs.python.org/3/library/os.html#os.replace)도 사용 중인 파일, 권한, 파일시스템을 고려해야 한다. [Git 줄바꿈](https://git-scm.com/docs/gitattributes#_checking_out_and_checking_in)은 저장소와 작업 사본의 바이트가 달라질 수 있는 근거다.

사용자의 전역 Git 설정을 바꾸거나 문서 전체를 일괄 정규화하는 해결을 기본으로 삼지 않는다. Windows Codex의 [sandbox 조건](https://learn.chatgpt.com/docs/windows/windows-sandbox)은 별도로 확인하며 권한 경계를 없애서 통과시키지 않는다.

문서/파일 경로와 일반 처리는 조정 범위를 좁히기 쉬운 후보이고, 실제 실행, 권한, 중단/복구는 검증 부담이 큰 부분으로 본다. 큰 범용 OS 계층을 먼저 만들기보다 실제 차이가 있는 경로, 명령, 프로세스, 파일 반영 책임을 공통 정책에서 분리한다. 지원할 WSL 경로도 유지한다면 공통 변경 뒤 그 환경의 영향받은 검사까지 대조해야 한다. Windows로 첫 범위를 바꾸는 것과 두 환경을 모두 검증해 지원하는 것은 다른 공수다.

Windows를 채택하면 [지속 시험 공간](../../verification/acceptance.md)의 앱 clone을 Windows 로컬 폴더에 두고 Windows Git, Python, Codex로 시험하는 구성이 적절하다. 파일만 Windows에 두고 WSL 도구로 실행한 결과는 Windows 직접 실행 검증이 아니다.

시험은 원본과 분리한 Windows 사본의 기준 상태 확인 → 최소 설치, 발견/호출, 문서 읽기/쓰기 → 실제 중단/재개, 갱신/충돌, 복원 순서로 구체화한다. 기존 시험 프로젝트 자체의 Windows 빌드/검사 제약과 하네스 적용 후 새 문제를 구분한다. 예를 들어 [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html)는 `gradlew.bat`를 제공하지만 그것만으로 이 프로젝트의 비공개 의존성, 전체 빌드 성공까지 보장하지 않는다. 원본/별도 WIKI, DB/컨테이너, 원격 보호 조건은 시험 공간의 기존 계약을 따른다. 아직 Windows 도구, 지원 버전, sandbox, 실제 대상 명령을 확인하지 않았으므로 쉬운 전환이나 무결함을 확약하지 않는다.

## 채택 뒤 확인할 것

1. 지원 셸, 도구, 버전과 대상 경로/파일시스템을 확인하고, 미지원 환경에서는 쓰기 전에 설명하고 중단하는 흐름을 검토한다. 단순 `/home`, `/mnt/c` 문자열만으로 mount, symlink 대상을 확정하지 않는다.
2. WSL 터미널과 Windows IntelliJ의 WSL 터미널에서 같은 설치, 기능 추가, 실행, 복구 결과가 나오는지 확인한다. IDE 터미널의 성공을 JDK, Gradle, 실행 설정 전체의 성공으로 대신하지 않는다.
3. 공백, 한글 경로, 심볼릭 링크와 경계 밖 대상, 재설치, 중간 실패, 이후 사용자 편집 보존을 시험한다. 미지원 파일시스템의 중단도 검증한다.
4. 배포 shell 파일의 LF와 실행 방식을 확인한다. 대상 프로젝트의 전역 Git 설정이나 모든 파일의 줄바꿈을 임의 변경하지 않는다. [Git 줄바꿈 속성](https://git-scm.com/docs/gitattributes).
5. 배포물만 받은 별도 작업 공간에서 README 순서대로 설치, 기능 추가, 재개할 수 있어야 한다. 작성자의 체크아웃, 개인 경로에 의존하면 실패다.

설치 수단은 [ADR 0010](0010-distribution.md), 문서 보존은 [ADR 0011](0011-preservation.md)과 연결한다. 이번에는 위키 문서만 작성하며 제품 환경을 변경하지 않는다.
