# 현재 조건부 하네스 구조 감사

> 검토와 관측 기록. 검토 당시의 후보와 관측을 보존한다. 현재 채택 범위는 결정 목록에서 확인하며, 미실행 계획이나 예비 시험을 제품 검증 완료로 해석하지 않는다.

## 감사 상태와 총평

- 기준일: **2026-10-26**, 기준 HEAD: `f6e33dd56baa2a651a70d7d0b2cc3ebde6575153`.
- 최신 사용자 범위: **조사, 재현, 개선 계획 문서화만 수행한다. 실제 구조 변경 단계 전까지 `harness/**` 밖 파일을 생성, 수정 또는 삭제하지 않는다.**
- 관측은 당시 구현의 결과다. 수정 후보는 아래 설계 문서로 분리했으며 미채택, 미구현이다. 발견한 결함을 수정 완료로 표시하지 않는다.
- 이전 Q&A, draft-v1, 역할 분해안은 참고 자료다. 현재 코드, 계약, 재현 결과보다 우선하지 않는다.

현재 구조는 **메인이 필요한 컨텍스트와 독립 게이트를 선택하고, 스크립트와 lifecycle hook이 일부 실행, 복구를 보조하는 조건부 작업 체계**다. 파일만 놓으면 모든 정책이 강제되는 실행 엔진은 아니다.

설계의 방향은 유지할 가치가 있다. 조건부 읽기, 의미 판단과 기계 실행의 분리, 명시적 scope, 실패 후 선택적 재검증, 짧은 복구 상태는 실제 문제를 겨냥한다. 그러나 **현재 PASS가 원래 필요한 검증의 성공을 뜻하는지, active가 중단 직전 상태를 담는지에 중요한 빈틈이 있다.** 지금 상태를 신뢰성과 이식성이 검증된 배포용 하네스라고 평가하기는 어렵다.

우선순위는 로컬 모델 도입보다 **검증의 동일성, 증거 효력, 복구 시점, 실행기 호환성을 먼저 명확히 하는 것**이다. 이 판단은 현재 디렉토리나 모든 절차를 그대로 유지하자는 뜻이 아니다.

## 확인 범위와 근거의 강도

### 실제로 확인한 범위

- `AGENTS.md`와 추적 중인 `.codex` 25개 파일: config 6개, skill 10개, shell 5개, README 2개, hooks JSON, Python 각 1개.
- docs 전역 라우터와 discussions, decisions, guides, explainers, roadmap, contract, followup, runbook, learn 소유 README, 관련 템플릿.
- prompts 전역, topics, worklog README, governance topic, 조건부 전환 worklog, 복구 runbook.
- 루트 README, `.github/CONTRIBUTING.md`, PR 템플릿, CI, ignore 정책, 모듈 의존 선언.
- 코드 이력: 조건부 전환 worklog, compact guard 보완 커밋 `c4536fd`, 구현 검증 경량화 커밋 `d6e32f9`의 위치와 현재 결과.
- 로컬 CLI 버전 관찰값은 `codex-cli 0.164.0`. 현재 대화 클라이언트의 hook 신뢰, 발동을 이 버전 확인으로 증명하지 않는다.

제품 요구사항, API, 도메인 문서 전체의 내용 정확성을 감사한 것은 아니다. 해당 문서들이 하네스에서 어떤 근거 경로로 분류되는지 확인했다. `docs/**` 모두가 공통 하네스 코어인 것도 아니다.

### 실행 근거

| 근거 | 확인 내용 | 해석 한계 |
| --- | --- | --- |
| [관측 기록 (기존 script 기준선)](../../evidence/experiments/baseline/2026-10-22_19-21-37-script-baseline.md) | 16개 시나리오, assertion 36개 통과 | shell 분기 검사. 제품, 모델 품질 통과가 아님 |
| [관측 기록 (기존 경계 probe)](../../evidence/experiments/baseline/2026-10-22_19-57-14-structure-probes.md) | scope, PASS, 계획, 선택 테스트 등 관측 10건 | stub, 격리 입력의 실제 동작 |
| [관측 기록 (이번 복구, retry probe)](../../evidence/experiments/baseline/2026-10-26_19-03-55-recovery-retry-audit.md) | 명령 14회, 고정 관측 9건 일치 | 결함까지 관측한 결과. 정상 동작 9/9를 뜻하지 않음 |
| 기존 감사 입력 48개 SHA-256 대조 | 모두 변경 없음 | 기존 기준선을 재사용한 근거 |

이번 probe는 복사한 원본 스크립트, dummy 파일과 Gradle stub을 사용했다. 실제 Gradle, 모델 호출, quota 소진과 native compact 이벤트는 실행하지 않았다. 이 관측은 해당 격리 입력의 동작만 설명하며 실제 제품 실행 검증을 대체하지 않는다.

## 설계 의도와 현재 구현의 관계

| 설계 의도 | 현재 수단 | 평가 |
| --- | --- | --- |
| 작은 작업의 고정 비용 줄이기 | Direct/Scoped/Harness, 필요한 게이트만 ON | 방향은 타당. AGENTS, skill 목록의 기본 비용은 남음 |
| 필요한 문서만 읽기 | path-rule, docs-routing, prompts 기본 OFF | 의미 판단에 의존. 실제 읽기 허용 목록을 런타임이 강제하지 않음 |
| 규칙의 원본을 구분하기 | AGENTS → README → config, skill, script | 역할은 나뉘지만 실제 문장, 분기 규칙 중복이 존재 |
| 문서 최신화와 문서 체계 검사를 분리하기 | doc-impact/update와 doc-governance 분리 | 작은 코드 변경에 전체 문서 검사를 강제하지 않는 장점 |
| 계획 확인 비용 줄이기 | implementation의 dry-run JSON 우선 | 구조화 출력의 일관성, 실행 여부 구분을 보완해야 함 |
| 실패 비용 줄이기 | FAIL 보존, PASS 재사용, 선택 retry | 의존성 누락과 최초 검증 범위 유실 때문에 현재 보장 부족 |
| 긴 작업 복구 | active, scope, marker, snapshot | 의미 상태는 메인이 저장해야 하며 quota 자동 감지는 없음 |
| 선택적 위임 | bounded packet과 네 capability | 상시 다중 agent보다 절제돼 있으나 권한 제한은 주로 지시 계약 |

전환 worklog의 의도는 강한 기본 하네스에서 필요한 때만 확장하는 구조로 바꾸는 것이다. 이후 compact 이력에서는 stale마다 compact를 막던 방식을 snapshot 후 계속 진행하도록 바꿨다. 따라서 **stale인데 compact가 계속되는 것은 현재 의도된 동작**이다. 이를 무조건 중단하도록 되돌리면 압축을 반복 차단했던 문제가 재발할 수 있다.

## 전체 구조와 소유 위치

```text
요청 + 적용된 AGENTS
  └─ 메인: 작업 수준, scope, 게이트 선택
      ├─ 관련 경로 README, 공식 근거만 읽기
      ├─ 필요 시 skill → 필요한 config/script
      ├─ 수정과 계획 산출, 검증 실행
      ├─ FAIL/UNCLASSIFIED → 필요한 지점부터 복구
      └─ 결과, 미완료, 문서 영향을 통합해 완료 판단

독립된 세션 경로
  SessionStart / PreCompact / PostCompact
    └─ active 존재, scope, marker 확인 → 안내 / snapshot / 일부 중단

선택적 capability
  main → bounded subagent → main 검토, 통합
```

`Harness`는 모든 게이트가 순서대로 실행되는 모드가 아니다. skill도 별도 agent가 아니며, Markdown config도 실행 시 동적으로 읽히는 정책 엔진이 아니다.

### 규칙과 config, 문서

| 자산 | 실제 역할 |
| --- | --- |
| `AGENTS.md` | 진입 원칙, 작업 수준, 독립 게이트, 최종 판단 책임 |
| `.codex/README.md` | 보조 자산의 연결과 사용 경계 |
| `config/doc-update-matrix.md` | 문서 영향, 갱신, governance 변경 성격과 동반 문서 기준 |
| `config/doc-to-code-check-matrix.md` | 구현 검증 후보, 모듈별 floor, 예외 |
| `config/gate-state-contract.md` | PASS/FAIL/UNCLASSIFIED, 증거 효력과 재개 계약 |
| `config/failure-route-map.md` | 문서, 구현 검증 실패의 기존 runbook 후보 |
| `config/subagent-task-contract.md` | 메인 책임, 네 역할, packet, 통합 계약 |
| `config/doc-governance-search-excludes.txt` | 금지 참조 검색의 제외 glob. 다른 제외 정책 전체를 대체하지 않음 |
| `docs/README.md` | 공식 문서 라우터와 전역 작성 규칙 |
| `prompts/README.md` | 작업 기록 읽기와 쓰기 조건과 topic/worklog 구분 |

공식 Codex는 실행 시작 시 AGENTS 지침을 조합한다. 그 이후 어떤 README를 읽을지는 이 저장소의 지침이다. README 존재 자체가 자동 정책 실행을 뜻하지 않는다. [공식 AGENTS 문서](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

docs 내부의 역할은 다음과 같다.

| 경로 | 들어가는 정보 | 라우팅에서 주의할 점 |
| --- | --- | --- |
| REQUIREMENTS | 현재 유효한 제품 요구, 채택 정책 | 원본 헤더에는 draft 표기가 남아 있음. 채택 상태를 내용과 대조해야 함 |
| discussions → decisions | 검토 → 채택된 ADR | 매 작업마다 선행 로딩하지 않음. 보존해야 할 공식 근거 |
| guides | 구현 계약, 절차, 체크리스트 | 기능군별 공통/프론트/백엔드 문서. 하위 README 대신 공통 guideline이 역할 설명 |
| explainers | 구조, 동작, 배경 설명 | 구현 계약, 개인 학습과 구분 |
| roadmap | 기존 기능의 후속 과제 | 현재 요구사항으로 자동 취급하지 않음 |
| contract, platform, troubleshooting | 실제 서비스, 외부 연동의 계약과 운영 지식 | 주요 계약 경로인데 구현 후보 탐지에서 일부 빠짐 |
| runbook | 실패 축별 재현, 복구 | 정상 작업의 기본 읽기 대상이 아님 |
| followup | 현재 복구 상태 | 장기 사실 기록이나 정책 원본이 아님 |
| learn | 개인 학습 | 공식 근거, 공유 링크 대상에서 제외 |
| prompts/topics, worklog | 탐색 인덱스, 과거 수행 사실 | 현재 정책보다 우선하지 않음 |

`000-strategy-review-template.md`, `000-adr-template.md`, `000-active-task-template.md`, worklog `TEMPLATE.md`는 문서 입력 구조를 제공한다. 템플릿을 채웠다는 사실로 내용의 사실성이나 검증 완료가 보장되지는 않는다.

### Skill 연결

| Skill | 진입 조건과 역할 |
| --- | --- |
| docs-task-start | docs-routing 활성화 뒤 필요한 경로, 문서로 분기 |
| doc-governance-check | 문서 체계, workflow 계약 변경의 정합성 검사 |
| implementation-check | 제품 구현, 의미 있는 계약 변경의 테스트 선택, 실행 |
| followup-handoff | 긴 작업, 압축, 재개의 의미 상태 정리 |
| runbook-trigger | 실패, 반복 실수, 복구 신호에서 해당 축으로 분기 |
| verification-retry | 실제 FAIL을 받아 수정 후 동일 검증 재개 |
| subagent-orchestration | 선택 호출, packet 작성, 결과 통합 |
| commit-stage | 명시적으로 요청한 범위만 stage |
| commit-msg | 변경 근거로 커밋 메시지 작성 |
| commit-ready | 명시 요청 시 stage와 메시지 절차 조합 |

커밋 skill은 기본 개발 파이프라인이 아니다. 현재 세션에는 `.codex/skills`의 목록이 제공되지만, 공식 저장소 발견 경로는 `.agents/skills`로 안내된다. 현재 환경에서 보이는 사실과 다른 머신의 자동 발견 보장을 구분해야 한다. 공식 설명처럼 이름, 설명과 선택된 본문의 단계적 로딩을 유지하는 방향은 적절하다. [공식 skills 문서](https://learn.chatgpt.com/docs/build-skills)

### Script 연결

| Script | 입력과 출력, 실행 경계 |
| --- | --- |
| gate-common.sh | scope 수집, 해시, state 기록, dependency 비교 |
| check-doc-governance.sh | change-kind와 scope를 받아 일부 동반 문서, 금지 참조, active 개수 검사 |
| check-doc-implementation.sh | scope/change-kind → 계획; `--run`일 때 실제 Gradle 호출 |
| verify-and-retry.sh | FAIL state와 PASS state → REUSED/RECHECK 계획, 재실행 |
| check-harness-scenarios.sh | 임시 scope/state로 script 분기 회귀 검사. 제품, 모델 평가가 아님 |

`--scope-path`는 implementation에만 구현돼 있다. scripts README의 공통 옵션 설명을 모든 script에 그대로 적용하면 오류가 난다. `--scope-file`은 실제 파일을 요구하며, 없을 때 `git status` 전체를 fallback으로 사용한다.

### 런타임과 CI

현재 추적 자산에는 `.codex/config.toml`이나 역할별 실행 설정이 없다. Markdown config와 subagent 계약이 모델, provider, 실행 권한을 등록하는 것은 아니다.

CI는 제품 `clean test`, 빌드, 외부 계약, Compose 검증 등을 수행한다. 하네스 회귀 suite를 호출하는 연결은 찾지 못했다. CI의 성공을 하네스 동작 검증으로 치환할 수 없다.

active, scope, gate state는 ignore 대상이다. 다른 clone, 기기로 자동 전달되지 않으며, 한 디렉토리의 active 하나, 공유 marker는 동시 독립 세션용 상태 저장소가 아니다.

## 게이트별 실제 연결과 보장 수준

| Gate | 누가 결정, 수행하는가 | 실제 보장 경계 |
| --- | --- | --- |
| path-rule | 메인이 경로와 기존 패턴 확인 | 읽기 순서 준수는 모델 책임 |
| docs-routing | 메인 + docs-task-start | 라우터를 거쳐 대상 경로 선택 |
| doc-impact | 메인이 요청, diff로 DOC_* 판단 | script가 의미 판단하지 않음 |
| doc-update | DOC_REQUIRED 뒤 메인이 반영 | governance PASS와 별도 |
| requirements | 제품, 정책 의미 확인 시 메인 | 요구 변경, ADR 필요 여부 최종 판단 |
| skill | 메인 또는 호스트의 skill 선택 | 발견, 본문 읽기와 실제 절차 실행은 구분 |
| script | 메인이 필요한 명령 호출 | 호출되지 않으면 기계 검증도 없음 |
| implementation-verification | 메인 선택 + implementation script | 지정 scope에 계산된 테스트만 수행 |
| doc-governance | 메인 선택 + governance script | 일부 규칙만 기계 검사; 의미 품질은 미보장 |
| verification-retry | FAIL 뒤 메인 + retry script | 현재 최초 검증 범위 보존 결함 있음 |
| runbook | 메인이 실패 축 확정 | script의 경로 인자만으로 적합성 검증 안 됨 |
| followup | 메인 + 복구 skill + lifecycle hook | 의미 상태 작성은 메인; hook은 일부 보조 |
| prompts | 기록, 의도 복구 필요 시 메인 | 현재 정책이 아닌 과거 사실과 인덱스 |
| subagent | 메인이 bounded task 선택 | 서브 결과는 전체 완료가 아님 |

공통 gate 상태와 도메인 결과는 구분돼 있다. `UNCLASSIFIED`는 분류 대기이고 `DOC_UNDETERMINED`는 문서 영향 미확정이다. 이 구분 자체는 유용하지만 코드 전체에서 일관된 상태 schema로 강제되지는 않는다.

### 대표 흐름

1. **짧은 설명 요청:** 사용자 정보와 현재 지침으로 답할 수 있으면 Direct. 별도 문서, script를 열지 않는다.
2. **단일 API 구현 변경:** 관련 경로 확인 → DOC_* 판단 → implementation 계획 → 필요한 테스트. DOC_NONE이면 공식 문서 최신화 탐색을 열지 않는다.
3. **제품 계약 변경:** 관련 요구, guide, 계약과 구현 대조 → 문서 반영과 구현 검증을 각각 수행. 문서 체계를 바꾸지 않았다면 governance는 자동 ON이 아니다.
4. **검증 실패:** FAIL 원본 유지 → 원인 수정 → 영향받은 선행 PASS와 실패 검증만 재실행. 이것이 의도이며, 현재 script는 아래 E-012 조건에서 다른 테스트로 바뀔 수 있다.
5. **긴 작업:** 초기에 active 생성 → 상태가 바뀌는 checkpoint에서 최소 갱신 → compact 시 기계적 단서 → 재개 시 active와 요약 대조.
6. **하네스 자체 변경:** 필요한 script sanity/회귀를 메인이 직접 골라야 한다. 제품용 implementation 경로 탐지만 믿으면 하네스 코드 변경을 검증 완료로 오해할 수 있다.

## active가 사용량 제한 전에 갱신되지 않는 이유

### 현재 연결에서 확인된 원인

`followup-handoff/SKILL.md:17`은 잔여 사용량이 10% 미만으로 **보이는 경우**를 조건으로 적는다. 그러나 hook 입력을 소비하는 코드는 `cwd`를 사용하며, quota 값, 조회, 알림 연결은 없다. 임계값에 도달하면 스크립트를 실행하는 구성도 없다.

따라서 이 구조는 **에이전트가 경고를 실제로 전달받고, 지침을 적용하고, 쓰기 도구를 실행할 수 있을 때 갱신을 기대하는 구조**다. 사용자가 본 누락의 개별 사건 로그가 없어 마지막 실패 지점을 특정하지는 못하지만, “임계값 이전 자동 저장”을 보장할 연결이 없는 것은 코드로 확정된다.

```text
원하는 흐름
사용량 임박 감지 → 실행 가능한 시점에 의미 상태 저장 → 이후 중단 → 재개

현재 흐름
메인이 임박함을 인지하면 skill 적용 가능
  + 별도로 compact 이벤트가 발생하면 hook 실행
  + active가 없으면 hook은 그냥 계속 진행
```

계정 사용량 제한, 모델의 컨텍스트 한도, 파일 백업은 서로 다른 축이다. quota 소진이 compact 이벤트를 반드시 발생시키지 않는다. UI의 남은 사용량 표시가 모델에게 구조화 입력으로 전달된다고 가정해서도 안 된다. CLI의 `/status`는 사용자 확인 수단으로 안내된다. [공식 사용량 안내](https://learn.chatgpt.com/docs/pricing)

### Hook의 실제 효과

| 이벤트/조작 | 현재 코드 | 놓치기 쉬운 점 |
| --- | --- | --- |
| active 없음 | `continue: true` | 긴 작업인지 판단하거나 active를 만들지 않음 |
| PreCompact + 유효 marker | 계속 진행 | 의미 상태가 최신임을 검증하지 않음 |
| PreCompact + 일반 stale | snapshot 생성 후 계속 | active 본문은 그대로 |
| PostCompact | active, snapshot 확인을 `systemMessage`로 안내 | 모델 컨텍스트 주입과 같은 의미가 아님 |
| SessionStart | `additionalContext`로 active 확인 지시 | 파일 내용을 자동 읽거나 상태를 수정하지 않음 |
| mark | fingerprint, 시각 저장, snapshot 제거 | 실제로 읽고 갱신했는지 검증하지 않음 |

공식 계약에서 `systemMessage`는 UI/event 경고이며 `SessionStart.additionalContext`가 모델 문맥에 들어간다. `source: compact`도 지원하지만 현재 matcher에는 `fork`가 없다. quota 전용 이벤트는 문서화된 목록에 없다. project hook은 지원 클라이언트와 trust가 필요하며 cloud orchestration에는 로컬 hook 제약이 있다. 따라서 현재 세션에서 이벤트가 실제 발동했다고 단정하지 않는다. [공식 hooks 계약](https://learn.chatgpt.com/docs/hooks)

### 추천하는 복구 방향 — 아직 설계 후보

1. **기본 안전망은 상태 전환 checkpoint로 둔다.** 긴 작업 시작, scope, 결정, 검증 상태 변경, 외부 실행 전후, 미완료 턴 종료 때 갱신 필요 여부를 판단한다. 변경이 없으면 다시 쓰지 않는다.
2. **quota 신호는 추가 조기 경고로 둔다.** 공식 app-server의 `account/rateLimits/read`, `account/rateLimits/updated`를 이용할 수 있다. `usedPercent`, `windowDurationMins`, 갱신 시각, bucket을 확인하는 실행기 어댑터가 필요하다. 현재는 연결되지 않았다. [공식 app-server](https://learn.chatgpt.com/docs/app-server)
3. **의미 상태와 기계 상태를 나눈다.** 목표, 결정, 다음 행동은 메인이 작성하고, 실행 명령, 종료 상태, artifact, revision은 실행기가 저장하는 방향을 검토한다. snapshot은 전체 파일 백업이 아니다.
4. **중단 후 저장을 약속하지 않는다.** 이미 추론이 차단됐거나 프로세스가 죽었다면 새 의미 요약을 쓸 기회가 없을 수 있다. 확인할 목표는 직전 checkpoint 이후의 유실 범위를 줄이는 것이다.
5. **Stop 차단을 만능 해법으로 도입하지 않는다.** 공식 Stop 차단은 추가 continuation을 유도한다. 비용, 반복 방지와 quota 소진 조건을 확인해야 한다. Interrupt/SessionEnd도 모든 중단에 의미 상태 작성을 보장하는 경로가 아니다. [공식 lifecycle 동작](https://learn.chatgpt.com/docs/hooks)

기존 skill은 앞부분에서 checkpoint를 요구하면서 절차 6에서는 위험이 없으면 갱신하지 말라고 재차 제한한다. 모순이라고 단정하기보다, “복구할 정보가 바뀌었는가”와 “quota가 보이는가”를 따로 명시해 해석 여지를 줄이는 편이 낫다. 지침 보완만으로 자동 보장이 생기는 것은 아니다.

사용량 비율을 남은 raw token 수로 환산하거나 모든 환경의 window를 5시간, 주간으로 고정하지 않는다. 실제 계정, bucket이 제공하는 값과 신호가 없는 상태를 구분해야 한다. 10%라는 임계값도 마지막 저장을 보장하는 수학적 안전 여유는 아니다.

## 확인된 문제와 우선순위

P0는 외부 보안 등급이 아니라 **검증, 완료 신뢰를 위해 우선 다뤄야 하는 수준**이다. 반복 운영의 발생률은 아직 없다.

### P0: 검증 결과의 의미

**E-012 — 재시도가 최초 실패의 검증 범위를 바꿀 수 있다.** `verify-and-retry.sh`는 실패 gate/change-kind를 읽지만 실행 범위는 현재 전달된 scope로 다시 계산한다. state에 원래 실행 명령, 선택 테스트를 재실행 가능한 형태로 보존하지 않는다.

이번 격리 재현은 `API FAIL → core scope로 retry PASS → API는 여전히 FAIL`이었다. 실패 원본을 보존하는 기능은 작동했으나 “동일 검증 재개”는 지켜지지 않았다. 사용자나 메인이 잘못 좁힌 scope를 그대로 성공으로 닫을 수 있다는 반례다. 실제 프로젝트 테스트 실패가 은폐된 사건을 관측한 것은 아니다.

**E-005 — PASS 재사용의 의존 범위가 불완전하다.** 기존 probe에서는 gradlew가 성공에서 실패로 바뀌어도 API PASS가 REUSED였다. 이번에는 core 변경도 API PASS를 무효화하지 않았다. 실제 `sample-api/build.gradle`에는 core 의존성이 있지만 state에는 해당 전이 의존성이 없다.

현재 방식은 바뀐 파일 목록에서 dependency를 뽑는 것이어서 검증 도구, 공통 빌드 설정, 환경, 관련 모듈의 전체 영향 그래프와 같지 않다. Gradle도 결과 재사용 키에 task 구현과 입력을 포함한다. 이 원리를 하네스 증거에 적용하면 검증기의 버전과 실제 입력 범위가 빠진 PASS는 자동 재사용 근거로 부족하다. [Gradle cache key](https://docs.gradle.org/current/userguide/build_cache_concepts.html)

**E-005/E-007 — 표시한 테스트 범위와 실제 선택이 다르다.** `test` floor는 실행 시 API/core/infrastructure와 boot의 지정 9개 클래스로 펼쳐진다. matrix는 특정 테스트 하나 제외만 설명하지만 구현은 include allowlist다. 새 boot 테스트가 추가돼도 목록 밖이면 자동 포함되지 않는다. 일반 `./gradlew test`나 CI 전체 범위로 표현하면 안 된다.

2026-10-27 사용자 보충: 제외 사유는 팀원의 비공개 platform BOM 관련 자원에 접근할 수 없기 때문이다. 이 프로젝트의 예외로 유지하며 제외 자체를 하네스 결함으로 분류하지 않는다. 위 관찰에서 남는 검토는 의도한 제외와 실제 선택 범위가 일치하는지다. 접근 상태를 새로 시험하거나 기존 원시 재현을 바꾼 것은 아니다.

**E-007 — 계획, 비활성, 실행 결과가 혼동될 수 있다.** multi-module 계획에서 floor는 `test`지만 `requires_full_test=false`다. 이번에는 빈 배열이 `[]` 대신 `[""]`로 출력되는 것도 확인했다. dry-run JSON의 PASS는 계획 산출 성공이다. 실행 성공과 같은 의미로 소비하면 안 된다.

### P1: 복구와 라우팅

| 항목 | 확정 사실 | 영향과 남은 확인 |
| --- | --- | --- |
| E-011 quota 갱신 | 임계값은 자연어 조건, 입력, 이벤트 연결 없음 | 사용량 제한 전 저장 보장 불가. 개별 누락 사건 로그는 미확인 |
| E-006 scope 경계 | 상대 외부 경로 허용, 절대 외부 경로는 marker 없을 때 계속 | 경계 검사가 입력 표현, 상태에 따라 달라짐 |
| E-006 scope 파일 symlink | 저장소 밖 dummy scope를 연결해 mark 성공 | scope 자체의 해석 경계도 필요 |
| E-013 marker, 입력 복원력 | JSON 배열 marker에서 AttributeError, 잘못된 UTF-8에서 UnicodeDecodeError | 구조화된 실패 대신 예외. 실제 호스트의 실패 처리 별도 확인 필요 |
| E-013 시각 검증 | 1시간 미래 marker가 유효 처리됨 | 시계 변경, 잘못된 상태에 TTL 판단이 흔들림 |
| E-015 복구 지시 전달 | PostCompact는 UI 경고, SessionStart는 문맥 주입 | snapshot 안내 전달과 실제 재개 행동을 검증해야 함 |
| E-014 후보 경로 누락 | docs/contract, platform, 중첩 runbook, hook 경로 등이 일부 후보 정규식 밖 | 명시적 kind 없이 호출하면 후보 없음 PASS로 빠질 수 있음. 정적 확인 |
| E-014 하네스 자체 검증 | 제품 경로 위주 분기, CI에 하네스 suite 연결 없음 | Python/shell 의미 변경을 별도로 검증할 소유자 필요 |

scope 문제는 외부 dummy를 해시, 해석한 재현이다. 비밀 유출 사고로 표현하지 않는다. 상태 파일의 동시 쓰기, 부분 쓰기, 다중 세션 혼선은 코드상 위험이며 아직 동시 실행 재현을 하지 않았다.

### P2: 정합성과 운영 비용, 이식

- **E-008:** workflow-contract-change의 topic, worklog 필수 조건을 matrix가 정의하지만 script는 그 누락을 잡지 않는다. 필수 경로가 scope 목록에 있는지만 보는 검사도 실제로 필요한 내용이 최신화됐는지 증명하지 않는다.
- **E-009:** 루트 README의 모든 AI 작업 기록 요구와 AGENTS/prompts의 조건부 기록이 충돌한다. PR의 로그 경로 기대도 기록 없는 작업을 어떻게 표현할지 정리할 필요가 있다.
- **E-009:** `.github/CONTRIBUTING.md`는 현재 editor와 다른 auth 라이브러리 책임, 예외 규칙을 담고 있다. 단순 이름 치환으로 이식하면 잘못된 정책까지 옮겨진다.
- scripts README의 공통 `--scope-path` 설명은 실제 구현과 다르다. failure-route-map은 retry가 runbook 후보를 반환한다고 설명하지만 현재 retry 출력에는 해당 매핑이 없다.
- JSON 결과와 state 파일은 별도 포맷이며 schema 검증, 실제 실행 argv, 환경, 작업 ID가 충분하지 않다. `--json --run`도 단일 JSON 실행 결과 API로 설계돼 있지 않다.
- scope 없는 fallback의 `git status --short | awk '{print $2}'`는 공백, rename, quoted path에 취약하다. 이번에는 정적 위험으로 남긴다.
- `/usr/bin/python3`, Bash/GNU 도구, Git root 탐색, Codex trust, skills 발견을 전제한다. WSL에서 동작하는 것과 Windows native, 새 clone 호환은 다르다.
- README, topic, skill, matrix에 gate 책임 설명이 반복된다. topic의 현재 기준은 자체 가이드의 3~5개 bullet 권장보다 길어 상세 규칙을 재요약한다.
- GitHub 링크가 특정 repo/branch에 고정돼 있고 PR 템플릿은 다른 repo 링크도 사용한다. 현재 링크가 전부 깨졌다고 단정하지 않지만 이식 후 근거 이동 경로를 설계해야 한다.

## 장단점과 불필요한 비용

### 유지할 장점

- 필요한 때만 컨텍스트를 확장하는 방향은 작은 작업에 적합하다. 전체 docs, runbook, subagent를 기본 로딩하지 않는다.
- 정책 채택, 의미 판단과 파일 해시, 명령 실행의 역할을 구분했다. 로컬 보조를 붙여도 이 경계는 재사용할 수 있다.
- DOC_*와 검증 상태를 분리해 문서 최신화 때문에 무조건 전체 검증을 반복하지 않는다.
- FAIL 원본 보존과 등록 의존 변경의 RECHECK는 실제로 동작한다. 이미 해결된 Gradle 실패 전파도 stub에서 exit 1, FAIL로 확인됐다.
- active와 장기 worklog를 분리해 재개 비용을 줄이려는 의도가 분명하다.
- subagent는 상시 팀이 아닌 선택 기능이며 최종 통합은 메인이 소유한다.

### 비용이 생기는 위치

다음은 **파일 크기 측정**이며 토큰 추정치, 실제 로딩량이 아니다.

| 파일 | UTF-8 bytes | 줄 수 |
| --- | ---: | ---: |
| AGENTS.md | 16,842 | 160 |
| .codex/README.md | 6,696 | 44 |
| docs/README.md | 7,058 | 83 |
| doc-update-matrix.md | 14,980 | 323 |
| subagent-task-contract.md | 12,822 | 275 |
| followup-handoff/SKILL.md | 8,523 | 57 |
| docs/followup/README.md | 9,003 | 119 |

한 줄이 긴 문서도 많으므로 줄 수만으로 경량화를 평가할 수 없다. AGENTS의 기본 비용, 선택된 skill, 라우터의 중복, 복구 때 재독하는 양, 장문 도구 출력, 잘못된 PASS 뒤 재작업, 위임 packet, 메인 재검토가 모두 총비용에 들어간다. 현재 이 감사의 전체 읽기량을 평상시 개발의 읽기량으로 일반화하지 않는다.

실제 절약 여부는 같은 작업에서 입력, 캐시 입력과 출력, 재시도, subagent 사용량을 합쳐 측정해야 한다. 파일 크기 감소나 클라우드 호출 횟수 감소만으로 성공 작업당 총비용이 줄었다고 결론내릴 수 없다.

### 줄이거나 보류할 것

| 대상 | 제안 | 이유 |
| --- | --- | --- |
| README, topic의 상위 원칙 재서술 | 소유 위치 링크와 경로별 추가 규칙 중심으로 축소 | 중복 읽기, 문구 drift 감소 |
| followup 지침의 반복 문단 | checkpoint 판정, 작성, 복구 절차를 한 번씩 명확히 | quota 조건과 상태 변화 조건 혼동 감소 |
| 모든 작업의 로그 요구 | 의미 있는 작업, 복구 필요와 연결 | 기록 자체가 작업 비용이 되는 것을 방지 |
| 범용 provider, 상시 다중 agent 플랫폼 | 현재 단계에서는 보류 | 핵심 신뢰 경계 결함을 해결하지 못함 |
| 모든 tool 호출에 긴 hook 문맥 주입 | 기본안으로 채택하지 않음 | 실행 지연과 반복 컨텍스트 비용 |
| 같은 디렉토리의 상태 파일 무제한 추가 | 최소 의미 상태와 실행 증거의 수명 분리 | 복구 경로의 장기 로그화 방지 |
| 실제 효과 없는 packet 필드 | 읽기와 쓰기, 증거 식별의 필수 필드부터 검토 | 형식 충족이 안전성보다 앞서는 것을 방지 |

discussions, ADR, 실패 runbook을 통째로 없애는 것은 권하지 않는다. 지워야 할 것은 유효한 근거가 아니라 중복, 오래된 정책, 효과가 확인되지 않은 의무 절차다.

## 감사 이후의 설계

이 감사의 관측, 실행 결과는 당시 기준으로 보존한다. 2026-10-29 정리에서 뒤에 반복되던 구조, 개선 순서, 평가 기준은 각 소유 문서로 통합했다. 새 설계가 생겼다는 이유로 E-005, E-007, E-012 등의 결함을 해결 완료로 바꾸지 않는다.

- [구조와 책임](../../design/architecture.md): before/after와 scope, 검증, 복구, 이식의 수정 후보.
- [검증 계약](../../design/workflow/verification.md): 원래 검사 유지, 검사 선택/재사용 분리, 초기 자체 캐시 보류. 감사 당시의 후보와 이후 채택을 구분하며 현재 상태는 해당 계약과 [ADR 목록](../../decisions/README.md)을 따른다. 기존 결함의 수정 완료를 뜻하지 않는다.
- [수용 기준과 평가 기준](../../verification/acceptance.md): 실패/정상 대조, native 복구, 이식, 문서 보존, 실제 사용량의 별도 검증.
- [기술 검토 평가](alternatives.md): 공개 도구와의 차이와 배포 판단에 필요한 실증.
- [진행표](../../development/roadmap.md): 합의 → 범위표/복구 → 파일별 명세 → 개발 준비, 구현, 실제 이식의 순서.
- [현행 자산과 변경 명세](../../development/migration.md): 이후 채택한 책임을 현재 파일과 소비 연결에 대응한 첫 표. 이 감사의 관측을 다시 실행하거나 덮어쓴 결과가 아니다.

주력 트러블슈팅 후보는 원래 검증 범위 유실(E-012), 불완전한 PASS 무효화(E-005), checkpoint와 quota 신호 혼동(E-011)이다. 고정 관측은 개선율, 실서비스 장애율, 복구 성공률이 아니며, 수정 후 실제 결과가 있어야 성과를 주장할 수 있다.
