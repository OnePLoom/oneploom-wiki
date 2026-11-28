# 개발 검증 CI

## 검사별 책임

코드와 WIKI의 변경을 GitHub에서 자동 검사하는 개발 도구다. 사용자 프로젝트에 설치할 조건부 검증 기능과는 별도다. 공통 실행 규칙과 코드 검사 명령은 [코드 CONTRIBUTING의 「검사와 문서」](https://github.com/OnePLoom/oneploom/blob/main/CONTRIBUTING.md#검사와-문서)가 소유한다.

| 검사 | 확인할 범위 | 현재 단계 |
| --- | --- | --- |
| 코드의 Windows tests | 기존 명령/프로젝트 발견 테스트 전체와 실패 전달 | GitHub 검사 성공과 main 필수 등록 완료. PR 병합 전 |
| WIKI 내부 링크 | 저장소 내부 문서 파일과 섹션의 연결 | GitHub 첫 실행 실패. 루트 판별 수정의 로컬 검증 완료, 수정 커밋과 원격 재검증 전 |

작업의 범위와 전체 완료 조건은 [공통 이슈 4](https://github.com/OnePLoom/oneploom/issues/4)에 연결한다. 한쪽 로컬 검사가 끝났다는 이유로 두 저장소의 CI 구성이 완료됐다고 판단하지 않는다.

## 실행 코드와 권한의 분리

초안은 YAML의 `run`에 Python 환경 확인과 테스트 발견/판정을 직접 넣었다. 문법상 가능하지만 로컬 기여 안내는 `unittest`를 직접 호출해, 빈 검사와 건너뛴 검사를 실패로 처리하는 기준이 서로 달랐다. 실행 순서를 고치는 파일과 검사 기준을 고치는 파일도 뒤섞였다.

현재 구조는 다음과 같다.

| 위치 | 맡는 책임 |
| --- | --- |
| 코드 `.github/workflows/windows-tests.yml` | 이벤트, 실행기/Python 준비, 토큰 권한, 동시 실행과 시간 상한 |
| 코드 `tools/run_tests.py` | 환경 확인, 저장소의 테스트 발견, 실행과 성공 판정. 로컬과 CI가 함께 호출 |
| 코드 `tests/test_runner.py` | 빈 검사, 실패, 건너뜀, 로딩 오류, 경고와 중단이 성공으로 바뀌지 않는지 검사 |
| 코드 `CONTRIBUTING.md` | 실행 명령과 실패 대응의 안내 원본 |

검사 명령의 Python 옵션은 바이트코드 파일 생성 방지, UTF-8 입출력과 폐기 예정 API 경고의 오류 처리를 지정한다. YAML의 환경 변수와 Python 버전 재확인 코드는 제거했다. CI 버전 선택은 `setup-python`, 테스트 실행 정책은 공통 스크립트와 동일한 실행 옵션이 담당한다. Python 옵션은 실행한 검사 인터프리터에 적용하며, 테스트가 따로 여는 제품 프로세스의 설정까지 자동 강제하는 것으로 해석하지 않는다.

[Requests의 검사 workflow](https://github.com/psf/requests/blob/main/.github/workflows/run-tests.yml)는 `make ci`, [pip의 검사 workflow](https://github.com/pypa/pip/blob/main/.github/workflows/ci.yml)는 Nox를 호출한다. 환경 준비와 실제 검사 진입점을 나눠 유지하는 사례로 참고했다. OnepLoom은 표준 라이브러리 검사만 있으므로 Make/Nox 같은 추가 도구 없이 작은 Python 스크립트를 사용한다. 사례의 구성 전체를 복제하지 않는다.

비슷한 단계라도 권한, 입력과 실패 기준이 다르면 합치지 않는다. 코드 검사와 WIKI 검사는 서로 다른 저장소/검증 대상을 갖고, 향후 배포나 이슈 갱신은 쓰기 권한이 필요하다. 현재 한 검사만을 위해 재사용 workflow나 composite action을 추가하지 않는다. 실제 중복된 책임이 생기면 [GitHub의 재사용 단위](https://docs.github.com/en/actions/concepts/workflows-and-actions/reusing-workflow-configurations)와 대조해 선택한다.

## Windows 검사 환경을 고른 이유

현재 제품의 첫 대상은 Windows이며, 기존 테스트에는 Windows 사용자 폴더 API, 파일 공유 거부와 PowerShell 호출이 있다. Linux에서 건너뛴 Windows 검사를 성공으로 계산하지 않도록 Windows 실행기를 사용한다. GitHub가 제공하는 `windows-2025`는 Windows Server 2025이므로 실제 Windows 11의 설치와 사용 검증을 대신하지 않는다. [실행기 이미지의 공개 구성](https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-Readme.md)에서 설치 도구와 이미지 변경을 확인할 수 있다.

Python은 현재 직접 검증한 3.13 계열로 시작한다. 검사를 실행한 정확한 패치 버전, Git과 PowerShell 버전은 로그로 확인한다. 실행기 기본 Python에 맡기면 이미지 변경에 따라 검사 환경이 바뀔 수 있어 공식 `setup-python`으로 선택한다. 이는 CI의 검사 환경이며 배포 사용자의 Python이나 Codex 버전을 강제로 바꾸는 기능이 아니다. 다른 지원 버전은 실제 호환성 검증 범위가 정해질 때 추가한다. [GitHub의 Python 검사 안내](https://docs.github.com/en/actions/tutorials/build-and-test-code/python)를 참고했다.

## 실패와 중복 실행

PR은 병합 대상과 합쳐질 변경을 검사하고, main push는 실제 반영된 상태를 확인한다. 작업 브랜치의 push에 별도 실행을 추가하지 않아 같은 제출을 push와 PR에서 반복 검사하는 비용을 줄인다. 필수 검사에서 경로 필터로 실행 자체를 건너뛰면 결과가 계속 대기할 수 있으므로 PR에 파일 경로 필터를 두지 않는다. 같은 PR 또는 같은 이벤트/참조에 새 실행이 생기면 이전 실행을 취소하고 최신 결과를 확인한다. [workflow 실행 조건과 동시 실행 제어](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)를 따른다.

현재 테스트는 하나도 발견하지 못하거나 하나라도 건너뛰면 실패로 처리한다. 오류를 발견하지 않았다는 사실과 필요한 검사를 모두 수행했다는 사실을 구분하기 위한 기준이다. 의도적인 선택 검사가 필요해지면 실행 조건, 필수 범위와 결과 표현을 함께 검토한다. 준비 실패, 테스트 실패와 시간 초과도 성공으로 바꾸지 않는다.

### 시간 상한과 수동 실행

`timeout-minutes: 15`는 job이 시작된 뒤 준비와 검사에 쓸 초기 최대 시간이다. 작업 대기열 시간이나 제품 사용자의 실행 시간을 제한하지 않는다. [GitHub의 기본 job 상한은 360분](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)이어서, 짧은 검사에서 프로세스가 멈춘 경우를 오래 방치하지 않도록 별도 상한을 둔다.

15분을 최적값으로 입증한 것은 아니다. 로컬 테스트의 초 단위 결과에는 GitHub의 checkout/Python 준비 비용이 없으므로 단순 배수로 계산하지 않는다. 첫 원격 실행부터 준비와 검사 시간을 따로 확인한다. 정상 실행에 여유가 부족하면 원인을 검토해 상한을 조정하고, 멈춤/교착이면 시간을 늘려 숨기지 않는다. 상한 때문에 취소된 결과는 검증 통과가 아니다.

빈 `workflow_dispatch:`는 미구현 항목이 아니라 별도 입력 없는 수동 시작 이벤트다. 현재는 PR과 main 변경이 검사의 출발점이며 별도 수동 실행 목적이 없어 제거했다. 일시적 준비 실패는 [기존 실행의 재시도](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)로 처리한다. 재시도는 원래 커밋을 검사하므로 수정한 코드의 검증은 새 커밋에서 확인한다.

## Actions 버전과 비밀값

### 버전 지정의 선택

| 방식 | 장점 | 고려할 점과 현재 판단 |
| --- | --- | --- |
| 메이저 태그 `@v7` | 읽기 쉽고 같은 메이저의 수정 사항을 자동으로 받음 | 실행 코드가 바뀌며 회귀 오류 가능성은 남음. 현재 공식 테스트 Action 두 개에 사용 |
| 구체 릴리스 태그 `@v7.0.1` | 선택한 릴리스가 명확함 | 후속 수정은 직접 반영해야 하며 일반 태그의 이동 가능성은 별도 고려 |
| 전체 SHA와 버전 주석 | 실행할 커밋을 고정하면서 사람이 버전을 읽을 수 있음 | 자동 수정 수신을 멈추므로 SHA/주석 갱신과 검토가 필요 |
| 태그와 Actions 의존성 lockfile | 태그의 가독성과 잠긴 실행 코드/의존성 확인을 함께 제공 | 현재 공식 사용 조건이 GitHub Enterprise Cloud이므로 Free 운영에 도입하지 않음 |

현재는 `actions/checkout@v7`과 `actions/setup-python@v7`을 선택한다. [GitHub의 Action 릴리스 안내](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions#using-release-management-for-actions)와 [공식 Actions 버전 운영 안내](https://github.com/actions/toolkit/blob/main/docs/action-versioning.md)는 같은 메이저의 호환되는 수정 사항을 받고, 문제가 있을 때 구체 릴리스나 SHA 고정을 검토하는 흐름을 설명한다. 메이저 태그는 새 메이저로 자동 전환되지 않는다.

OnepLoom의 현재 CI는 공식 Action 두 개로 검사만 수행하고 저장소 쓰기 권한, 사용자 Secret과 배포 단계를 갖지 않는다. 이 범위에서는 실행 커밋을 매번 수동 갱신하는 비용보다 같은 메이저의 수정 수신과 간결한 유지관리를 우선한다. 초안의 SHA 고정 권고는 실행 코드의 고정에 무게를 두었지만 현재 운영 범위를 다시 대조해 변경했다. 향후 배포나 외부 Action을 추가할 때는 해당 권한과 위험에 맞춰 별도로 평가한다.

SHA 고정도 정상적인 보안 관례다. 위 Requests와 pip의 실제 workflow에서도 사용하며, [GitHub 보안 지침](https://docs.github.com/en/actions/reference/security/secure-use)은 변경 가능한 태그보다 고정한 실행 코드의 장점을 설명한다. 전체 SHA는 비밀 토큰이 아닌 공개 커밋 식별자이며 호환성보다 코드가 바뀌지 않는다는 보장을 위한 선택이다. 반대로 메이저 태그의 호환성 원칙은 회귀 오류나 실행기 변경의 영향을 없애지는 않는다. 실패하면 원인을 확인한 뒤 필요한 경우 정상 동작한 릴리스나 SHA로 일시 고정한다. 읽기 권한만 부여해도 실행 코드를 신뢰해야 하는 위험은 남는다.

[Actions 의존성 lockfile](https://docs.github.com/en/actions/how-tos/secure-your-work/lock-workflow-dependencies)은 현재 공식 사용 조건이 GitHub Enterprise Cloud이므로 Free 운영에 도입하지 않는다. 태그 선택을 이유로 모든 외부 도구의 고정 정책을 일괄 바꾸지 않는다.

### 검증 작업의 최소 권한

workflow 기본 권한을 `{}`로 두고 Windows 검사 job에만 `contents: read`를 부여한다. [공식 checkout의 권장 권한](https://github.com/actions/checkout#recommended-permissions)에 맞춰 저장소를 읽는 데 사용하며 커밋, 이슈 수정과 배포 권한은 필요 없다. GitHub API 토큰 권한과 실행기 파일시스템 권한은 다르므로 테스트의 임시 파일 쓰기는 가능하다. 새 job은 필요한 권한을 별도로 명시한다.

checkout의 자격증명 보존은 끄고 사용자 PAT, 다른 저장소 토큰이나 배포 비밀값은 전달하지 않는다. `pull_request`로 외부 코드를 검사하며 높은 권한의 `pull_request_target`으로 교체하지 않는다. 현재 workflow에는 PR 제목 같은 외부 입력을 실행할 스크립트 본문에 삽입하는 구문도 없다. [GitHub의 외부 입력과 권한 경계](https://docs.github.com/en/actions/reference/security/secure-use)를 따른다.

현재 사용자가 등록할 Secret은 없다. 이후 비밀값이 필요한 기능을 실제 추가할 때만 필요한 저장소/환경과 job에 한정해 등록한다. 등록 위치와 노출 시 대응은 코드 CONTRIBUTING의 「CI의 비밀값 관리」가 소유한다. 비밀값 탐지 검사에서 발견하지 못했다는 사실이 모든 자격증명과 보안 문제의 부재를 보증하지는 않는다.

## WIKI 내부 링크 검사

WIKI의 검사 명령과 준비 방법은 [WIKI CONTRIBUTING의 「개발 검사」](../CONTRIBUTING.md)에서 관리한다. Markdown 해석, 제목 식별과 저장소 검사의 책임을 구분한다.

| 위치 | 맡는 책임 |
| --- | --- |
| [tools/check-links.js](../tools/check-links.js) | Git 공유 대상 목록을 읽고 문서 파일과 제목 연결을 검사. 파일은 수정하지 않음 |
| [tests/check-links.test.js](../tests/check-links.test.js) | 임시 Git 저장소에서 정상, 누락, 표기, 경로와 실행 실패를 확인 |
| [package.json](../package.json), [package-lock.json](../package-lock.json) | 개발 의존성과 공통 실행 명령, 실제 설치할 버전과 무결성 값 |
| [.github/workflows/document-checks.yml](../.github/workflows/document-checks.yml) | PR/main 이벤트, 실행기 준비, 최소 권한과 검사 순서 |

### 표준 라이브러리의 선택과 경계

[markdown-it](https://github.com/markdown-it/markdown-it)으로 Markdown을 해석하고, [github-slugger](https://github.com/Flet/github-slugger)로 GitHub식 제목 식별자를 만든다. 전자는 [VS Code의 Markdown 기능](https://github.com/microsoft/vscode/blob/main/extensions/markdown-language-features/package.json)에서도 사용하는 파서다. OnepLoom의 검사 코드는 파일 경로와 문서 간 연결을 확인하며 Markdown 문법이나 Unicode 제목 변환을 직접 재구현하지 않는다.

Node.js는 이 WIKI의 개발 검사에만 필요하다. 제품과 코드 저장소의 Python 실행 환경을 바꾸거나 배포 사용자에게 Node.js를 추가로 요구하지 않는다. 현재 Windows 개발 환경에서 확인한 Node.js 22 계열로 CI를 구성하며, 정확한 실행 버전은 job 로그에서 확인한다.

다음 후보를 실제 입력과 비교했다.

| 후보 | 확인한 결과와 판단 |
| --- | --- |
| lychee 0.24.2의 오프라인 파일/앵커 검사 | 원본 164문서에서 제목 연결 177건이 GitHub식 앵커와 다르게 해석됨. 기존 제목 표기를 유지하는 검사에 그대로 적용하지 않음 |
| Python Markdown 해석기와 github-slugger 0.0.3 포트 | Python 3.13.9에서 포트의 import가 UnicodeEncodeError로 실패. 라이브러리를 임시 수정하거나 실패를 무시해 사용하지 않음 |
| JavaScript 원본 파서와 제목 변환기 | 기존 제목 표기와 GitHub 앵커를 구분하고 저장소 경계만 검사 코드에서 다룸. Node.js 준비 비용을 수용하고 선택 |

기존 제목 링크는 [Obsidian의 제목 연결](https://help.obsidian.md/links)과 GitHub의 해석이 다르다. 검사기는 GitHub식 앵커 또는 제목 원문이 실제로 존재하는지 확인하며, 제목 원문으로만 확인한 링크 수를 따로 출력한다. 예를 들어 `#사용%20방법`과 `#사용-방법`은 검사 대상 문서에 `사용 방법` 제목이 있는지 각각 확인한다. 전자가 GitHub에서 같은 방식으로 이동한다는 뜻은 아니다. 기존 링크를 자동 치환하거나 검사에서 제외하지 않는다. 두 화면의 실제 클릭과 위치 확인은 별도 검증이다.

### 검사 범위와 실패 처리

- Git이 추적하는 파일과 ignore되지 않은 새 파일 중 Markdown을 검사한다. 개발 중 새 문서도 포함하고, 이미 추적된 파일이 로컬에서 사라지면 실패한다. 로컬 전용 파일은 검사에 넣지 않으며 그 파일을 가리키는 공유 문서의 링크는 실패한다.
- 일반 Markdown 링크, 참조형 링크, 이미지와 표 안의 링크를 해석한다. 코드 블록, 인라인 코드와 HTML 주석 안의 예시는 실행할 링크로 취급하지 않는다.
- 파일과 폴더의 존재, 정확한 대소문자, URL 인코딩과 Markdown 제목을 확인한다. 제목의 강조/인라인 코드와 중복 제목의 GitHub식 번호도 구분한다.
- 저장소 밖 상대 경로, 절대 경로, 로컬 파일 URL, symlink/junction, 지원하지 않는 scheme/query를 거부한다. UTF-8을 해석하지 못하거나 대상 파일을 읽지 못해도 성공으로 처리하지 않는다.
- HTTP(S), 메일과 외부 호스트 링크는 개수만 알리고 네트워크 요청을 보내지 않는다. HTML 링크/직접 지정한 HTML 앵커, Obsidian 전용 `[[...]]` 문법, PDF 내부 위치, 정의되지 않은 참조의 의도나 일반 본문의 절 이름은 자동 검사 범위가 아니다. 현재 작성 규칙은 저장소 내부 Markdown 상대 링크다.
- 오류에는 문서와 해당 문단/표 셀의 시작 행을 출력한다. 긴 문단의 링크가 있는 정확한 열이나 화면상의 위치까지 뜻하지 않는다.

정상은 종료 코드 0, 문서/연결 오류는 1, 준비/인자 오류나 Markdown이 하나도 없는 경우는 2다. 로컬과 CI는 같은 명령을 사용한다. 명령이 성공했다고 문서 내용의 정확성이나 모든 렌더러의 호환성이 입증되는 것은 아니다.

CI는 `npm ci --ignore-scripts --no-audit --no-fund`로 잠금 파일의 개발 의존성을 설치한다. [npm ci](https://docs.npmjs.com/cli/v11/commands/npm-ci)는 선언과 잠금 파일이 다르면 실패하며, 설치 과정의 패키지 스크립트는 끈다. 설치가 끝난 뒤 검사기 테스트와 전체 WIKI 검사를 각각 실행한다. 작은 의존성 묶음에는 별도 캐시를 추가하지 않았다. [setup-node](https://github.com/actions/setup-node)의 자동 캐시도 끈다. 네트워크가 필요한 준비 단계와 오프라인 문서 검사 단계를 구분한다.

PR/main 이벤트, 이전 실행 취소, 저장소 읽기 권한과 초기 15분 상한은 앞의 공통 기준을 따른다. 새 Secret은 필요하지 않다. 향후 쓰기 권한을 가진 배포/이슈 처리 작업에 이 검사 job을 그대로 재사용하지 않는다.

## 검증 상태

2026-11-28의 로컬 Windows 검사와 첫 GitHub 실행 결과다. 수정 후보의 로컬 검증을 원격 성공으로 계산하지 않는다.

| 확인 | 관측 |
| --- | --- |
| 환경 | Windows 11, Python 3.13.9, Git 2.52.0.windows.1, Windows PowerShell 5.1.26100.10068 |
| 전체 테스트 | 공통 진입점으로 기존 59개와 실행기 회귀 검사 10개, 총 69개 통과. 실패/건너뜀 없음. 테스트 실행 6.400초 |
| 실패 전달 | 정상, 빈 검사, assertion 실패, 단독/혼합 건너뜀, import/setUp 오류, 폐기 예정 API 경고와 중단을 실제 Python 자식 프로세스로 확인. 필수 도구가 없을 때와 다른 작업 폴더에서의 진입도 확인 |
| 정적 구문 | actionlint 1.7.12에서 workflow 오류 없음 |
| Action 참조 변경 | 2026-11-28 공식 Git 참조 조회에서 두 `v7` 태그가 각각 기존에 확인한 checkout v7.0.1, setup-python v7.1.0의 커밋과 같음. 이후 태그 이동까지 보장하는 결과는 아님 |
| 비밀값 탐지 | Gitleaks CLI 8.30.1로 공개 대상 파일과 로컬에서 접근 가능한 양쪽 Git 이력을 검사. 탐지/검사 오류 없음. 배포 CI로 추가한 것은 아님 |
| WIKI 검사기 | 첫 Windows 11/Node.js 22.12.0 검사에서 24개 통과, 실패/건너뜀 없음. 테스트 3.841초. 원격 실패 뒤 루트 판별을 보완한 후보는 기존 24개와 새 경계 3개, 총 27개 통과. 실패/건너뜀 없음, 테스트 4.262초 |
| WIKI 전체 문서 | Markdown 164개, 내부 링크 2,293개 확인, 오류 0개. 제목 원문 일치 177개를 별도 집계하고 외부 링크 1,043개는 제외 |
| WIKI 준비/의존성 | npm ci 성공, 잠금 파일과 설치 파일 해시 보존. 8개 개발 패키지의 npm audit에서 알려진 취약점 0개. 보안 문제 전체의 부재를 보증하지 않음 |
| 원격 실행 | 코드 69개 통과. WIKI는 24개 중 21개 실패, 3개 통과이며 전체 문서 검사는 실행되지 않음. 아래 실행 링크와 원인 검토 참고 |
| 필수 검사 | 코드 main에 GitHub Actions의 Windows tests 등록 완료. WIKI는 실제 성공 후 등록 |

초안의 첫 로컬 실행에서는 WSL에서 Windows로 전달한 Python 환경 변수 세 개가 누락돼 경고 오류화 조건이 적용되지 않았다. Windows 프로세스에서 환경을 구성하도록 시험 실행부를 수정한 뒤 기존 59개와 합성 입력 6개 전체를 다시 확인했다. 이후 실행기 분리에서는 로컬/CI 명령의 Python 실행 옵션으로 바꾸고 위 69개를 다시 확인했다. 과거 결과를 새 실행기의 검증으로 대신하지 않았으며 두 실행의 테스트 수가 달라 속도 개선으로 비교하지 않는다.

정적 구문 검사는 GitHub의 권한, 실행기 준비, 이벤트 발동이나 필수 검사 연결을 증명하지 않는다. 실행 방법과 실패 시 재실행 절차는 코드 CONTRIBUTING의 「Windows CI」를 따른다.

Action 참조를 메이저 태그로 변경할 때는 제품 코드, 테스트와 공통 검사 진입점이 그대로임을 확인해 위 69개 결과를 재사용했다. workflow 구문 검사는 변경 후 다시 수행했고, 이후 첫 GitHub 실행에서 아래 결과를 확인했다.

WIKI 검사기의 첫 회귀 검사에서 폴더 경로 끝의 `/`를 중복 처리하는 오류를 발견했다. 경로 정규화에서 수정한 뒤 원래 실패 사례를 포함한 전체 24개를 재검증했다. 원문 파일/제목이 없는 경우와 표기 차이를 구분하며, 원문 문서를 변경해 통과시키지 않았다.

### 첫 GitHub 실행과 준비 비용

[코드 PR 5](https://github.com/OnePLoom/oneploom/pull/5)와 [WIKI PR 4](https://github.com/OnePLoom/oneploom-wiki/pull/4)의 첫 실행을 확인했다. 두 실행 모두 `pull_request` 이벤트와 Windows Server 2025 실행기를 사용했다.

| 실행 | 실제 결과 | 준비와 검사 시간 |
| --- | --- | --- |
| [Windows tests](https://github.com/OnePLoom/oneploom/actions/runs/46089684006) | Python 3.13.17, Git 2.56.1에서 69개 통과 | job 26초. checkout 7초, Python 준비 1초 미만, 검사 step 13초. 그 안의 테스트 실행 7.963초 |
| [Document links](https://github.com/OnePLoom/oneploom-wiki/actions/runs/46089690847) | Node.js 22.23.5, Git 2.56.1에서 검사기 테스트 실패. 전체 WIKI 검사는 건너뜀 | job 28초. checkout 7초, Node 준비 5초, npm 설치 4초, 실패한 테스트 step 6초 |

job과 step 시간은 GitHub API의 시작/종료 시각 차이며 대기열 시간은 포함하지 않는다. 한 번의 관측이고 WIKI는 실패 실행이므로 두 검사의 성능 비교나 정상 실행 상한으로 사용하지 않는다. 현재 작은 의존성 설치에 캐시를 추가할 근거는 부족하며, 수정 후 성공 실행의 시간도 확인한다.

코드의 `Windows tests`를 기존 main ruleset에 추가하고 기존 PR, 대화 해결, 선형 이력과 삭제/강제 push 방지 규칙을 보존했다. 결과 출처는 실제 성공을 보고한 GitHub Actions로 지정했다. 병합 전 최신 main을 포함하는 검사를 요구하는 기본 strict 방식을 사용한다. 다른 PR이 먼저 병합되면 작업 브랜치 최신화와 재검사가 필요할 수 있다. [GitHub의 strict/loose 비교](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)를 따른다. WIKI 필수 등록은 수정본의 실제 GitHub 성공 후 진행한다.

### Windows 루트 경로 판별 실패와 수정

첫 WIKI 실행에서는 테스트용 임시 Git 저장소를 최상위 폴더로 인정하지 못했다. 실패 지점은 Git이 보고한 경로와 Node.js의 `realpathSync` 결과를 문자열로 비교하는 부분이었다. 해당 로그에는 비교한 두 경로 값이 없어 GitHub 실행기에서 어떤 표기 차이가 생겼는지는 확정하지 않는다.

별도 Windows 재현에서 같은 폴더 경로를 대문자 또는 소문자로 전달하면 기존 검사가 실패했다. [Node.js의 realpath 설명](https://nodejs.org/download/release/latest-jod/docs/api/fs.html#fsrealpathpath-options-callback)은 대소문자를 구분하지 않는 파일시스템에서도 대소문자를 통일하지 않는다고 명시한다. 따라서 문자열 일치만으로 저장소 최상위 여부를 판단하는 전제를 제거한다.

`repositoryFiles(root)`는 [Git rev-parse](https://git-scm.com/docs/git-rev-parse.html)의 `--is-inside-work-tree`와 `--show-prefix`를 함께 사용한다. 작업 트리 안이고 최상위로부터의 상대 경로가 비어 있을 때만 파일 목록을 읽는다. 하위 폴더에서 일부 문서만 검사하거나 `.git`과 bare 저장소의 관리 파일을 검사하는 것은 계속 거부한다. 문서 링크에 적힌 파일명 자체의 대소문자 검사는 변경하지 않는다.

추가한 회귀 검사는 같은 루트의 대소문자 표기, `.git` 디렉터리, bare 저장소다. 수정 후보는 Windows에서 전체 27개와 WIKI 전체 링크 검사를 통과했다. 기존 실패를 무시하거나 검사를 줄이지 않았으며, GitHub 실행기에서 해결됐는지는 수정 커밋 후 같은 workflow로 다시 확인해야 한다.

## 외부 도구와 고지

| 도구 | 확인한 버전과 이용 조건 | 사용 범위 |
| --- | --- | --- |
| actions/checkout | [v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1), [MIT](https://github.com/actions/checkout/blob/3d3c42e5aac5ba805825da76410c181273ba90b1/LICENSE) | CI 작업 사본 준비 |
| actions/setup-python | [v7.1.0](https://github.com/actions/setup-python/releases/tag/v7.1.0), [MIT](https://github.com/actions/setup-python/blob/6d4fd22b20465ccc0f7354476588e8df7c9ca0e0/LICENSE) | CI Python 환경 선택 |
| actions/setup-node | [v7](https://github.com/actions/setup-node/tree/v7), [MIT](https://github.com/actions/setup-node/blob/v7/LICENSE) | WIKI CI의 Node.js 준비 |
| markdown-it | [15.0.3](https://www.npmjs.com/package/markdown-it/v/15.0.3), MIT | WIKI의 Markdown 문법 해석 |
| github-slugger | [2.0.0](https://www.npmjs.com/package/github-slugger/v/2.0.0), ISC | 제목의 GitHub식 식별자와 중복 번호 생성 |
| actionlint | [v1.7.12](https://github.com/rhysd/actionlint/releases/tag/v1.7.12), [MIT](https://github.com/rhysd/actionlint/blob/v1.7.12/LICENSE.txt) | 개발 중 workflow 정적 검사. 제품/CI 실행 의존성으로 추가하지 않음 |
| Gitleaks CLI | [v8.30.1](https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1), [MIT](https://github.com/gitleaks/gitleaks/blob/v8.30.1/LICENSE) | 이번 공개 대상과 Git 이력의 비밀값 탐지. 제품/CI 실행 의존성으로 추가하지 않음 |

외부 도구의 코드를 저장소에 복사하지 않는다. actionlint와 Gitleaks CLI는 공식 릴리스의 체크섬을 대조해 실행했다. 후자는 서버나 유료 GitHub Action을 설치한 것이 아니며, 발견 내용의 원문/비밀값을 출력하거나 보관하지 않는 방식으로 검사했다. Python의 검사 발견/실행/결과 판정은 [unittest의 공개 API](https://docs.python.org/3.13/library/unittest.html)를 사용한다.

WIKI 개발 의존성 8개의 실제 배포본에서 라이선스 파일을 확인했다. 직접 사용하는 두 패키지 외에 mdurl, linkify-it, punycode.js, uc.micro는 MIT, entities는 BSD-2-Clause, argparse는 PSF-2.0이다. 패키지의 원래 고지는 설치된 의존성에 보존되며 소스를 이 저장소나 제품 배포물에 복사하지 않는다. 갱신 시 잠금 파일, 이용 조건과 실제 검사 결과를 함께 검토한다.
