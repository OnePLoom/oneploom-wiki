# OnepLoom WIKI

OnepLoom의 개발 지식을 관리하는 독립 저장소다. 요구사항과 상세 설계뿐 아니라 토의, 대안과 선택 이유, 실패한 가설, 검증 계획과 실제 결과를 함께 보존한다. 제품 사용 안내는 [코드 저장소](https://github.com/OnePLoom/oneploom)의 README가 맡는다.

## 현재 상태

설계와 개발 준비 단계다. 실행 가능한 제품, 설치기와 릴리스는 아직 없다. 상세 설계, 토의와 검증 계획은 이 저장소에서 주제별로 확인할 수 있다.

과거 예비 코드/SQL 검사와 실제 Codex 시험은 제품 구현 완료와 구분한다. 문서가 상세하다는 사실, 설계가 채택됐다는 사실, 구현과 검증이 끝났다는 사실은 서로 다르다.

## 읽는 순서

| 알고 싶은 것 | 시작 문서 |
| --- | --- |
| 제품 목적과 첫 제공 범위 | [요구사항](REQUIREMENTS.md) |
| 전체 책임과 현재 구조 | [아키텍처](design/architecture.md), [설계 안내](design/README.md) |
| 코드/WIKI의 소유와 개발 순서 | [개발 공간](development/workspace.md), [진행 순서](development/roadmap.md) |
| 상세 설치/실행/상태/복원 계약 | [주제별 설계](design/README.md) |
| 왜 선택했고 무엇을 기각했는가 | [토의](discussions/README.md), [결정 24개](decisions/README.md) |
| 어떤 조건에서 시험할 것인가 | [검증 계획](verification/README.md), [상세 수용 입력](verification/acceptance.md) |
| 실제로 무엇이 확인됐는가 | [관측과 한계](evidence/README.md), [문제 대장](evidence/issues.md), [MCP 비교 사례](evidence/cases/mcp-cost.md) |
| 개념 설명이 필요한가 | [기술 설명](explanations/README.md) |

## 문서별 책임

요구사항은 기대 동작, 설계는 처리 계약, 토의는 선택 전후의 논거, ADR은 결정 상태와 변경 이유, 검증 문서는 시험 조건과 관측을 소유한다. 같은 상세를 여러 곳에서 따로 갱신하지 않고 필요한 곳으로 연결한다.

문서 역할과 변경 검토 기준은 [문서 관리](development/documentation.md)가 소유한다. 설계 채택, 구현과 실제 검증 상태를 구분하고, 관측에는 입력 조건과 결과의 한계를 함께 기록한다.

## 연결과 변경

저장소 안의 Markdown 상대 파일 링크를 사용한다. GitHub와 Obsidian의 제목 링크 해석이 달라 파일 링크 옆의 「정확한 절 제목」으로 읽을 위치를 안내한다. 문서 이동 시 대상 파일과 해당 절의 존재를 함께 검사한다.

코드와의 대응은 실제 두 커밋/PR로 연결한다. 원격 주소는 [개발 공간 — 「코드와 WIKI」](development/workspace.md)에 정리했다. 실제 생성된 SHA와 PR 링크만 사용하고, 로컬 기록과 원격 게시 완료를 구분한다. 초기 커밋, 기본 모듈의 동작 검증 완료, 첫 릴리스는 별개의 단계다.
