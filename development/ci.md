# 개발 검증 CI

## 검사별 책임

코드와 WIKI의 변경을 GitHub에서 자동 검사하는 개발 도구다. 사용자 프로젝트에 설치할 조건부 검증 기능과는 별도다. 공통 실행 규칙과 코드 검사 명령은 [코드 CONTRIBUTING의 「검사와 문서」](https://github.com/OnePLoom/oneploom/blob/main/CONTRIBUTING.md#검사와-문서)가 소유한다.

| 검사 | 확인할 범위 | 현재 단계 |
| --- | --- | --- |
| 코드의 Windows tests | 기존 명령/프로젝트 발견 테스트 전체와 실패 전달 | workflow 작성과 로컬 Windows 검사 완료. GitHub 실행과 필수 등록 전 |
| WIKI 내부 링크 | 저장소 내부 문서 파일과 섹션의 연결 | 후속 구현 예정 |

작업의 범위와 전체 완료 조건은 [공통 이슈 4](https://github.com/OnePLoom/oneploom/issues/4)에 연결한다. 한쪽 로컬 검사가 끝났다는 이유로 두 저장소의 CI 구성이 완료됐다고 판단하지 않는다.

## Windows 검사 환경을 고른 이유

현재 제품의 첫 대상은 Windows이며, 기존 테스트에는 Windows 사용자 폴더 API, 파일 공유 거부와 PowerShell 호출이 있다. Linux에서 건너뛴 Windows 검사를 성공으로 계산하지 않도록 Windows 실행기를 사용한다. GitHub가 제공하는 `windows-2025`는 Windows Server 2025이므로 실제 Windows 11의 설치와 사용 검증을 대신하지 않는다. [실행기 이미지의 공개 구성](https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-Readme.md)에서 설치 도구와 이미지 변경을 확인할 수 있다.

Python은 현재 직접 검증한 3.13 계열로 시작한다. 검사를 실행한 정확한 패치 버전, Git과 PowerShell 버전은 로그로 확인한다. 실행기 기본 Python에 맡기면 이미지 변경에 따라 검사 환경이 바뀔 수 있어 공식 `setup-python`으로 선택한다. 이는 CI의 검사 환경이며 배포 사용자의 Python이나 Codex 버전을 강제로 바꾸는 기능이 아니다. 다른 지원 버전은 실제 호환성 검증 범위가 정해질 때 추가한다. [GitHub의 Python 검사 안내](https://docs.github.com/en/actions/tutorials/build-and-test-code/python)를 참고했다.

## 실패와 중복 실행

PR은 병합 대상과 합쳐질 변경을 검사하고, main push는 실제 반영된 상태를 확인한다. 작업 브랜치의 push에 별도 실행을 추가하지 않아 같은 제출을 push와 PR에서 반복 검사하는 비용을 줄인다. 필수 검사에서 경로 필터로 실행 자체를 건너뛰면 결과가 계속 대기할 수 있으므로 PR에 파일 경로 필터를 두지 않는다. 같은 PR 또는 같은 이벤트/참조에 새 실행이 생기면 이전 실행을 취소하고 최신 결과를 확인한다. [workflow 실행 조건과 동시 실행 제어](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)를 따른다.

현재 테스트는 하나도 발견하지 못하거나 하나라도 건너뛰면 실패로 처리한다. 오류를 발견하지 않았다는 사실과 필요한 검사를 모두 수행했다는 사실을 구분하기 위한 기준이다. 의도적인 선택 검사가 필요해지면 실행 조건, 필수 범위와 결과 표현을 함께 검토한다. 준비 실패, 테스트 실패와 시간 초과도 성공으로 바꾸지 않는다.

저장소 읽기 권한만 사용하고 별도 개인 토큰이나 다른 저장소의 자격증명을 전달하지 않는다. 공식 Actions는 전체 커밋 SHA로 지정한다. 태그 변경으로 실행 코드가 바뀌는 위험을 줄이는 대신, 업데이트 시 새 버전의 호환성과 고지를 다시 확인해야 한다. [GitHub의 최소 권한과 Actions 고정 지침](https://docs.github.com/en/actions/reference/security/secure-use)을 참고했다.

## 검증 상태

2026-11-28 로컬 Windows 검사 결과다. GitHub의 호스팅된 실행 결과와 구분한다.

| 확인 | 관측 |
| --- | --- |
| 환경 | Windows 11, Python 3.13.9, Git 2.52.0.windows.1, Windows PowerShell 5.1.26100.10068 |
| 기존 테스트 | workflow의 동일 검사 코드로 59개 통과, 실패/건너뜀 없음 |
| 실패 전달 | 합성 입력 6개: 정상은 종료 코드 0, 실패/건너뜀/빈 검사/로딩 오류/폐기 예정 API 경고는 종료 코드 1 |
| 정적 구문 | actionlint 1.7.12에서 workflow 오류 없음 |
| 원격 실행 | 아직 미실행. PR의 실제 실행 결과 확인 필요 |
| 필수 검사 | 아직 미등록. 성공 결과와 실제 check 이름을 확인한 뒤 등록 |

처음 로컬 실행에서는 WSL에서 Windows로 전달한 Python 환경 변수 세 개가 누락돼 경고 오류화 조건이 적용되지 않았다. Windows 프로세스에서 환경을 구성하도록 시험 실행부를 수정한 뒤 기존 59개와 합성 입력 6개 전체를 다시 확인했다. 수정 전 통과 결과를 CI와 동일한 조건의 근거로 재사용하지 않았다. workflow 자체의 GitHub 환경 변수 전달을 검증한 결과로 확대하지 않는다.

정적 구문 검사는 GitHub의 권한, 실행기 준비, 이벤트 발동이나 필수 검사 연결을 증명하지 않는다. 다음 단계에서 최신 제출의 실제 GitHub 성공과 main 보호 설정을 확인한다. 실행 방법과 실패 시 재실행 절차는 코드 CONTRIBUTING의 「Windows CI」를 따른다.

## 외부 도구와 고지

| 도구 | 확인한 버전과 이용 조건 | 사용 범위 |
| --- | --- | --- |
| actions/checkout | [v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1), [MIT](https://github.com/actions/checkout/blob/3d3c42e5aac5ba805825da76410c181273ba90b1/LICENSE) | CI 작업 사본 준비 |
| actions/setup-python | [v7.1.0](https://github.com/actions/setup-python/releases/tag/v7.1.0), [MIT](https://github.com/actions/setup-python/blob/6d4fd22b20465ccc0f7354476588e8df7c9ca0e0/LICENSE) | CI Python 환경 선택 |
| actionlint | [v1.7.12](https://github.com/rhysd/actionlint/releases/tag/v1.7.12), [MIT](https://github.com/rhysd/actionlint/blob/v1.7.12/LICENSE.txt) | 개발 중 workflow 정적 검사. 제품/CI 실행 의존성으로 추가하지 않음 |

외부 도구의 코드를 저장소에 복사하지 않는다. actionlint는 공식 릴리스의 체크섬을 대조해 실행했다. Python의 검사 발견/실행/결과 판정은 [unittest의 공개 API](https://docs.python.org/3.13/library/unittest.html)를 사용한다.
