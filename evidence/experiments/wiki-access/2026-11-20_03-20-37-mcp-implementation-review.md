# MCP 후보의 구현 범위 검토

자료명은 관측에 사용한 근거를 식별한다. 개별 파일의 제공 범위는 [기록 기준](../../recording.md)을 따른다.

> 검토와 관측 기록. 검토 당시의 후보와 관측을 보존한다. 현재 채택 범위는 결정 목록에서 확인하며, 미실행 계획이나 예비 시험을 제품 검증 완료로 해석하지 않는다.

사용자 지정 2026-11-19 작업이다. 환경 날짜와 자동으로 TIL 경계를 바꾸지 않는다. 앞선 읽기 계약을 보존된 시험 소스에 대응한 **정적 검토**이며 후보 코드, SDK, Windows Codex나 모델을 실행한 결과가 아니다.

## 입력과 확인한 차이

입력은 [읽기 명세](../../../design/integration/mcp.md), [수용 기준 — 「MCP 읽기 보완의 검증 입력」](../../../verification/acceptance.md), [앞선 분포/설정 파싱](2026-11-20_00-33-30-mcp-read-contract.md)과 [11/18 시험 소스](2026-11-18_18-45-45-mcp-read-fidelity.md)다. 실제 읽은 소스 네 개의 해시와 관찰은 inspection.json 기록에 남겼다. 옛 코드를 수정하거나 임의 상한 시험을 다시 실행하지 않았다.

| 차이 | 구현 준비에 반영한 내용 |
| --- | --- |
| 파일 전체/줄 배열과 전체 검색 결과를 메모리에 적재 | 원문 처리와 페이지 생성의 스트리밍 후보. 전체 본문 보관을 피하되 원문 변경 확인 비용은 별도로 측정 |
| 읽기는 다음 줄, 검색은 결과 번호로 이어감 | 원래 요청, 원문 기준과 바이트 위치를 담은 cursor로 통일. 기존 프로세스 HMAC 책임 재사용 후보 |
| Python의 정수 타입 검사와 JSON Schema의 정수 의미 차이 | 1과 1.0의 일치, 소수부/불리언/숫자 문자열/비유한 값의 거부를 명세와 수용 입력에 함께 보정 |
| casefold, query.strip, 100자 제한과 숨김 문서 일괄 제외 | 리터럴/대소문자 구분/공백 보존과 허용 집합을 명시. 보호 경로를 푸는 수정과 구분 |
| WIKI를 시험 부모 폴더 아래로 제한 | 합성 시험의 보호 경계와 배포 제품의 내부/외부 등록 연결을 구별. 그 제약을 풀어 기존 실사용 결과로 재표시하지 않음 |
| async handler에서 긴 동기 파일/검색 호출 | 실제 취소 전달, 통신 루프와 파일 I/O 분리, 자원 정리와 늦은 결과 처리의 미실행 입력 추가 |
| 수기 MCP 포장 크기와 object만 선언한 출력 schema | 논리 결과, 실제 전송/호스트 수신 계수 분리. 성공/오류 필드와 진행 정보 검증을 후보에 연결 |

HMAC cursor 후보는 요청마다 본문을 다시 읽을 수 있다. 새로운 조회 DB/캐시 수명 관리가 없다는 이점과 반복 I/O 비용을 같이 기록했다. 정렬된 경로/식별 정보의 메모리 비용도 남는다. 한 번의 파일별 확인을 전체 WIKI의 원자적 스냅샷으로 설명하지 않는다.

## 공식 근거와 적용 범위

- [JSON Schema 숫자](https://json-schema.org/understanding-json-schema/reference/numeric): integer는 표기보다 값의 정수 여부를 판단한다. Python 언어 타입만으로 같은 입력을 다르게 처리하던 후보를 보정한 근거다.
- [JSON Schema 조건부 검증](https://json-schema.org/understanding-json-schema/reference/conditionals): 초기/이어 입력의 조건을 표현할 수단이다. 현재 SDK의 schema/호스트 전달 검증을 완료했다는 뜻은 아니다.
- [MCP 페이지](https://modelcontextprotocol.io/specification/2025-11-25/server/utilities/pagination): 불투명 cursor 개념을 참고했다. 표준 list 연산과 우리 도구 인자는 구별한다.
- [Python HMAC](https://docs.python.org/3.13/library/hmac.html): 기존 무결성 확인 책임의 재사용 근거다. 새 인증 저장소나 암호화를 채택한 것이 아니다.
- [Python I/O 실행](https://docs.python.org/3.13/library/asyncio-task.html#asyncio.to_thread), [MCP 취소](https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/cancellation): 통신 루프 차단 위험과 취소 뒤 자원/늦은 결과 처리의 근거다. 스레드 취소가 자동 완료된다고 가정하지 않는다.
- [Python 파일 읽기](https://docs.python.org/3.13/library/functions.html#open), [파일 정보](https://docs.python.org/3.13/library/os.html#os.stat): 원문 바이트/줄바꿈과 Windows 식별 필드의 책임을 확인했다. 앞선 Windows 실측을 새 실행으로 세지 않는다.

외부 구현 본문이나 템플릿을 복사하지 않고 원리를 우리 설계로 설명했다. 신규 의존성 설치/변경/배포는 없으며 공식 SDK의 최종 배포 조건 검토는 실제 채택/포함 범위가 정해질 때 유지한다.

## 보존과 다음 순서

백업은 2026-11-20 03:19:22 KST 생성 백업(식별자 `L40ZxHTI`)다. 기존 문서 세 개의 후보/검증/진행을 함께 수정하고 이 근거를 추가했다. 원문, 사본, 과거 소스, 조회한 사용자 설정과 제품 Git/index 보존은 문서 검사 기록과 최종 검토 기록에 기록한다. 처음 문서 패치의 문맥 일치 실패는 파일 변경 전에 중단됐고, 해당 문맥을 바로잡아 적용했다. 런타임 검증 실패로 계산하지 않는다.

다음은 [정한 범위 — 「구현과 회귀검사의 범위」](../../../design/integration/mcp.md)의 후보 코드/공통 설정과 Windows 검증 입력 준비다. 허용 집합과 경로 보호, SDK 취소 전달, 실제 호스트 수신 관측을 구체화한다. 새 AI 실행은 입력/모델/반복/비용을 확인한 뒤 진행하고 기존 실제 답변 PARTIAL이나 SDK FAIL을 이번 문서 검사로 통과시키지 않는다. MCP 첫 제공, 쓰기/복원이나 제품 전체 개발 착수는 이번에 확정하지 않았다.
