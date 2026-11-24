# ADR 0020: Windows 직접 실행 우선

- 날짜와 채택: 2026-11-11
- 설계 상태: `accepted` — Windows 직접 실행을 첫 배포 기준으로, WSL/Linux 정식 지원은 후속으로 둔다.
- 대체: [ADR 0013](0013-platform-history.md)의 첫 제품 실행, 코드 저장 범위. 개인 WIKI 이전과 당시 검증 근거는 보존한다.
- 구현 및 검증: 지원 방향 채택, Windows 도구 버전 실행, 독립 시험 clone/빈 WIKI 준비 완료. 제품 Windows 실행, 설치와 갱신, 복구는 미검증이다.

## 결정과 근거

첫 배포는 Windows 11의 PowerShell에서 Windows용 Git, Python, Codex를 사용하고 Windows 로컬 프로젝트에서 실행한다. 정확한 도구 버전과 파일시스템 조건은 실제 검증 후 명세한다. 내부 WIKI와 별도 로컬 WIKI를 지원하며 Obsidian은 선택이다. Git 릴리스 + Python 제공, 프로젝트 내 실행 자산, 사용자 편집 보존과 로컬 상태 제외는 기존 합의를 유지한다.

배포 모듈의 본 구현 전에 Windows 사용자의 기존 프로젝트를 유지하는 방향을 택한다. 이미 있는 WSL 의존 자산은 개인 연결 도구, 기존 기존 시험 프로젝트 하네스, 격리 실험이다. 이를 완성된 공통 제품처럼 취급해 WSL을 필수로 고정하지 않는다. 변경 비용이 작을 여지는 있지만 공수, 성능 우위, 무결함을 실측한 결론은 아니다.

| 대안 | 이점 | 비용과 판단 |
| --- | --- | --- |
| Windows 우선 — 채택 | Windows 프로젝트에서 바로 시작하고 첫 검증 대상을 좁힘 | Windows 명령, 권한, 중단/복구를 실제로 검증해야 함 |
| WSL 우선 유지 | 기존 개인 흐름을 활용 | 배포받는 사용자가 Linux 도구와 코드 사본을 준비해야 함 |
| Windows, WSL 동시 첫 지원 | 두 환경 수용 | 검증 조합 증가. 첫 배포 기한을 고려해 보류 |

[OpenAI Windows 안내](https://learn.chatgpt.com/docs/windows/windows-sandbox)는 Windows 직접 실행을 지원한다. [Microsoft 파일시스템 안내](https://learn.microsoft.com/en-us/windows/wsl/filesystems)는 실행 도구에 맞는 파일시스템을 권장한다. 이 사실은 이 모듈의 호환 완료나 Windows의 절대 성능 우위를 증명하지 않는다. 당시 상세 비교는 [기존 재검토 — 「Windows 직접 실행 재검토」](0013-platform-history.md)에 남긴다.

## 적용 경계

- 공통 판단, 문서, 보존 정책을 OS에 종속시키지 않는다. 실제 차이가 있는 경로, 명령, 프로세스, 파일 반영만 구분하고 모든 미래 OS 계층을 선행 구현하지 않는다.
- 새로 구현하거나 재사용할 제품 자산은 Windows 사용 흐름으로 구현, 검증한다. 기존 Bash 파일은 이름만 바꿔 복사하지 않는다. 지원 밖 환경은 적용 전에 설명하고 중단한다.
- 개발 환경의 예비 도구와 배포 제품의 지원 환경은 구분한다. WSL에서 얻은 예비 관측은 Windows 제품 검증을 대신하지 않는다. [예비 도구와 제품 환경](../../evidence/environment-observations.md)에 관측 범위를 연결한다.
제품의 Windows 지원을 개인 세션, 인증, 전역 설정 이전으로 확대하지 않는다.

## 확인할 것과 다음 순서

설치와 평소 사용 안내는 [실행 환경과 사용 안내](../../design/runtime/install.md), 시험 사본은 [지속 시험 공간](../../verification/acceptance.md)이 소유한다. 기존 WSL의 개인 재접속, hook, 예제 PASS를 Windows 제품 성공으로 바꾸지 않는다.

Windows 도구/버전, 경로, 권한을 확인하고, 원본과 분리한 Windows 시험 clone/WIKI에서 실제 진입, 문서 읽기/쓰기, 중단/재개를 검증한다. 11/11 기준 clone, 빈 WIKI와 도구 실행을 확인했으며 현재 결과, 남은 조건은 [현재 준비 상태](../../verification/acceptance.md)가 소유한다. 예비 WSL 작업과 시험 대상의 실행 환경을 구별하며 현재 대화는 시험 세션으로 이전하지 않는다. Windows Codex 업데이트는 사용자가 진행한다. 후속 버전 실행 관측을 제품 지원 버전 확정으로 확대하지 않는다. 모델 호출, 시험 설정의 구체 범위는 실행 전에 정한다. 검증 계약 → 복구 계약 → 파일별 명세 → 개발 준비의 부모 순서는 유지한다. 각 기능 구현 뒤 Windows에서 설치와 갱신, 충돌, 복원을 확인한다.

준비 단계의 읽기 관측은 Windows PowerShell `5.1.26100.9818`, OS build `10.0.26300.0`, Git `2.52.0.windows.1`, Python launcher의 `3.13` 설치, Codex npm 패키지 `0.132.0`, `codex.ps1` 진입이다. 사용자 업데이트 전 관측이며 제품 지원 버전이나 현재 최신값으로 고정하지 않는다. 그 관측 당시 Codex 실제 실행, 인증, hook, sandbox, 제품 기능은 확인하지 않았다.
