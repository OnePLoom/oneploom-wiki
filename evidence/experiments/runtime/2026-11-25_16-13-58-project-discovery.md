# 명령 해석과 프로젝트 발견의 첫 구현 검증

작성일: 2026-11-25. [작업 이슈](https://github.com/OnePLoom/oneploom/issues/1)의 발견 기능을 확인한 기록이다. 설치 또는 전체 실행 흐름의 완료 결과는 아니다.

## 목표와 범위

명령과 경로를 일반 코드로 해석하고 이번 호출의 프로젝트 하나를 확인한다. 정상 프로젝트가 아닌 입력을 다른 프로젝트로 대체하지 않으며, 조회 과정에서 설정을 생성하거나 수정하지 않는 것이 목표다.

이번 구현은 명령/도움말, 현재 위치/명시 경로/등록 목록의 대상 선택, Git 경계, 기본/사용자 지정 설치 위치와 발견에 필요한 설정 읽기를 포함한다. 목록 등록/제거, WIKI 접근/권한, 설치 기준의 소유 확인과 Codex 실행은 후속 연결 대상이다.

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

## 발견한 문제와 수정

초기 43개 검사에서는 경로 API의 향후 제거 경고가 관측됐다. 예약 장치명과 경로 규칙을 Windows 공식 명세에 따라 확인하도록 바꾸고, 경고를 오류로 처리하는 검사로 이어갔다.

이후 59개 검사 중 `test_git_worktree_configuration_cannot_redirect_explicit_target`가 한 번 실패했다. 요청한 위치와 Git의 `core.worktree`가 다른 상황에서 실행은 중단했지만 원인을 `invalid_project`로 반환했다. 기대한 `project_mismatch`와 달라 어떤 설정을 확인해야 하는지 구분하지 못하는 문제였다.

일반적인 작업 폴더 여부를 판정하기 전에 Git이 보고한 루트와 요청 위치를 대조하도록 공통 조회 순서를 수정했다. 같은 59개 전체 검사를 다시 실행해 모두 통과했다. 검사를 삭제하거나 기대 원인을 일반 오류로 완화하지 않았다.

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
