# 명령 해석과 프로젝트 발견의 첫 구현 검증

작성일: 2026-11-25. [작업 이슈](https://github.com/OnePLoom/oneploom/issues/1)의 발견 기능을 확인한 기록이다. 설치 또는 전체 실행 흐름의 완료 결과는 아니다.

## 목표와 범위

명령과 경로를 일반 코드로 해석하고 이번 호출의 프로젝트 하나를 확인한다. 정상 프로젝트가 아닌 입력을 다른 프로젝트로 대체하지 않으며, 조회 과정에서 설정을 생성하거나 수정하지 않는 것이 목표다.

이번 구현은 명령/도움말, 현재 위치/명시 경로/등록 목록의 대상 선택, Git 경계, 기본/사용자 지정 설치 위치와 발견에 필요한 설정 읽기를 포함한다. 목록 등록/제거, WIKI 접근/권한, 설치 기준의 소유 확인과 Codex 실행은 후속 연결 대상이다.

## 사용자 요구와 이번에 만든 동작

이번 기능은 **지금 명령을 실행할 프로젝트가 어디인지 확인하는 입구**다. 여러 프로젝트를 사용하는 상황에서 다른 프로젝트의 설정을 잘못 사용하지 않도록 후속 설치/실행보다 먼저 구현했다.

예를 들어 `C:\Work\sample`을 대상으로 확인하려면 코드 저장소 루트의 PowerShell에서 다음 개발용 명령을 사용할 수 있다. 아직 설치된 `oneploom` 명령이나 제품의 완성된 시작 절차는 아니다.

```powershell
py -3 -B -m oneploom.cli start --project 'C:\Work\sample' --preview --json
```

1. **명령 해석:** `cli.py`가 start와 경로, 미리보기 옵션을 구분한다. 오타를 임의로 보정하거나 중복된 프로젝트 경로 중 하나를 고르지 않는다.
2. **프로젝트 선택:** 명시 경로가 있으면 그 경로만 확인한다. 없으면 현재 위치를 먼저 확인하고, 프로젝트 밖이거나 목록 선택을 요청했을 때 등록 목록을 사용한다. 마지막 선택을 전역 기본값으로 저장하지 않는다.
3. **실제 Git 경계 확인:** `project.py`가 Git이 보고한 루트와 실제 경로를 대조한다. 다른 프로젝트로 연결되는 설정이나 사라진 위치를 발견하면 대체 실행하지 않고 원인을 반환한다.
4. **설치 설정 확인:** 프로젝트의 로컬 연결과 공유 설정을 읽어 설치 위치와 프로젝트 ID를 대조한다. 등록 목록은 위치를 찾는 보조 자료이며 실제 설치 상태의 증명으로 사용하지 않는다.
5. **확인 결과 반환:** 경로나 설정에 문제가 있으면 그 단계의 이유를 알린다. 모두 확인해도 현재 구현에는 Codex 실행부가 없으므로 `runtime_not_implemented`와 종료 코드 5를 반환한다. 이는 조회 실패와 구분되는 미구현 안내다.

예시 경로에 설치 설정이 없다면 위 명령은 설치 부재를 알린다. 문서 예시를 실행하면 항상 성공한다고 가정하지 않는다. 이번 조회는 파일 생성, WIKI 수정과 Codex 실행을 하지 않는다. 도움말만 요청하면 Git이나 프로젝트 목록도 읽지 않는다.

## 책임을 나눈 이유

명령을 해석하는 부분은 사용자가 무엇을 요청했는지, 프로젝트 확인은 어느 폴더와 설정을 사용할지 판단한다. Windows 전용 코드는 현재 사용자 계정의 목록 보관 위치를 찾는다. 이 경계를 나눠 명령 옵션이 바뀌어도 Windows 폴더 조회를 다시 작성하지 않고, 이후 실행부가 추가돼도 프로젝트 판정을 재사용하도록 했다.

불필요한 공통 실행 계층을 늘리는 대신 Python 표준 라이브러리와 Git의 실제 조회 결과를 사용했다. 다만 Git이 루트를 반환했다는 사실만으로 올바른 대상이라고 믿지 않고 요청 경로와 비교한다. 테스트에서도 반환 문구뿐 아니라 파일 보존, 실제 프로세스 종료 코드와 잘못된 대상의 거부를 확인했다.

## 구현과 판단

| 책임 | 코드 저장소의 구현 | 확인한 경계 |
| --- | --- | --- |
| 명령과 출력 | `oneploom/cli.py` | 무인자 start, start/resume 입력, 도움/개발 버전, projects list, JSON과 종료 상태 |
| 경로와 설정 | `oneploom/project.py` | Git 루트, 로컬/공유 설정과 ID, 사용자 지정 설치 위치, 목록 형식과 선택 |
| 사용자별 목록 위치 | `oneploom/windows.py` | Windows의 현재 사용자 앱 데이터 위치 조회. 파일과 폴더 생성 없음 |
| 검증 | `tests/test_cli.py`, `test_project.py`, `test_windows.py`, `test_process.py` | 단위 입력, 실제 Windows 파일/Git/PowerShell과 부분 프로세스 연결 |

표준 argparse를 사용하되 축약 옵션, 중복 프로젝트 옵션, 오타를 추정 실행하는 처리는 허용하지 않는다. `--` 뒤 인자는 배열로 보존하고 이번 단계에서 실행하지 않는다. 도움말은 Git, WIKI와 목록에 접근하지 않는다.

Git의 루트 조회와 실제 파일 위치를 함께 확인한다. 상속된 저장소 전용 Git 환경값은 조회 자식의 환경에서만 제외하고 현재 프로세스의 환경과 설정 파일은 변경하지 않는다. 작업 폴더를 다른 곳으로 지정한 Git 설정도 입력 위치와 대조한다. 중첩 저장소와 `.git` 파일을 사용하는 worktree는 별개 작업 사본으로 취급한다.

프로젝트 목록은 조회 또는 선택이 필요할 때만 읽는다. 현재 위치나 명시 경로가 유효하면 목록 부재/손상과 무관하게 대상 확인을 진행한다. 표시한 목록의 경로와 번호를 유지하며 다른 호출의 새 목록으로 번호를 재해석하지 않는다. JSON 요청과 비대화형 입력에서는 선택을 대신하지 않는다.

설치 위치와 설정이 확인되어도 실행 준비 전체가 끝난 것은 아니다. 개발 작업본은 `runtime_not_implemented`, `unsupported`, 종료 코드 5로 후속 연결이 없음을 알린다. 공유 ID나 `cli.py` 존재를 실행 허가로 사용하지 않으며 실제 파일을 실행하지 않는다.

검증한 소스와 검사는 [코드 커밋 632cbf8](https://github.com/OnePLoom/oneploom/tree/632cbf81f04712aae8d0cf6bea86ee618121437b)에 보존했다.

## 환경과 재현

| 항목 | 관측값 |
| --- | --- |
| OS | Windows 11, build 26300, x64 |
| Python | 3.13.9 |
| Windows Git | 2.52.0.windows.1 |
| Windows PowerShell | 5.1.26100.10068 |
| 입력 자료 | 검사에서 생성한 한글/공백/따옴표 경로의 합성 Git 작업 사본과 설정 |
| 파일 접근 실패 | 실제 Windows 파일 핸들의 공유 제한으로 읽기 거부 재현 |
| 파일 보존 | 호출 전후 내용 해시 대조, 부재 목록/로컬 파일 미생성 확인 |

코드 저장소 루트에서 실행한다. 필요한 Git 작업 사본과 설정은 테스트가 임시 위치에 만들고 정리한다. 설정 예시는 실제 설치기의 산출물을 대신하는 합성 자료이며 설치 시험으로 계산하지 않는다.

```powershell
py -3 -B -X utf8 -W error::DeprecationWarning -m unittest discover -s tests -v
```

최종 결과는 **59개 통과, 실패 0개, 건너뛴 검사 0개**다. 실행 시간 4.387초는 전체 검사 묶음의 관측 시간이며 제품의 시작 시간이나 성능 보장이 아니다. [최종 검사 출력](2026-11-25_16-13-58-project-discovery.log)을 함께 제공한다.

## PR 전 요구사항 대조

2026-11-25 [공통 이슈 #1](https://github.com/OnePLoom/oneploom/issues/1)의 요구사항, 포함 범위와 검증 체크리스트 20개를 구현과 기존 검사 근거에 대조했다. 이번 발견 기능의 필수 누락이나 철회 항목은 없었으며 충족 항목을 이슈에 체크했다. 상위 항목의 완료는 해당 하위 항목의 충족을 포함한다.

| 이슈 항목 묶음 | 항목 수 | 대조한 구현과 검사 근거 |
| --- | --- | --- |
| 명령 입력/도움말과 하위 조건 | 4 | `parse_args`, `main`과 `ParsingTests`: 무인자, 도움말, 잘못된 입력, 구분자 뒤 인자 보존 |
| 프로젝트 대상과 하위 조건 | 4 | `resolve_project`, `git_root`, `RoutingTests`, `ProjectTests`: 현재/명시/선택, 중첩 저장소/worktree, 부재/권한/다른 사본 거부 |
| 읽기 전용 설정과 하위 조건 | 4 | `read_catalog`, `choose_project`, `find_module`, `catalog_path`와 관련 테스트: 선택/중단/형식/위치 확인, 기존 파일과 설정 보존 |
| 실제 Windows 검사와 문서 | 1 | 위 환경/출력, README 실행 안내와 현재 구현 범위. 미구현 실행을 성공으로 보고하지 않음 |
| Code/Wiki 포함 범위 | 2 | 코드 최종 diff와 이 문서 및 관련 계약의 현재 구현 범위 |
| 테스트/검증 항목 | 5 | 입력/결과, 실제 Windows Git, 한글 경로/이동/취소, 보존, 문서와 구현 대응 |

제품/테스트 9파일이 위 59개 검사 통과 시점과 동일한 것을 해시로 확인해 실행 결과를 재사용했다. 이후 문서만 수정했으며, 새로운 실행이나 더 넓은 환경의 성공으로 계산하지 않는다. 사람의 대화형 콘솔 조작과 설치/호스트 실행은 아래 미실행 범위에 그대로 남긴다.

이는 구현자의 1차 검토다. 이슈 체크 완료는 관리자의 PR 검토, 실제 병합이나 전체 제품 완성의 승인이 아니다. 향후 코드나 요구가 바뀌면 영향받는 항목과 검사 근거를 다시 대조한다. 절차의 소유 위치는 코드 저장소 `CONTRIBUTING.md`의 「PR 제출 전 요구사항 검토」다.

## 발견한 문제와 수정

초기 43개 검사에서는 경로 API의 향후 제거 경고가 관측됐다. 예약 장치명과 경로 규칙을 Windows 공식 명세에 따라 확인하도록 바꾸고, 경고를 오류로 처리하는 검사로 이어갔다.

이후 59개 검사 중 `test_git_worktree_configuration_cannot_redirect_explicit_target`가 한 번 실패했다. 요청한 위치와 Git의 `core.worktree`가 다른 상황에서 실행은 중단했지만 원인을 `invalid_project`로 반환했다. 기대한 `project_mismatch`와 달라 어떤 설정을 확인해야 하는지 구분하지 못하는 문제였다.

일반적인 작업 폴더 여부를 판정하기 전에 Git이 보고한 루트와 요청 위치를 대조하도록 공통 조회 순서를 수정했다. 같은 59개 전체 검사를 다시 실행해 모두 통과했다. 검사를 삭제하거나 기대 원인을 일반 오류로 완화하지 않았다.

## 병합과 작업 마감

2026-11-27 코드 PR을 먼저, WIKI PR을 다음에 Rebase and merge했다. PR 검토 대상의 마지막 커밋과 병합 후 커밋은 식별자가 다르지만, 두 저장소 모두 전체 파일 내용이 같은 것을 Git tree로 대조했다. 아래 시각은 실제 GitHub 병합 시각을 KST로 표시한 값이다.

| 저장소 | 병합된 PR | 최종 반영 커밋 | 병합 시각 |
| --- | --- | --- | --- |
| 코드 | [PR #2](https://github.com/OnePLoom/oneploom/pull/2) | [bdcb402](https://github.com/OnePLoom/oneploom/commit/bdcb402ff4eb0a220c701e5b9663d1716c579179) | 2026-11-27 09:47:59 KST |
| WIKI | [PR #1](https://github.com/OnePLoom/oneploom-wiki/pull/1) | [3934292](https://github.com/OnePLoom/oneploom-wiki/commit/3934292da727b753f02266c37ef428f2f27fabea) | 2026-11-27 09:48:23 KST |

[공통 이슈 #1](https://github.com/OnePLoom/oneploom/issues/1)은 두 PR과 정식으로 연결되어 있으며, 필요한 두 PR의 병합 후 `CLOSED/COMPLETED`와 [OnePLoom Project](https://github.com/orgs/OnePLoom/projects/2)의 `Done` 상태를 확인했다. [작업 진행 기록](https://github.com/OnePLoom/oneploom/issues/1#issuecomment-7155285671)에서도 양쪽 최종 커밋을 확인할 수 있다.

검증 기준 커밋 632cbf8과 최종 코드 커밋의 `oneploom/`, `tests/` 내용은 같다. 위 Windows 검사 59개는 동일한 입력의 기존 결과를 재사용한 것이며 병합 뒤 새로 실행한 검사로 표시하지 않는다. 원래 검사 환경, 실패 후 수정 과정과 미실행 범위도 그대로 보존한다.

이번 마감은 OnepLoom 개발 작업의 Git 운영 결과다. 제품의 원격 PR 연계, 무인 이슈 마감, 필수 CI나 설치/실행 연결 기능의 구현 완료를 뜻하지 않는다.

## 확인 방식과 남은 범위

| 범위 | 상태 |
| --- | --- |
| 한글/공백/따옴표 경로, 중첩 저장소, 실제 worktree, 경로 이동, junction 이탈 | 실제 Windows 파일과 Git으로 확인 |
| 실제 Python 프로세스의 결과/종료 코드와 PowerShell 경로 전달 | 실제 프로세스로 확인. 소스 실행 경로이며 설치된 wheel의 검증이 아님 |
| 실제 파일 사용 중 읽기 거부 | Windows 파일 핸들로 확인 |
| 번호 오류, Enter/q, Ctrl+C, EOF, 비대화형 선택 | 입출력 대역을 통한 단위 검사. 사람의 콘솔 조작 시험은 미실행 |
| 네트워크 드라이브 판별 실패, 일반 접근 거부 | 함수/오류 주입 검사. 실제 네트워크 저장소나 ACL 변경 시험은 미실행 |
| 설치/목록 갱신, PATH 등록, WIKI 연결과 실제 Codex 시작/재개 | 미구현 또는 미실행인 다음 단위 |
| 최소/최대 Python 버전, 다른 Windows 조합, CMD/Git Bash 전체 동작 | 지원 범위 검증 전 |

다음 연결에서는 발견한 설정을 소비하는 프로젝트 실행부가 WIKI/권한/호스트 조건과 설치 소유를 확인해야 한다. 실행 직전 대상 변경도 다시 대조해야 하며, 이 읽기 전용 확인 결과를 영구 실행 허가로 저장하지 않는다.

## 공식 근거

- [Python argparse](https://docs.python.org/3.13/library/argparse.html): 하위 명령, 도움말과 옵션 해석. 제품의 중복/충돌 보호는 별도로 검사했다.
- [Git rev-parse](https://git-scm.com/docs/git-rev-parse): 작업 폴더와 저장소 전용 환경변수 이름 조회. 입력 위치와 조회 결과는 코드에서 추가 대조한다.
- [Windows 파일과 경로 규칙](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file): 예약명과 경로의 의미.
- [Windows Known Folder 조회](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath), [드라이브 종류 조회](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getdrivetypew): 현재 사용자의 위치와 로컬 지원 조건 확인.

공식 문서는 API/형식의 근거이며 이번 실행 결과는 위 검사에서 확인했다. 외부 구현 소스나 실행 파일을 제품에 복사하지 않았다. 사용하는 Python과 Git의 배포 조건은 각각 [Python 라이선스](https://docs.python.org/3.13/license.html), [Git COPYING](https://github.com/git/git/blob/master/COPYING)에 별도로 존재한다. 이번 변경에는 두 도구의 배포본을 동봉하지 않는다.
