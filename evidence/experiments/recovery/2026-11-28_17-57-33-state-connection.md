# Windows 파일 DB의 연결과 트랜잭션

## 목적과 변경 범위

WIKI 연결 정보를 저장하기 전에, 작업 기록을 같은 SQLite DB에 안전하게 읽고 쓰는 기반을 확인했다. 기존 [저장 계약](../../../design/workflow/storage.md)의 조회/쓰기 구분, 명시적 트랜잭션과 실패 처리를 `oneploom/storage.py`에 옮긴 단계다. 현재 CLI에 저장 명령을 연결하거나 전체 제품 DDL을 적용한 결과는 아니다.

기존 설정 확인은 파일을 읽는 데서 끝났다. 이번 기반은 이미 준비된 상태 DB를 열고, 기대하는 DB 식별과 형식을 대조한 뒤 짧은 SQL 묶음을 처리한다. 성공과 실패에서 연결을 닫으며, commit 또는 연결 종료 오류를 곧바로 같은 작업의 재실행 근거로 사용하지 않는다.

## 코드의 책임

| 함수 | 입력과 역할 | 경계 |
| --- | --- | --- |
| `state_path` | Windows 절대 경로에서 실제 로컬 일반 파일 확인. 최종 파일의 hard link/reparse 거부 | 프로젝트 소유나 변경 승인을 증명하지 않음 |
| `check_identity` | 현재 트랜잭션에서 metadata 한 행의 DB 식별/정수 형식을 대조 | 전체 DDL/내용 무결성 검사를 대신하지 않음 |
| `transaction` | 기존 파일을 ro/rw로 열고 설정 재조회, BEGIN, 식별 확인, 호출 SQL, COMMIT/ROLLBACK과 close 처리 | 최초 생성/변환, 실제 파일 변경이나 사용자 대기를 수행하지 않음 |

호출자는 허용된 상태 위치와 실제 작업 사본의 소유를 먼저 확인해야 한다. 기대하는 schema_version은 호출 코드가 지원하는 번호이며 실행 시 임의로 바뀌지 않는다. 정상 조회에 모든 작업 이력을 읽거나 모델에 보내는 동작은 없다.

## 검증 환경과 결과

- Windows 11, OS 빌드 10.0.26300.
- Python 3.13.9, 포함된 SQLite 3.50.4, Windows Git 2.52.0.windows.1, PowerShell 5.1.26100.10068.
- 명령: `py -3 -B -X utf8 -W error::DeprecationWarning tools/run_tests.py`.
- 전체 **119개 통과**, 실패 0, 건너뜀 0. 그중 새 저장 검사 23개다.
- unittest가 보고한 전체 소요 시간은 **10.180초**다. 한 번의 전체 회귀 검사 관측이며 DB 지연의 벤치마크나 성능 개선 수치가 아니다.
- [전체 원시 출력](2026-11-28_17-57-33-state-connection.log)을 함께 보존했다. 이후 소스 변경은 이 결과의 입력과 다시 대조해야 한다.

시험은 실제 디스크 파일과 Python 표준 sqlite3를 사용했다. metadata와 두 관계, 중단 시험용 본문 테이블로 만든 작은 합성 DB이며 제품 schema.sql 전체를 대신하지 않는다.

| 사례 | 실제 관측 |
| --- | --- |
| 정상 쓰기와 재연결 | foreign_keys=1, journal_mode=delete, synchronous=3 확인. commit 뒤 새 연결에서 행 확인 |
| 조회만 수행하거나 조회 연결로 쓰기 시도 | 조회는 원래 바이트 보존. 쓰기 시도는 실패, 원래 DB 보존 |
| 한글/공백/#/%/&가 있는 파일명, 없는 DB/부모 | 같은 파일만 사용. 새 DB나 디렉토리 생성 없음 |
| DB 식별/형식 불일치, 잘못된 metadata, 빈 파일/손상 | 호출 SQL에 진입하지 않고 거부. 자동 초기화/변환 없음 |
| hard link와 디렉토리 | 실제 Windows 파일 사례에서 거부 |
| 기존 WAL 방식의 DB | 쓰기 거부. 조회로 WAL 유지 확인, DELETE로 변환하지 않음 |
| 두 번째 SQL의 외래키 위반 | 첫 번째로 삽입한 행도 rollback되어 재조회 결과 없음 |
| 다른 연결/별도 프로세스가 쓰기 중 | state_busy 반환. 먼저 실행한 작업의 완료 뒤 새 쓰기 가능 |
| 읽는 연결 때문에 writer commit이 막힘 | state_commit_failed 반환과 rollback. 기존 reader 관측과 재연결 결과 유지 |
| 시험 자식이 저장 도중 비정상 종료 | 4 MiB 합성 쓰기로 실제 hot journal을 남김. 읽기 전용 조회 실패 뒤 쓰기 연결에서 SQLite 자체 복구. 이전 commit만 유지하고 미commit 행/본문은 취소 |
| 본문 예외, KeyboardInterrupt, SystemExit | 주입한 예외가 전달되고 이전 SQL 취소와 연결 종료 확인 |
| sqlite3/API/필수 설정 부재, commit/rollback/close 오류 | 주입 검사. 준비 필요 또는 해당 오류를 구분. close 오류 전 commit된 행은 남아 재실행하면 안 됨을 확인 |

4 MiB는 실제 journal 복구를 관측하기 위한 시험 자료 크기다. 제품에 출력/파일 크기 제한을 추가한 값이 아니다. 자식 프로세스의 10초 정지 감지는 시험 보호 장치이며 제품 명령의 시간 제한이 아니다.

## 설계 근거와 선택

SQLite URI의 `ro`/`rw`는 기존 DB만 열며, 일반 connect의 암묵적 파일 생성과 구분된다. 경로는 파일 URI로 인코딩한 뒤 고정된 mode를 붙였다. [SQLite URI](https://www.sqlite.org/uri.html).

Python의 `autocommit=True`에서는 명시적 SQL로 트랜잭션을 제어한다. 외래키 설정은 BEGIN 전에 적용하고 결과를 다시 확인한다. [Python 트랜잭션 제어](https://docs.python.org/3.13/library/sqlite3.html#transaction-control-via-the-autocommit-attribute), [SQLite foreign_keys](https://www.sqlite.org/pragma.html#pragma_foreign_keys).

기존 DELETE + EXTRA 후보를 유지하며, 쓰기 잠금은 BEGIN IMMEDIATE에서 확인한다. 잠금은 현재 구현에서 기다리지 않고 원인을 반환한다. 읽는 작업 때문에 commit이 실패할 수도 있으므로 시작 성공과 저장 확정을 구분했다. [SQLite 트랜잭션](https://www.sqlite.org/lang_transaction.html), [저장 동기화](https://www.sqlite.org/pragma.html#pragma_synchronous), [hot journal 복구](https://www.sqlite.org/lockingv3.html#dealing_with_hot_journals).

별도 DB 엔진/서버나 Python 패키지를 설치하지 않았고 외부 구현 소스도 편입하지 않았다. 사용한 표준 라이브러리와 엔진의 이용 조건은 [Python 라이선스](https://docs.python.org/3.13/license.html)와 [SQLite 저작권 안내](https://www.sqlite.org/copyright.html)에서 확인했다. 런타임 자체를 배포물에 포함할 때의 고지는 해당 패키징 검토에서 별도로 다룬다.

## 남은 범위

- 최초 DB 생성, 전체 DDL과 승인 기록, 같은 작업의 중복/재시도 대조, 실제 설정 파일의 보존/반영은 아직 구현 전이다. 현재 DB 기반은 CLI가 호출하지 않는다.
- metadata 일치는 프로젝트 소유나 정품 설치, 전체 스키마의 정상성을 증명하지 않는다. 경로 확인과 실제 열기 사이의 교체 방지, 상태 루트의 보호 및 소유는 상위 파일 보호 절차와 함께 검증해야 한다.
- 진짜 디스크 장애, 전원 단절, 장치가 저장 요청을 지키지 않는 경우의 내구성은 확인하지 않았다. 시험 자식의 종료를 이 범위의 보장으로 확대하지 않는다.
- 실제 사용자 WIKI 변경, Codex 실행이나 AI 대화는 수행하지 않았다. 정상 DB 트랜잭션 성공을 파일 변경이나 전체 설치/복구의 성공으로 표시하지 않는다.
