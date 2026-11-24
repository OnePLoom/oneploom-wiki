-- 설계 후보. 빈 시험 DB용 DDL이며 설치기나 기존 DB의 갱신 스크립트가 아니다.
-- 연결별 foreign_keys=ON 확인과 명시적 트랜잭션은 호출자의 책임이다.
-- JSON 형식, 실제 파일/입력, 사용자 허용과 완료 의미는 storage.md의 저장 계약으로 검사한다.

-- 형식과 요청
CREATE TABLE metadata (
    singleton INTEGER NOT NULL PRIMARY KEY CHECK (singleton = 1),
    schema_version INTEGER NOT NULL CHECK (typeof(schema_version) = 'integer' AND schema_version > 0),
    db_id TEXT NOT NULL UNIQUE CHECK (typeof(db_id) = 'text' AND length(trim(db_id)) > 0)
);

CREATE TABLE tasks (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    target_json TEXT NOT NULL CHECK (typeof(target_json) = 'text' AND length(target_json) > 0),
    request_json TEXT NOT NULL CHECK (typeof(request_json) = 'text' AND length(request_json) > 0),
    created_at TEXT NOT NULL CHECK (length(created_at) > 0),
    current_change_plan_id TEXT,
    current_verification_plan_id TEXT,
    current_choice_id TEXT,
    revision INTEGER NOT NULL DEFAULT 0 CHECK (typeof(revision) = 'integer' AND revision >= 0),
    FOREIGN KEY (id, current_change_plan_id) REFERENCES plans(task_id, id),
    FOREIGN KEY (id, current_verification_plan_id) REFERENCES plans(task_id, id),
    FOREIGN KEY (id, current_choice_id) REFERENCES choices(task_id, id)
);

CREATE TABLE plans (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    task_id TEXT NOT NULL REFERENCES tasks(id),
    kind TEXT NOT NULL CHECK (kind IN ('verification', 'change', 'maintenance')),
    previous_id TEXT CHECK (previous_id IS NULL OR previous_id <> id),
    reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    context_json TEXT NOT NULL CHECK (typeof(context_json) = 'text' AND length(context_json) > 0),
    details_json TEXT NOT NULL CHECK (typeof(details_json) = 'text' AND length(details_json) > 0),
    created_at TEXT NOT NULL CHECK (length(created_at) > 0),
    UNIQUE (task_id, id),
    UNIQUE (task_id, kind, id),
    FOREIGN KEY (task_id, kind, previous_id) REFERENCES plans(task_id, kind, id)
);

CREATE TABLE checks (
    plan_id TEXT NOT NULL REFERENCES plans(id),
    check_id TEXT NOT NULL CHECK (typeof(check_id) = 'text' AND length(trim(check_id)) > 0),
    requirement TEXT NOT NULL CHECK (requirement IN ('required', 'not_required', 'undetermined')),
    reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    stage TEXT NOT NULL CHECK (stage IN ('minimum', 'completion', 'ci')),
    execution_policy TEXT NOT NULL CHECK (execution_policy IN ('fresh', 'tool_reuse')),
    details_json TEXT NOT NULL CHECK (typeof(details_json) = 'text' AND length(details_json) > 0),
    PRIMARY KEY (plan_id, check_id)
);

-- 변경 계획의 의무와 논리적인 변경. 실제 파일별 사본은 attempt_files가 소유한다.
CREATE TABLE units (
    plan_id TEXT NOT NULL REFERENCES plans(id),
    unit_id TEXT NOT NULL CHECK (typeof(unit_id) = 'text' AND length(trim(unit_id)) > 0),
    requirement TEXT NOT NULL CHECK (requirement IN ('required', 'not_required', 'undetermined')),
    apply_verification TEXT NOT NULL CHECK (apply_verification IN ('required', 'not_required', 'undetermined')),
    restore_verification TEXT NOT NULL CHECK (restore_verification IN ('required', 'not_required', 'undetermined')),
    completion_json TEXT NOT NULL CHECK (typeof(completion_json) = 'text' AND length(completion_json) > 0),
    PRIMARY KEY (plan_id, unit_id)
);

CREATE TABLE unit_dependencies (
    plan_id TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    predecessor_id TEXT NOT NULL CHECK (predecessor_id <> unit_id),
    PRIMARY KEY (plan_id, unit_id, predecessor_id),
    FOREIGN KEY (plan_id, unit_id) REFERENCES units(plan_id, unit_id),
    FOREIGN KEY (plan_id, predecessor_id) REFERENCES units(plan_id, unit_id)
);

CREATE TABLE unit_requirements (
    plan_id TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('apply', 'restore')),
    verification_plan_id TEXT NOT NULL,
    check_id TEXT NOT NULL,
    PRIMARY KEY (plan_id, unit_id, kind, verification_plan_id, check_id),
    FOREIGN KEY (plan_id, unit_id) REFERENCES units(plan_id, unit_id),
    FOREIGN KEY (verification_plan_id, check_id) REFERENCES checks(plan_id, check_id)
);

CREATE TABLE changes (
    plan_id TEXT NOT NULL,
    change_id TEXT NOT NULL CHECK (typeof(change_id) = 'text' AND length(trim(change_id)) > 0),
    unit_id TEXT NOT NULL,
    position INTEGER NOT NULL CHECK (typeof(position) = 'integer' AND position >= 0),
    action TEXT NOT NULL CHECK (action IN ('create', 'modify', 'delete', 'rename')),
    details_json TEXT NOT NULL CHECK (typeof(details_json) = 'text' AND length(details_json) > 0),
    candidate_id TEXT,
    PRIMARY KEY (plan_id, change_id),
    UNIQUE (plan_id, unit_id, change_id),
    UNIQUE (plan_id, unit_id, position),
    FOREIGN KEY (plan_id, unit_id) REFERENCES units(plan_id, unit_id),
    FOREIGN KEY (plan_id, candidate_id) REFERENCES artifacts(plan_id, id)
);

-- 시도와 관측. sequence는 시계 대신 요청 안의 준비 순서를 식별한다.
CREATE TABLE attempts (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    task_id TEXT NOT NULL,
    plan_id TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('verify', 'apply', 'restore', 'handoff', 'backup', 'migrate', 'cleanup')),
    unit_id TEXT,
    previous_id TEXT CHECK (previous_id IS NULL OR previous_id <> id),
    restore_of TEXT CHECK (restore_of IS NULL OR restore_of <> id),
    sequence INTEGER NOT NULL CHECK (typeof(sequence) = 'integer' AND sequence > 0),
    input_json TEXT NOT NULL CHECK (typeof(input_json) = 'text' AND length(input_json) > 0),
    command_json TEXT,
    active_hash TEXT CHECK (active_hash IS NULL OR (length(active_hash) = 64 AND active_hash NOT GLOB '*[^0-9a-f]*')),
    state TEXT NOT NULL CHECK (state IN ('prepared', 'running', 'ended', 'unknown')),
    reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    unresolved_reason TEXT CHECK (unresolved_reason IS NULL OR length(trim(unresolved_reason)) > 0),
    process_json TEXT,
    created_at TEXT NOT NULL CHECK (length(created_at) > 0),
    ended_at TEXT CHECK (ended_at IS NULL OR length(ended_at) > 0),
    exit_code INTEGER CHECK (exit_code IS NULL OR typeof(exit_code) = 'integer'),
    cancel_requested_at TEXT,
    revision INTEGER NOT NULL DEFAULT 0 CHECK (typeof(revision) = 'integer' AND revision >= 0),
    UNIQUE (task_id, id),
    UNIQUE (plan_id, id),
    UNIQUE (plan_id, unit_id, id),
    UNIQUE (task_id, sequence),
    FOREIGN KEY (task_id, plan_id) REFERENCES plans(task_id, id),
    FOREIGN KEY (plan_id, unit_id) REFERENCES units(plan_id, unit_id),
    FOREIGN KEY (task_id, previous_id) REFERENCES attempts(task_id, id),
    FOREIGN KEY (plan_id, unit_id, restore_of) REFERENCES attempts(plan_id, unit_id, id),
    CHECK ((kind IN ('apply', 'restore') AND unit_id IS NOT NULL)
        OR (kind IN ('verify', 'handoff', 'backup', 'migrate', 'cleanup') AND unit_id IS NULL)),
    CHECK ((kind = 'restore' AND restore_of IS NOT NULL) OR (kind <> 'restore' AND restore_of IS NULL)),
    CHECK ((kind = 'verify' AND command_json IS NOT NULL AND length(command_json) > 0)
        OR (kind <> 'verify' AND command_json IS NULL AND process_json IS NULL AND exit_code IS NULL)),
    CHECK (state <> 'ended' OR ended_at IS NOT NULL),
    CHECK (state <> 'unknown' OR unresolved_reason IS NOT NULL)
);

CREATE TABLE attempt_checks (
    attempt_id TEXT NOT NULL,
    plan_id TEXT NOT NULL,
    check_id TEXT NOT NULL,
    PRIMARY KEY (attempt_id, check_id),
    FOREIGN KEY (plan_id, attempt_id) REFERENCES attempts(plan_id, id),
    FOREIGN KEY (plan_id, check_id) REFERENCES checks(plan_id, check_id)
);

CREATE TABLE artifacts (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    plan_id TEXT NOT NULL REFERENCES plans(id),
    attempt_id TEXT,
    role TEXT NOT NULL CHECK (role IN ('candidate', 'before_image', 'log', 'report', 'assessment')),
    root TEXT NOT NULL CHECK (root IN ('code', 'wiki', 'state')),
    path TEXT NOT NULL CHECK (length(path) > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64 AND sha256 NOT GLOB '*[^0-9a-f]*'),
    UNIQUE (plan_id, id),
    UNIQUE (attempt_id, id),
    FOREIGN KEY (plan_id, attempt_id) REFERENCES attempts(plan_id, id),
    CHECK ((role = 'candidate' AND attempt_id IS NULL)
        OR (role IN ('before_image', 'log', 'report') AND attempt_id IS NOT NULL)
        OR role = 'assessment')
);

CREATE TABLE results (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    attempt_id TEXT NOT NULL,
    check_id TEXT NOT NULL,
    previous_id TEXT UNIQUE CHECK (previous_id IS NULL OR previous_id <> id),
    source TEXT NOT NULL CHECK (source IN ('executed', 'tool_reused', 'not_run')),
    conclusion TEXT NOT NULL CHECK (conclusion IN ('pass', 'fail', 'undetermined')),
    reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    observed_at TEXT NOT NULL CHECK (length(observed_at) > 0),
    UNIQUE (attempt_id, id),
    UNIQUE (attempt_id, check_id, id),
    FOREIGN KEY (attempt_id, check_id) REFERENCES attempt_checks(attempt_id, check_id),
    FOREIGN KEY (attempt_id, check_id, previous_id) REFERENCES results(attempt_id, check_id, id),
    CHECK (source <> 'not_run' OR conclusion <> 'pass')
);
CREATE UNIQUE INDEX results_first ON results(attempt_id, check_id) WHERE previous_id IS NULL;

CREATE TABLE result_artifacts (
    result_id TEXT NOT NULL,
    artifact_id TEXT NOT NULL,
    attempt_id TEXT NOT NULL,
    PRIMARY KEY (result_id, artifact_id),
    FOREIGN KEY (attempt_id, result_id) REFERENCES results(attempt_id, id),
    FOREIGN KEY (attempt_id, artifact_id) REFERENCES artifacts(attempt_id, id)
);

-- 변경 준비와 실제 파일별 관측
CREATE TABLE attempt_changes (
    attempt_id TEXT NOT NULL,
    plan_id TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    change_id TEXT NOT NULL,
    PRIMARY KEY (attempt_id, change_id),
    FOREIGN KEY (plan_id, unit_id, attempt_id) REFERENCES attempts(plan_id, unit_id, id),
    FOREIGN KEY (plan_id, unit_id, change_id) REFERENCES changes(plan_id, unit_id, change_id)
);

CREATE TABLE attempt_files (
    attempt_id TEXT NOT NULL,
    change_id TEXT NOT NULL,
    slot TEXT NOT NULL CHECK (slot IN ('source', 'target')),
    task_id TEXT NOT NULL,
    write_order INTEGER NOT NULL CHECK (typeof(write_order) = 'integer' AND write_order > 0),
    root TEXT NOT NULL CHECK (root IN ('code', 'wiki', 'state')),
    path TEXT NOT NULL CHECK (length(path) > 0),
    before_presence TEXT NOT NULL CHECK (before_presence IN ('missing', 'file')),
    before_artifact_id TEXT,
    after_presence TEXT NOT NULL CHECK (after_presence IN ('missing', 'file')),
    after_sha256 TEXT,
    restore_from TEXT,
    observation TEXT NOT NULL CHECK (observation IN ('pending', 'matched', 'different', 'unknown')),
    observation_json TEXT,
    PRIMARY KEY (attempt_id, change_id, slot),
    UNIQUE (task_id, write_order),
    FOREIGN KEY (attempt_id, change_id) REFERENCES attempt_changes(attempt_id, change_id),
    FOREIGN KEY (task_id, attempt_id) REFERENCES attempts(task_id, id),
    FOREIGN KEY (attempt_id, before_artifact_id) REFERENCES artifacts(attempt_id, id),
    FOREIGN KEY (restore_from, change_id, slot) REFERENCES attempt_files(attempt_id, change_id, slot),
    CHECK ((before_presence = 'missing' AND before_artifact_id IS NULL)
        OR (before_presence = 'file' AND before_artifact_id IS NOT NULL)),
    CHECK ((after_presence = 'missing' AND after_sha256 IS NULL)
        OR (after_presence = 'file' AND after_sha256 IS NOT NULL AND length(after_sha256) = 64 AND after_sha256 NOT GLOB '*[^0-9a-f]*')),
    CHECK ((observation = 'pending' AND observation_json IS NULL)
        OR (observation <> 'pending' AND observation_json IS NOT NULL AND length(observation_json) > 0))
);

CREATE TABLE unit_checks (
    attempt_id TEXT NOT NULL REFERENCES attempts(id),
    verification_plan_id TEXT NOT NULL,
    check_id TEXT NOT NULL,
    result_id TEXT REFERENCES results(id),
    PRIMARY KEY (attempt_id, verification_plan_id, check_id),
    FOREIGN KEY (verification_plan_id, check_id) REFERENCES checks(plan_id, check_id)
);

CREATE TABLE unit_outcomes (
    attempt_id TEXT NOT NULL PRIMARY KEY REFERENCES attempts(id),
    outcome TEXT NOT NULL CHECK (outcome IN ('completed', 'restored')),
    report_id TEXT NOT NULL,
    recorded_at TEXT NOT NULL CHECK (length(recorded_at) > 0),
    FOREIGN KEY (attempt_id, report_id) REFERENCES artifacts(attempt_id, id)
);

-- 사용자 선택과 요청 전체의 복원. 마지막 계획만으로 복원 범위를 한정하지 않는다.
CREATE TABLE choices (
    id TEXT NOT NULL PRIMARY KEY CHECK (typeof(id) = 'text' AND length(trim(id)) > 0),
    task_id TEXT NOT NULL,
    plan_id TEXT NOT NULL,
    previous_id TEXT UNIQUE CHECK (previous_id IS NULL OR previous_id <> id),
    action TEXT NOT NULL CHECK (action IN ('retry', 'restore')),
    apply_limit INTEGER NOT NULL CHECK (typeof(apply_limit) = 'integer' AND apply_limit >= 0),
    verification_plan_id TEXT,
    scope_json TEXT NOT NULL CHECK (typeof(scope_json) = 'text' AND length(scope_json) > 0),
    selected_at TEXT NOT NULL CHECK (length(selected_at) > 0),
    UNIQUE (task_id, id),
    FOREIGN KEY (task_id, plan_id) REFERENCES plans(task_id, id),
    FOREIGN KEY (task_id, verification_plan_id) REFERENCES plans(task_id, id),
    FOREIGN KEY (task_id, previous_id) REFERENCES choices(task_id, id),
    CHECK ((action = 'restore' AND verification_plan_id IS NOT NULL)
        OR (action = 'retry' AND verification_plan_id IS NULL))
);
CREATE UNIQUE INDEX choices_first ON choices(task_id) WHERE previous_id IS NULL;

CREATE TABLE restore_targets (
    choice_id TEXT NOT NULL REFERENCES choices(id),
    apply_attempt_id TEXT NOT NULL REFERENCES attempts(id),
    resolution TEXT NOT NULL CHECK (resolution IN ('pending', 'no_effect', 'restored')),
    restore_attempt_id TEXT REFERENCES unit_outcomes(attempt_id),
    report_id TEXT REFERENCES artifacts(id),
    PRIMARY KEY (choice_id, apply_attempt_id),
    CHECK ((resolution = 'pending' AND restore_attempt_id IS NULL AND report_id IS NULL)
        OR (resolution = 'no_effect' AND restore_attempt_id IS NULL AND report_id IS NOT NULL)
        OR (resolution = 'restored' AND restore_attempt_id IS NOT NULL AND report_id IS NOT NULL))
);

CREATE TABLE restore_checks (
    choice_id TEXT NOT NULL REFERENCES choices(id),
    verification_plan_id TEXT NOT NULL,
    check_id TEXT NOT NULL,
    result_id TEXT REFERENCES results(id),
    PRIMARY KEY (choice_id, check_id),
    FOREIGN KEY (verification_plan_id, check_id) REFERENCES checks(plan_id, check_id)
);

CREATE TABLE restore_outcomes (
    choice_id TEXT NOT NULL PRIMARY KEY REFERENCES choices(id),
    report_id TEXT NOT NULL REFERENCES artifacts(id),
    recorded_at TEXT NOT NULL CHECK (length(recorded_at) > 0)
);

-- 준비 기록도 사본에 보존한다. 실제 원본/대상 식별과 두 DB 대조는 공통 저장 코드의 책임이다.
CREATE TABLE handoffs (
    attempt_id TEXT NOT NULL PRIMARY KEY REFERENCES attempts(id),
    state TEXT NOT NULL CHECK (state IN ('prepared', 'received', 'released', 'active')),
    source_json TEXT NOT NULL CHECK (length(source_json) > 0),
    target_json TEXT NOT NULL CHECK (length(target_json) > 0),
    payload_json TEXT NOT NULL CHECK (length(payload_json) > 0),
    payload_sha256 TEXT NOT NULL CHECK (length(payload_sha256) = 64 AND payload_sha256 NOT GLOB '*[^0-9a-f]*'),
    receipt_id TEXT CHECK (receipt_id IS NULL OR length(trim(receipt_id)) > 0),
    source_confirmation_json TEXT,
    activated_at TEXT,
    CHECK (source_confirmation_json IS NULL OR length(source_confirmation_json) > 0),
    CHECK (activated_at IS NULL OR length(activated_at) > 0),
    CHECK ((state = 'prepared' AND receipt_id IS NULL AND source_confirmation_json IS NULL AND activated_at IS NULL)
        OR (state = 'received' AND receipt_id IS NOT NULL AND source_confirmation_json IS NULL AND activated_at IS NULL)
        OR (state = 'released' AND receipt_id IS NOT NULL AND source_confirmation_json IS NOT NULL AND activated_at IS NULL)
        OR (state = 'active' AND receipt_id IS NOT NULL AND source_confirmation_json IS NOT NULL AND activated_at IS NOT NULL))
);

-- 유지 관리의 기록. 실제 파일 검사와 짧은 실행 소유는 호출자의 책임이다.
CREATE TABLE backups (
    id TEXT NOT NULL PRIMARY KEY CHECK (length(trim(id)) > 0),
    attempt_id TEXT NOT NULL UNIQUE REFERENCES attempts(id),
    manifest_path TEXT NOT NULL CHECK (length(manifest_path) > 0),
    manifest_sha256 TEXT NOT NULL CHECK (length(manifest_sha256) = 64 AND manifest_sha256 NOT GLOB '*[^0-9a-f]*'),
    observed_at TEXT NOT NULL CHECK (length(observed_at) > 0)
);

CREATE TABLE resource_holds (
    id TEXT NOT NULL PRIMARY KEY CHECK (length(trim(id)) > 0),
    task_id TEXT NOT NULL REFERENCES tasks(id),
    artifact_id TEXT REFERENCES artifacts(id),
    backup_id TEXT REFERENCES backups(id),
    reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    created_at TEXT NOT NULL CHECK (length(created_at) > 0),
    released_at TEXT,
    release_reason TEXT,
    CHECK ((artifact_id IS NOT NULL) <> (backup_id IS NOT NULL)),
    CHECK ((released_at IS NULL AND release_reason IS NULL)
        OR (released_at IS NOT NULL AND length(released_at) > 0 AND release_reason IS NOT NULL AND length(trim(release_reason)) > 0))
);
CREATE INDEX holds_artifact ON resource_holds(artifact_id) WHERE released_at IS NULL;
CREATE INDEX holds_backup ON resource_holds(backup_id) WHERE released_at IS NULL;

CREATE TABLE transitions (
    attempt_id TEXT NOT NULL PRIMARY KEY REFERENCES attempts(id),
    source_version INTEGER NOT NULL CHECK (typeof(source_version) = 'integer' AND source_version > 0),
    target_version INTEGER NOT NULL CHECK (typeof(target_version) = 'integer' AND target_version > 0 AND target_version <> source_version),
    candidate_path TEXT NOT NULL CHECK (length(candidate_path) > 0),
    backup_id TEXT NOT NULL REFERENCES backups(id),
    report_id TEXT,
    activated_at TEXT,
    activation_json TEXT,
    FOREIGN KEY (attempt_id, report_id) REFERENCES artifacts(attempt_id, id),
    CHECK ((activated_at IS NULL AND activation_json IS NULL)
        OR (activated_at IS NOT NULL AND length(activated_at) > 0 AND report_id IS NOT NULL
            AND activation_json IS NOT NULL AND length(activation_json) > 0))
);

-- 내용 해시의 재계산은 공통 코드에서 수행한다. SQL은 같은 목록에 대한 확인인지 대조한다.
CREATE TABLE cleanup_plans (
    plan_id TEXT NOT NULL PRIMARY KEY REFERENCES plans(id),
    manifest_sha256 TEXT NOT NULL CHECK (length(manifest_sha256) = 64 AND manifest_sha256 NOT GLOB '*[^0-9a-f]*'),
    impact_sha256 TEXT NOT NULL CHECK (length(impact_sha256) = 64 AND impact_sha256 NOT GLOB '*[^0-9a-f]*'),
    item_count INTEGER NOT NULL CHECK (typeof(item_count) = 'integer' AND item_count > 0),
    UNIQUE (plan_id, manifest_sha256, impact_sha256)
);

CREATE TABLE cleanup_items (
    plan_id TEXT NOT NULL REFERENCES cleanup_plans(plan_id),
    item_id TEXT NOT NULL CHECK (length(trim(item_id)) > 0),
    root TEXT NOT NULL CHECK (root IN ('state', 'bootstrap', 'download')),
    path TEXT NOT NULL CHECK (length(path) > 0),
    identity_json TEXT NOT NULL CHECK (length(identity_json) > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64 AND sha256 NOT GLOB '*[^0-9a-f]*'),
    bytes INTEGER NOT NULL CHECK (typeof(bytes) = 'integer' AND bytes >= 0),
    artifact_id TEXT REFERENCES artifacts(id),
    backup_id TEXT REFERENCES backups(id),
    impact_json TEXT NOT NULL CHECK (length(impact_json) > 0),
    PRIMARY KEY (plan_id, item_id),
    UNIQUE (plan_id, root, path),
    CHECK (artifact_id IS NULL OR backup_id IS NULL)
);

CREATE TABLE cleanup_decisions (
    id TEXT NOT NULL PRIMARY KEY CHECK (length(trim(id)) > 0),
    plan_id TEXT NOT NULL,
    previous_id TEXT UNIQUE CHECK (previous_id IS NULL OR previous_id <> id),
    manifest_sha256 TEXT NOT NULL,
    impact_sha256 TEXT NOT NULL,
    decision TEXT NOT NULL CHECK (decision IN ('approved', 'kept', 'cancelled')),
    evidence_json TEXT NOT NULL CHECK (length(evidence_json) > 0),
    recorded_at TEXT NOT NULL CHECK (length(recorded_at) > 0),
    UNIQUE (plan_id, id),
    FOREIGN KEY (plan_id, manifest_sha256, impact_sha256) REFERENCES cleanup_plans(plan_id, manifest_sha256, impact_sha256),
    FOREIGN KEY (plan_id, previous_id) REFERENCES cleanup_decisions(plan_id, id)
);
CREATE UNIQUE INDEX cleanup_decisions_first ON cleanup_decisions(plan_id) WHERE previous_id IS NULL;

-- 제거 시도 전에 새 소비를 막는다. 파일 삭제의 성공 기록은 observations가 소유한다.
CREATE TABLE cleanup_claims (
    plan_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    decision_id TEXT NOT NULL,
    attempt_id TEXT NOT NULL,
    recheck_id TEXT NOT NULL,
    recorded_at TEXT NOT NULL CHECK (length(recorded_at) > 0),
    PRIMARY KEY (plan_id, item_id),
    FOREIGN KEY (plan_id, item_id) REFERENCES cleanup_items(plan_id, item_id),
    FOREIGN KEY (plan_id, decision_id) REFERENCES cleanup_decisions(plan_id, id),
    FOREIGN KEY (plan_id, attempt_id) REFERENCES attempts(plan_id, id),
    FOREIGN KEY (attempt_id, recheck_id) REFERENCES artifacts(attempt_id, id)
);

CREATE TABLE cleanup_observations (
    id TEXT NOT NULL PRIMARY KEY CHECK (length(trim(id)) > 0),
    plan_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    attempt_id TEXT NOT NULL,
    previous_id TEXT UNIQUE CHECK (previous_id IS NULL OR previous_id <> id),
    observation TEXT NOT NULL CHECK (observation IN ('removed', 'absent', 'changed', 'blocked', 'unknown')),
    details_json TEXT NOT NULL CHECK (length(details_json) > 0),
    observed_at TEXT NOT NULL CHECK (length(observed_at) > 0),
    UNIQUE (plan_id, item_id, id),
    FOREIGN KEY (plan_id, item_id) REFERENCES cleanup_items(plan_id, item_id),
    FOREIGN KEY (plan_id, attempt_id) REFERENCES attempts(plan_id, id),
    FOREIGN KEY (plan_id, item_id, previous_id) REFERENCES cleanup_observations(plan_id, item_id, id)
);
CREATE UNIQUE INDEX cleanup_observations_first ON cleanup_observations(plan_id, item_id) WHERE previous_id IS NULL;

-- 같은 경로/내용의 다른 ID도 제외한다. 실제 파일 동일성은 공통 코드에서 확인한다.
CREATE VIEW retired_artifacts AS
SELECT DISTINCT a.id FROM artifacts a JOIN cleanup_items i
    ON a.id = i.artifact_id OR (a.root = i.root AND a.path = i.path AND a.sha256 = i.sha256)
JOIN cleanup_claims c ON c.plan_id = i.plan_id AND c.item_id = i.item_id;
CREATE VIEW retired_backups AS
SELECT DISTINCT i.backup_id AS id FROM cleanup_items i
JOIN cleanup_claims c ON c.plan_id = i.plan_id AND c.item_id = i.item_id WHERE i.backup_id IS NOT NULL;
CREATE VIEW retired_results AS
SELECT DISTINCT ra.result_id AS id FROM result_artifacts ra JOIN retired_artifacts r ON r.id = ra.artifact_id;

-- 물리 삭제의 증명이 아니라 저장된 최종 관측의 집계다.
CREATE VIEW observed_cleanups AS
SELECT p.plan_id FROM cleanup_plans p
WHERE (SELECT count(*) FROM cleanup_items i WHERE i.plan_id = p.plan_id) = p.item_count
  AND NOT EXISTS (SELECT 1 FROM cleanup_items i WHERE i.plan_id = p.plan_id AND NOT EXISTS (
      SELECT 1 FROM cleanup_observations o WHERE o.plan_id = i.plan_id AND o.item_id = i.item_id
      AND o.observation IN ('removed', 'absent')
      AND NOT EXISTS (SELECT 1 FROM cleanup_observations n WHERE n.previous_id = o.id)));

-- 관측한 PASS 중 구조 조건을 만족하는 것. 현재 입력/파일의 유효성을 보증하는 캐시가 아니다.
CREATE VIEW completion_results AS
SELECT r.id, r.attempt_id, c.plan_id, c.check_id
FROM results r
JOIN attempt_checks ac ON ac.attempt_id = r.attempt_id AND ac.check_id = r.check_id
JOIN checks c ON c.plan_id = ac.plan_id AND c.check_id = ac.check_id
JOIN attempts a ON a.id = r.attempt_id
WHERE r.conclusion = 'pass' AND r.source <> 'not_run'
  AND a.state = 'ended' AND a.unresolved_reason IS NULL
  AND (c.execution_policy = 'tool_reuse' OR r.source = 'executed')
  AND NOT EXISTS (SELECT 1 FROM results n WHERE n.previous_id = r.id)
  AND EXISTS (SELECT 1 FROM result_artifacts ra WHERE ra.result_id = r.id)
  AND NOT EXISTS (SELECT 1 FROM retired_results x WHERE x.id = r.id);

CREATE INDEX attempts_plan ON attempts(plan_id);
CREATE INDEX attempts_unresolved ON attempts(task_id, state) WHERE state <> 'ended' OR unresolved_reason IS NOT NULL;

-- 현재 계획으로 공개하거나 다른 기록에서 사용한 의무 묶음은 늘리거나 덮지 않는다.
CREATE VIEW published_plans AS
SELECT current_change_plan_id AS id FROM tasks WHERE current_change_plan_id IS NOT NULL
UNION SELECT current_verification_plan_id FROM tasks WHERE current_verification_plan_id IS NOT NULL
UNION SELECT plan_id FROM attempts
UNION SELECT previous_id FROM plans WHERE previous_id IS NOT NULL
UNION SELECT plan_id FROM choices
UNION SELECT verification_plan_id FROM choices WHERE verification_plan_id IS NOT NULL
UNION SELECT verification_plan_id FROM unit_requirements;

-- 종류/소유의 교차 검사. 트리거는 검사/거부만 하며 다른 업무 기록을 자동 생성하지 않는다.
CREATE TRIGGER checks_kind BEFORE INSERT ON checks BEGIN
    SELECT CASE WHEN (SELECT kind FROM plans WHERE id = NEW.plan_id) <> 'verification'
        THEN RAISE(ABORT, '검증 계획이 필요합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 중인 계획의 의무를 바꿀 수 없습니다') END;
END;
CREATE TRIGGER units_kind BEFORE INSERT ON units BEGIN
    SELECT CASE WHEN (SELECT kind FROM plans WHERE id = NEW.plan_id) <> 'change'
        THEN RAISE(ABORT, '변경 계획이 필요합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 중인 계획의 단위를 바꿀 수 없습니다') END;
END;
CREATE TRIGGER unit_dependencies_frozen BEFORE INSERT ON unit_dependencies BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 중인 계획의 의존을 바꿀 수 없습니다') END;
END;
CREATE TRIGGER unit_requirements_owner BEFORE INSERT ON unit_requirements BEGIN
    SELECT CASE WHEN (SELECT task_id FROM plans WHERE id = NEW.plan_id)
        <> (SELECT task_id FROM plans WHERE id = NEW.verification_plan_id)
        THEN RAISE(ABORT, '다른 작업의 검사 의무입니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 중인 계획의 의무를 바꿀 수 없습니다') END;
END;
CREATE TRIGGER attempts_kind BEFORE INSERT ON attempts BEGIN
    SELECT CASE WHEN NEW.sequence <= (SELECT coalesce(max(sequence), 0) FROM attempts WHERE task_id = NEW.task_id)
        THEN RAISE(ABORT, '시도 순서는 요청의 마지막 기록 뒤여야 합니다') END;
    SELECT CASE WHEN (SELECT kind FROM plans WHERE id = NEW.plan_id)
        <> CASE WHEN NEW.kind = 'verify' THEN 'verification'
            WHEN NEW.kind IN ('backup', 'migrate', 'cleanup') THEN 'maintenance' ELSE 'change' END
        THEN RAISE(ABORT, '시도와 계획 종류가 다릅니다') END;
    SELECT CASE WHEN NEW.kind = 'restore' AND (SELECT kind FROM attempts WHERE id = NEW.restore_of) <> 'apply'
        THEN RAISE(ABORT, '복원할 적용 시도가 필요합니다') END;
    SELECT CASE WHEN NEW.previous_id IS NOT NULL AND (SELECT kind FROM attempts WHERE id = NEW.previous_id) <> NEW.kind
        THEN RAISE(ABORT, '다른 종류의 시도를 재시도로 연결할 수 없습니다') END;
    SELECT CASE WHEN NEW.kind = 'apply' AND EXISTS (
        SELECT 1 FROM tasks t JOIN choices c ON c.id = t.current_choice_id
        WHERE t.id = NEW.task_id AND c.action = 'restore')
        THEN RAISE(ABORT, '전체 복원 선택 뒤에는 새 적용을 할 수 없습니다') END;
END;
CREATE TRIGGER attempt_checks_kind BEFORE INSERT ON attempt_checks BEGIN
    SELECT CASE WHEN (SELECT kind FROM attempts WHERE id = NEW.attempt_id) <> 'verify'
        THEN RAISE(ABORT, '검증 시도만 검사를 실행할 수 있습니다') END;
    SELECT CASE WHEN (SELECT state FROM attempts WHERE id = NEW.attempt_id) <> 'prepared'
        THEN RAISE(ABORT, '실행 준비 뒤 검사 목록을 바꿀 수 없습니다') END;
END;
CREATE TRIGGER artifacts_kind BEFORE INSERT ON artifacts BEGIN
    SELECT CASE WHEN NEW.role IN ('log', 'report') AND (SELECT kind FROM attempts WHERE id = NEW.attempt_id) <> 'verify'
        THEN RAISE(ABORT, '검사 자료에는 검증 시도가 필요합니다') END;
    SELECT CASE WHEN NEW.role = 'before_image' AND (SELECT kind FROM attempts WHERE id = NEW.attempt_id) NOT IN ('apply', 'restore')
        THEN RAISE(ABORT, '원문 사본에는 적용 또는 복원 시도가 필요합니다') END;
END;
CREATE TRIGGER changes_candidate BEFORE INSERT ON changes BEGIN
    SELECT CASE WHEN NEW.candidate_id IS NOT NULL AND (SELECT role FROM artifacts WHERE id = NEW.candidate_id) <> 'candidate'
        THEN RAISE(ABORT, '계획 후보 자료가 필요합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 중인 계획의 변경을 추가할 수 없습니다') END;
END;
CREATE TRIGGER result_artifacts_kind BEFORE INSERT ON result_artifacts BEGIN
    SELECT CASE WHEN (SELECT role FROM artifacts WHERE id = NEW.artifact_id) NOT IN ('log', 'report')
        THEN RAISE(ABORT, '검사 결과에는 로그 또는 보고서가 필요합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM unit_checks c JOIN unit_outcomes o ON o.attempt_id = c.attempt_id WHERE c.result_id = NEW.result_id)
        OR EXISTS (SELECT 1 FROM restore_checks c JOIN restore_outcomes o ON o.choice_id = c.choice_id WHERE c.result_id = NEW.result_id)
        THEN RAISE(ABORT, '완료에 사용한 결과의 근거 목록을 바꿀 수 없습니다') END;
END;
CREATE TRIGGER results_supplement BEFORE INSERT ON results BEGIN
    SELECT CASE WHEN NEW.previous_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM results p WHERE p.id = NEW.previous_id
        AND p.conclusion <> 'undetermined' AND (p.conclusion <> NEW.conclusion OR p.source <> NEW.source))
        THEN RAISE(ABORT, '확정 관측의 충돌은 별도로 보존하고 판단해야 합니다') END;
END;
CREATE TRIGGER attempt_changes_kind BEFORE INSERT ON attempt_changes BEGIN
    SELECT CASE WHEN (SELECT kind FROM attempts WHERE id = NEW.attempt_id) NOT IN ('apply', 'restore')
        THEN RAISE(ABORT, '파일 반영 시도가 필요합니다') END;
    SELECT CASE WHEN (SELECT state FROM attempts WHERE id = NEW.attempt_id) <> 'prepared'
        THEN RAISE(ABORT, '실행 준비 뒤 변경 목록을 바꿀 수 없습니다') END;
END;
CREATE TRIGGER attempt_files_owner BEFORE INSERT ON attempt_files BEGIN
    SELECT CASE WHEN (SELECT state FROM attempts WHERE id = NEW.attempt_id) <> 'prepared'
        THEN RAISE(ABORT, '실행 준비 뒤 파일 목록을 바꿀 수 없습니다') END;
    SELECT CASE WHEN NEW.write_order <= (SELECT coalesce(max(write_order), 0) FROM attempt_files WHERE task_id = NEW.task_id)
        THEN RAISE(ABORT, '파일 준비 순서는 마지막 기록 뒤여야 합니다') END;
    SELECT CASE WHEN NEW.slot = 'source' AND EXISTS (
        SELECT 1 FROM attempts a JOIN changes c ON c.plan_id = a.plan_id
        WHERE a.id = NEW.attempt_id AND c.change_id = NEW.change_id AND c.action <> 'rename')
        THEN RAISE(ABORT, '이름 변경만 원래 위치와 새 위치를 나눕니다') END;
    SELECT CASE WHEN NEW.before_artifact_id IS NOT NULL AND (SELECT role FROM artifacts WHERE id = NEW.before_artifact_id) <> 'before_image'
        THEN RAISE(ABORT, '적용 직전 사본이 필요합니다') END;
    SELECT CASE WHEN NEW.restore_from IS NOT (SELECT restore_of FROM attempts WHERE id = NEW.attempt_id)
        THEN RAISE(ABORT, '복원할 원래 파일과 연결해야 합니다') END;
    SELECT CASE WHEN NEW.restore_from IS NOT NULL AND EXISTS (
        SELECT 1 FROM attempt_files f LEFT JOIN artifacts b ON b.id = f.before_artifact_id
        WHERE f.attempt_id = NEW.restore_from AND f.change_id = NEW.change_id AND f.slot = NEW.slot
        AND (f.root <> NEW.root OR f.path <> NEW.path OR f.before_presence <> NEW.after_presence
            OR b.sha256 IS NOT NEW.after_sha256))
        THEN RAISE(ABORT, '원래 적용 직전 상태와 복원 목표가 다릅니다') END;
END;

-- 현재 참조와 관측의 변경. 호출자는 별도로 기대 revision을 WHERE에 지정한다.
CREATE TRIGGER tasks_update BEFORE UPDATE ON tasks BEGIN
    SELECT CASE WHEN NEW.id <> OLD.id OR NEW.target_json <> OLD.target_json OR NEW.request_json <> OLD.request_json
        OR NEW.created_at <> OLD.created_at OR NEW.revision <> OLD.revision + 1
        THEN RAISE(ABORT, '작업 원본 또는 revision 변경이 잘못됐습니다') END;
    SELECT CASE WHEN NEW.current_change_plan_id IS NOT NULL AND (SELECT kind FROM plans WHERE id = NEW.current_change_plan_id) <> 'change'
        THEN RAISE(ABORT, '현재 변경 계획 종류가 다릅니다') END;
    SELECT CASE WHEN NEW.current_verification_plan_id IS NOT NULL AND (SELECT kind FROM plans WHERE id = NEW.current_verification_plan_id) <> 'verification'
        THEN RAISE(ABORT, '현재 검증 계획 종류가 다릅니다') END;
END;
CREATE TRIGGER tasks_insert BEFORE INSERT ON tasks BEGIN
    SELECT CASE WHEN NEW.current_change_plan_id IS NOT NULL OR NEW.current_verification_plan_id IS NOT NULL OR NEW.current_choice_id IS NOT NULL OR NEW.revision <> 0
        THEN RAISE(ABORT, '작업 생성 뒤 같은 트랜잭션에서 현재 참조를 연결해야 합니다') END;
END;
CREATE TRIGGER attempts_update BEFORE UPDATE ON attempts BEGIN
    SELECT CASE WHEN NEW.id <> OLD.id OR NEW.task_id <> OLD.task_id OR NEW.plan_id <> OLD.plan_id OR NEW.kind <> OLD.kind
        OR NEW.unit_id IS NOT OLD.unit_id OR NEW.previous_id IS NOT OLD.previous_id OR NEW.restore_of IS NOT OLD.restore_of
        OR NEW.sequence <> OLD.sequence OR NEW.input_json <> OLD.input_json OR NEW.command_json IS NOT OLD.command_json
        OR NEW.active_hash IS NOT OLD.active_hash OR NEW.created_at <> OLD.created_at OR NEW.revision <> OLD.revision + 1
        THEN RAISE(ABORT, '시도 준비 원본 또는 revision 변경이 잘못됐습니다') END;
    SELECT CASE WHEN (OLD.exit_code IS NOT NULL AND NEW.exit_code IS NOT OLD.exit_code)
        OR (OLD.ended_at IS NOT NULL AND NEW.ended_at IS NOT OLD.ended_at)
        OR (OLD.process_json IS NOT NULL AND NEW.process_json IS NOT OLD.process_json)
        OR (OLD.cancel_requested_at IS NOT NULL AND NEW.cancel_requested_at IS NOT OLD.cancel_requested_at)
        THEN RAISE(ABORT, '이미 관측한 실행 사실을 덮을 수 없습니다') END;
END;
CREATE TRIGGER attempt_files_update BEFORE UPDATE ON attempt_files BEGIN
    SELECT CASE WHEN NEW.attempt_id <> OLD.attempt_id OR NEW.change_id <> OLD.change_id OR NEW.slot <> OLD.slot
        OR NEW.task_id <> OLD.task_id OR NEW.write_order <> OLD.write_order OR NEW.root <> OLD.root OR NEW.path <> OLD.path
        OR NEW.before_presence <> OLD.before_presence OR NEW.before_artifact_id IS NOT OLD.before_artifact_id
        OR NEW.after_presence <> OLD.after_presence OR NEW.after_sha256 IS NOT OLD.after_sha256 OR NEW.restore_from IS NOT OLD.restore_from
        THEN RAISE(ABORT, '파일 준비 원본을 바꿀 수 없습니다') END;
    SELECT CASE WHEN OLD.observation IN ('matched', 'different') AND (NEW.observation <> OLD.observation OR NEW.observation_json IS NOT OLD.observation_json)
        THEN RAISE(ABORT, '확정 파일 관측을 덮을 수 없습니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM unit_outcomes WHERE attempt_id = OLD.attempt_id)
        THEN RAISE(ABORT, '완료에 사용한 파일 관측을 바꿀 수 없습니다') END;
END;

CREATE TRIGGER unit_checks_insert BEFORE INSERT ON unit_checks BEGIN
    SELECT CASE WHEN NOT EXISTS (
        SELECT 1 FROM attempts a JOIN unit_requirements r
        ON r.plan_id = a.plan_id AND r.unit_id = a.unit_id AND r.kind = a.kind
        WHERE a.id = NEW.attempt_id AND r.verification_plan_id = NEW.verification_plan_id AND r.check_id = NEW.check_id)
        THEN RAISE(ABORT, '해당 단위의 검사 의무가 아닙니다') END;
    SELECT CASE WHEN NEW.result_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM results r JOIN attempt_checks c ON c.attempt_id = r.attempt_id AND c.check_id = r.check_id
        WHERE r.id = NEW.result_id AND c.plan_id = NEW.verification_plan_id AND c.check_id = NEW.check_id)
        THEN RAISE(ABORT, '다른 의무의 결과입니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM unit_outcomes WHERE attempt_id = NEW.attempt_id)
        THEN RAISE(ABORT, '완료 근거를 추가할 수 없습니다') END;
END;
CREATE TRIGGER unit_checks_update BEFORE UPDATE ON unit_checks BEGIN
    SELECT CASE WHEN NEW.attempt_id <> OLD.attempt_id OR NEW.verification_plan_id <> OLD.verification_plan_id OR NEW.check_id <> OLD.check_id
        OR EXISTS (SELECT 1 FROM unit_outcomes WHERE attempt_id = OLD.attempt_id)
        THEN RAISE(ABORT, '검사 의무 또는 완료 근거를 바꿀 수 없습니다') END;
    SELECT CASE WHEN NEW.result_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM results r JOIN attempt_checks c ON c.attempt_id = r.attempt_id AND c.check_id = r.check_id
        WHERE r.id = NEW.result_id AND c.plan_id = NEW.verification_plan_id AND c.check_id = NEW.check_id)
        THEN RAISE(ABORT, '다른 의무의 결과입니다') END;
END;

CREATE TRIGGER unit_outcomes_complete BEFORE INSERT ON unit_outcomes BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM attempts a WHERE a.id = NEW.attempt_id
        AND a.state = 'ended' AND a.unresolved_reason IS NULL
        AND ((a.kind = 'apply' AND NEW.outcome = 'completed') OR (a.kind = 'restore' AND NEW.outcome = 'restored')))
        THEN RAISE(ABORT, '해당 종류의 종료와 확인이 필요합니다') END;
    SELECT CASE WHEN (SELECT role FROM artifacts WHERE id = NEW.report_id) <> 'assessment'
        THEN RAISE(ABORT, '파일과 추가 완료 조건의 확인 자료가 필요합니다') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM attempts a JOIN changes c ON c.plan_id = a.plan_id AND c.unit_id = a.unit_id
        WHERE a.id = NEW.attempt_id AND (
            NOT EXISTS (SELECT 1 FROM attempt_changes x WHERE x.attempt_id = a.id AND x.change_id = c.change_id)
            OR (SELECT count(*) FROM attempt_files f WHERE f.attempt_id = a.id AND f.change_id = c.change_id AND f.observation = 'matched')
                <> CASE c.action WHEN 'rename' THEN 2 ELSE 1 END))
        OR EXISTS (SELECT 1 FROM attempt_files WHERE attempt_id = NEW.attempt_id AND observation <> 'matched')
        THEN RAISE(ABORT, '필수 파일의 반영 관측이 빠졌습니다') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM attempts a JOIN units u ON u.plan_id = a.plan_id AND u.unit_id = a.unit_id
        WHERE a.id = NEW.attempt_id AND (CASE a.kind WHEN 'apply' THEN u.apply_verification ELSE u.restore_verification END = 'undetermined'
        OR (CASE a.kind WHEN 'apply' THEN u.apply_verification ELSE u.restore_verification END = 'required'
            AND NOT EXISTS (SELECT 1 FROM unit_requirements r JOIN checks c ON c.plan_id = r.verification_plan_id AND c.check_id = r.check_id
                WHERE r.plan_id = a.plan_id AND r.unit_id = a.unit_id AND r.kind = a.kind AND c.requirement = 'required'))))
        THEN RAISE(ABORT, '검사 필요성이나 필수 의무가 미확정입니다') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM attempts a JOIN unit_requirements r ON r.plan_id = a.plan_id AND r.unit_id = a.unit_id AND r.kind = a.kind
        JOIN checks c ON c.plan_id = r.verification_plan_id AND c.check_id = r.check_id
        LEFT JOIN unit_checks s ON s.attempt_id = a.id AND s.verification_plan_id = c.plan_id AND s.check_id = c.check_id
        LEFT JOIN completion_results v ON v.id = s.result_id
        WHERE a.id = NEW.attempt_id AND (c.requirement = 'undetermined' OR (c.requirement = 'required' AND v.id IS NULL)))
        THEN RAISE(ABORT, '필수 검사의 유효한 결과가 빠졌습니다') END;
END;

CREATE TRIGGER choices_scope BEFORE INSERT ON choices BEGIN
    SELECT CASE WHEN (SELECT kind FROM plans WHERE id = NEW.plan_id) <> 'change'
        OR (NEW.verification_plan_id IS NOT NULL AND (SELECT kind FROM plans WHERE id = NEW.verification_plan_id) <> 'verification')
        THEN RAISE(ABORT, '선택에 연결한 계획 종류가 다릅니다') END;
    SELECT CASE WHEN NEW.apply_limit <> (SELECT coalesce(max(sequence), 0) FROM attempts WHERE task_id = NEW.task_id AND kind = 'apply')
        THEN RAISE(ABORT, '선택 시점까지의 적용 범위를 대조해야 합니다') END;
    SELECT CASE WHEN NEW.previous_id IS NOT (SELECT current_choice_id FROM tasks WHERE id = NEW.task_id)
        THEN RAISE(ABORT, '현재 선택에서 이어져야 합니다') END;
END;
CREATE TRIGGER restore_targets_insert BEFORE INSERT ON restore_targets BEGIN
    SELECT CASE WHEN NOT EXISTS (
        SELECT 1 FROM choices c JOIN attempts a ON a.task_id = c.task_id
        WHERE c.id = NEW.choice_id AND c.action = 'restore' AND a.id = NEW.apply_attempt_id AND a.kind = 'apply' AND a.sequence <= c.apply_limit)
        THEN RAISE(ABORT, '선택 범위의 적용 시도가 아닙니다') END;
    SELECT CASE WHEN NEW.resolution <> 'pending'
        THEN RAISE(ABORT, '복원 대상은 미확인 상태로 먼저 등록해야 합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM restore_outcomes WHERE choice_id = NEW.choice_id)
        THEN RAISE(ABORT, '전체 복원 완료의 범위를 바꿀 수 없습니다') END;
END;
CREATE TRIGGER restore_targets_update BEFORE UPDATE ON restore_targets BEGIN
    SELECT CASE WHEN NEW.choice_id <> OLD.choice_id OR NEW.apply_attempt_id <> OLD.apply_attempt_id
        OR EXISTS (SELECT 1 FROM restore_outcomes WHERE choice_id = OLD.choice_id)
        THEN RAISE(ABORT, '복원 대상 또는 완료 근거를 바꿀 수 없습니다') END;
    SELECT CASE WHEN NEW.resolution = 'restored' AND NOT EXISTS (
        SELECT 1 FROM attempts a JOIN unit_outcomes o ON o.attempt_id = a.id
        WHERE a.id = NEW.restore_attempt_id AND a.restore_of = NEW.apply_attempt_id AND o.outcome = 'restored')
        THEN RAISE(ABORT, '해당 적용의 복원 완료가 필요합니다') END;
    SELECT CASE WHEN NEW.resolution <> 'pending' AND NOT EXISTS (
        SELECT 1 FROM artifacts f JOIN plans p ON p.id = f.plan_id JOIN choices c ON c.task_id = p.task_id
        WHERE f.id = NEW.report_id AND f.role = 'assessment' AND c.id = NEW.choice_id)
        THEN RAISE(ABORT, '현재 복원 또는 무반영 확인 자료가 필요합니다') END;
END;
CREATE TRIGGER restore_checks_insert BEFORE INSERT ON restore_checks BEGIN
    SELECT CASE WHEN NEW.verification_plan_id IS NOT (SELECT verification_plan_id FROM choices WHERE id = NEW.choice_id)
        THEN RAISE(ABORT, '전체 복원의 검사 계획이 다릅니다') END;
    SELECT CASE WHEN NEW.result_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM results r JOIN attempt_checks c ON c.attempt_id = r.attempt_id AND c.check_id = r.check_id
        WHERE r.id = NEW.result_id AND c.plan_id = NEW.verification_plan_id AND c.check_id = NEW.check_id)
        THEN RAISE(ABORT, '다른 의무의 결과입니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM restore_outcomes WHERE choice_id = NEW.choice_id)
        THEN RAISE(ABORT, '전체 복원 완료 근거를 추가할 수 없습니다') END;
END;
CREATE TRIGGER restore_checks_update BEFORE UPDATE ON restore_checks BEGIN
    SELECT CASE WHEN NEW.choice_id <> OLD.choice_id OR NEW.verification_plan_id <> OLD.verification_plan_id OR NEW.check_id <> OLD.check_id
        OR EXISTS (SELECT 1 FROM restore_outcomes WHERE choice_id = OLD.choice_id)
        THEN RAISE(ABORT, '전체 복원의 의무 또는 완료 근거를 바꿀 수 없습니다') END;
    SELECT CASE WHEN NEW.result_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM results r JOIN attempt_checks c ON c.attempt_id = r.attempt_id AND c.check_id = r.check_id
        WHERE r.id = NEW.result_id AND c.plan_id = NEW.verification_plan_id AND c.check_id = NEW.check_id)
        THEN RAISE(ABORT, '다른 의무의 결과입니다') END;
END;
CREATE TRIGGER restore_outcomes_complete BEFORE INSERT ON restore_outcomes BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM choices c JOIN tasks t ON t.id = c.task_id
        WHERE c.id = NEW.choice_id AND c.action = 'restore' AND t.current_choice_id = c.id)
        THEN RAISE(ABORT, '현재 선택한 전체 복원만 완료할 수 있습니다') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM choices c JOIN attempts a ON a.task_id = c.task_id AND a.kind = 'apply'
        LEFT JOIN restore_targets t ON t.choice_id = c.id AND t.apply_attempt_id = a.id
        WHERE c.id = NEW.choice_id AND (a.sequence > c.apply_limit OR t.apply_attempt_id IS NULL OR t.resolution = 'pending'
            OR a.state <> 'ended' OR a.unresolved_reason IS NOT NULL))
        THEN RAISE(ABORT, '이번 요청의 적용 시도에 미확인이 남았습니다') END;
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM choices c JOIN checks q ON q.plan_id = c.verification_plan_id
        WHERE c.id = NEW.choice_id AND q.requirement = 'required')
        OR EXISTS (
            SELECT 1 FROM choices c JOIN checks q ON q.plan_id = c.verification_plan_id
            LEFT JOIN restore_checks s ON s.choice_id = c.id AND s.check_id = q.check_id
            LEFT JOIN completion_results v ON v.id = s.result_id
            WHERE c.id = NEW.choice_id AND (q.requirement = 'undetermined' OR (q.requirement = 'required' AND v.id IS NULL)))
        THEN RAISE(ABORT, '이전 구성의 필수 사용 검증이 빠졌습니다') END;
    SELECT CASE WHEN NOT EXISTS (
        SELECT 1 FROM choices c JOIN artifacts f ON f.plan_id = c.verification_plan_id
        WHERE c.id = NEW.choice_id AND f.id = NEW.report_id AND f.role = 'assessment')
        THEN RAISE(ABORT, '전체 복원과 사용 가능 여부의 확인 자료가 필요합니다') END;
END;

CREATE TRIGGER handoffs_kind BEFORE INSERT ON handoffs BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM attempts WHERE id = NEW.attempt_id AND kind = 'handoff' AND state = 'prepared')
        OR NEW.state <> 'prepared'
        THEN RAISE(ABORT, '준비된 인계 시도에서 시작해야 합니다') END;
END;
CREATE TRIGGER handoffs_update BEFORE UPDATE ON handoffs BEGIN
    SELECT CASE WHEN NEW.attempt_id <> OLD.attempt_id OR NEW.source_json <> OLD.source_json
        OR NEW.target_json <> OLD.target_json OR NEW.payload_json <> OLD.payload_json OR NEW.payload_sha256 <> OLD.payload_sha256
        OR (OLD.receipt_id IS NOT NULL AND NEW.receipt_id IS NOT OLD.receipt_id)
        OR (OLD.source_confirmation_json IS NOT NULL AND NEW.source_confirmation_json IS NOT OLD.source_confirmation_json)
        OR (OLD.activated_at IS NOT NULL AND NEW.activated_at IS NOT OLD.activated_at)
        THEN RAISE(ABORT, '인계 원본 또는 확정한 수신 사실을 바꿀 수 없습니다') END;
    SELECT CASE WHEN NOT (NEW.state = OLD.state
        OR (OLD.state = 'prepared' AND NEW.state IN ('received', 'released'))
        OR (OLD.state = 'received' AND NEW.state = 'active'))
        THEN RAISE(ABORT, '인계 단계의 순서가 잘못됐습니다') END;
    SELECT CASE WHEN NEW.state = 'active' AND NOT EXISTS (
        SELECT 1 FROM attempts WHERE id = NEW.attempt_id AND state = 'ended')
        THEN RAISE(ABORT, '인계 완료 시도와 함께 활성화해야 합니다') END;
END;

-- 확정 원본은 새 식별/관측으로 보충한다. 정리/형식 변환은 별도 검증 경로다.
CREATE TRIGGER metadata_immutable BEFORE UPDATE ON metadata BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER plans_immutable BEFORE UPDATE ON plans BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER checks_immutable BEFORE UPDATE ON checks BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER units_immutable BEFORE UPDATE ON units BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER unit_dependencies_immutable BEFORE UPDATE ON unit_dependencies BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER unit_requirements_immutable BEFORE UPDATE ON unit_requirements BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER changes_immutable BEFORE UPDATE ON changes BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER attempt_checks_immutable BEFORE UPDATE ON attempt_checks BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER artifacts_immutable BEFORE UPDATE ON artifacts BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER results_immutable BEFORE UPDATE ON results BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER result_artifacts_immutable BEFORE UPDATE ON result_artifacts BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER attempt_changes_immutable BEFORE UPDATE ON attempt_changes BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER unit_outcomes_immutable BEFORE UPDATE ON unit_outcomes BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER choices_immutable BEFORE UPDATE ON choices BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER restore_outcomes_immutable BEFORE UPDATE ON restore_outcomes BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER metadata_preserve BEFORE DELETE ON metadata BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER plans_preserve BEFORE DELETE ON plans BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER checks_preserve BEFORE DELETE ON checks BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER units_preserve BEFORE DELETE ON units BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER unit_dependencies_preserve BEFORE DELETE ON unit_dependencies BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER unit_requirements_preserve BEFORE DELETE ON unit_requirements BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER changes_preserve BEFORE DELETE ON changes BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER attempt_checks_preserve BEFORE DELETE ON attempt_checks BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER artifacts_preserve BEFORE DELETE ON artifacts BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER results_preserve BEFORE DELETE ON results BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER result_artifacts_preserve BEFORE DELETE ON result_artifacts BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER attempt_changes_preserve BEFORE DELETE ON attempt_changes BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER unit_outcomes_preserve BEFORE DELETE ON unit_outcomes BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER choices_preserve BEFORE DELETE ON choices BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER restore_outcomes_preserve BEFORE DELETE ON restore_outcomes BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER tasks_preserve BEFORE DELETE ON tasks BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER attempts_preserve BEFORE DELETE ON attempts BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER attempt_files_preserve BEFORE DELETE ON attempt_files BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER unit_checks_preserve BEFORE DELETE ON unit_checks BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER restore_targets_preserve BEFORE DELETE ON restore_targets BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER restore_checks_preserve BEFORE DELETE ON restore_checks BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;
CREATE TRIGGER handoffs_preserve BEFORE DELETE ON handoffs BEGIN SELECT RAISE(ABORT, '기록 정리는 별도 참조 검사가 필요합니다'); END;

CREATE TRIGGER backups_complete BEFORE INSERT ON backups BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM attempts WHERE id = NEW.attempt_id
        AND kind = 'backup' AND state = 'ended' AND unresolved_reason IS NULL)
        THEN RAISE(ABORT, '백업 시도의 종료와 파일 대조가 필요합니다') END;
END;

CREATE TRIGGER resource_holds_insert BEFORE INSERT ON resource_holds BEGIN
    SELECT CASE WHEN NEW.released_at IS NOT NULL
        THEN RAISE(ABORT, '보호할 의존을 먼저 등록해야 합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.artifact_id)
        OR EXISTS (SELECT 1 FROM retired_backups WHERE id = NEW.backup_id)
        THEN RAISE(ABORT, '정리 확정된 자료를 새 의존으로 사용할 수 없습니다') END;
END;
CREATE TRIGGER resource_holds_update BEFORE UPDATE ON resource_holds BEGIN
    SELECT CASE WHEN NEW.id <> OLD.id OR NEW.task_id <> OLD.task_id
        OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.backup_id IS NOT OLD.backup_id
        OR NEW.reason <> OLD.reason OR NEW.created_at <> OLD.created_at
        OR OLD.released_at IS NOT NULL OR NEW.released_at IS NULL
        THEN RAISE(ABORT, '의존은 해제 이유를 남기고 한 번만 해제할 수 있습니다') END;
END;

CREATE TRIGGER transitions_insert BEFORE INSERT ON transitions BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM attempts a WHERE a.id = NEW.attempt_id
        AND a.kind = 'migrate' AND a.state = 'prepared'
        AND NEW.source_version = (SELECT schema_version FROM metadata WHERE singleton = 1)
        AND EXISTS (SELECT 1 FROM resource_holds h WHERE h.task_id = a.task_id
            AND h.backup_id = NEW.backup_id AND h.released_at IS NULL))
        THEN RAISE(ABORT, '형식 변경 준비와 백업 보호가 필요합니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_backups WHERE id = NEW.backup_id)
        OR NEW.report_id IS NOT NULL OR NEW.activated_at IS NOT NULL
        THEN RAISE(ABORT, '유효한 백업으로 전환 준비를 먼저 기록해야 합니다') END;
END;
CREATE TRIGGER transitions_update BEFORE UPDATE ON transitions BEGIN
    SELECT CASE WHEN NEW.attempt_id <> OLD.attempt_id OR NEW.source_version <> OLD.source_version
        OR NEW.target_version <> OLD.target_version OR NEW.candidate_path <> OLD.candidate_path
        OR NEW.backup_id <> OLD.backup_id OR OLD.activated_at IS NOT NULL
        OR (OLD.report_id IS NOT NULL AND NEW.report_id IS NOT OLD.report_id)
        THEN RAISE(ABORT, '전환 준비와 확정 관측을 바꿀 수 없습니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_backups WHERE id = NEW.backup_id)
        OR EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.report_id)
        OR (NEW.report_id IS NOT NULL AND (SELECT role FROM artifacts WHERE id = NEW.report_id) <> 'assessment')
        THEN RAISE(ABORT, '전환에 유효한 백업과 검사 자료가 필요합니다') END;
    SELECT CASE WHEN NEW.activated_at IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM attempts a WHERE a.id = NEW.attempt_id AND a.state = 'ended' AND a.unresolved_reason IS NULL
        AND EXISTS (SELECT 1 FROM resource_holds h WHERE h.task_id = a.task_id AND h.backup_id = NEW.backup_id AND h.released_at IS NULL))
        THEN RAISE(ABORT, '전환 관측과 백업 보호 확인 뒤 활성화해야 합니다') END;
END;

CREATE TRIGGER cleanup_plans_kind BEFORE INSERT ON cleanup_plans BEGIN
    SELECT CASE WHEN (SELECT kind FROM plans WHERE id = NEW.plan_id) <> 'maintenance'
        OR EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        THEN RAISE(ABORT, '사용 전 유지 관리 계획이 필요합니다') END;
END;
CREATE TRIGGER cleanup_items_insert BEFORE INSERT ON cleanup_items BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM published_plans WHERE id = NEW.plan_id)
        OR EXISTS (SELECT 1 FROM cleanup_decisions WHERE plan_id = NEW.plan_id)
        THEN RAISE(ABORT, '확인하거나 실행한 정리 목록을 바꿀 수 없습니다') END;
    SELECT CASE WHEN (SELECT count(*) FROM cleanup_items WHERE plan_id = NEW.plan_id)
        >= (SELECT item_count FROM cleanup_plans WHERE plan_id = NEW.plan_id)
        THEN RAISE(ABORT, '표시할 항목 수를 초과했습니다') END;
    SELECT CASE WHEN NEW.artifact_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM artifacts a WHERE a.id = NEW.artifact_id AND a.root = 'state'
        AND NEW.root = a.root AND NEW.path = a.path AND NEW.sha256 = a.sha256)
        THEN RAISE(ABORT, '정리 자료의 위치나 내용 기준이 다릅니다') END;
    SELECT CASE WHEN NEW.backup_id IS NOT NULL AND NEW.root <> 'state'
        THEN RAISE(ABORT, '백업은 상태 영역의 사본만 정리할 수 있습니다') END;
END;
CREATE TRIGGER cleanup_decisions_insert BEFORE INSERT ON cleanup_decisions BEGIN
    SELECT CASE WHEN (SELECT count(*) FROM cleanup_items WHERE plan_id = NEW.plan_id)
        <> (SELECT item_count FROM cleanup_plans WHERE plan_id = NEW.plan_id)
        THEN RAISE(ABORT, '정리 목록을 완성한 뒤 확인해야 합니다') END;
    SELECT CASE WHEN NEW.previous_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cleanup_decisions WHERE previous_id = NEW.previous_id)
        THEN RAISE(ABORT, '마지막 확인에서 이어져야 합니다') END;
END;
CREATE TRIGGER cleanup_claims_insert BEFORE INSERT ON cleanup_claims BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM cleanup_decisions d WHERE d.id = NEW.decision_id
        AND d.decision = 'approved' AND NOT EXISTS (SELECT 1 FROM cleanup_decisions n WHERE n.previous_id = d.id))
        THEN RAISE(ABORT, '현재 정리 승인이 필요합니다') END;
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM attempts a JOIN artifacts r ON r.attempt_id = a.id
        WHERE a.id = NEW.attempt_id AND a.kind = 'cleanup' AND a.state IN ('prepared', 'running')
        AND a.unresolved_reason IS NULL AND r.id = NEW.recheck_id AND r.role = 'assessment')
        OR EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.recheck_id)
        THEN RAISE(ABORT, '정리 시도의 현재 재대조 근거가 필요합니다') END;
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM cleanup_items i JOIN resource_holds h ON h.released_at IS NULL
        LEFT JOIN artifacts a ON a.id = h.artifact_id
        WHERE i.plan_id = NEW.plan_id AND i.item_id = NEW.item_id
        AND (h.artifact_id = i.artifact_id OR h.backup_id = i.backup_id
            OR (a.root = i.root AND a.path = i.path AND a.sha256 = i.sha256)))
        THEN RAISE(ABORT, '현재 필요한 자료는 정리할 수 없습니다') END;
    SELECT CASE WHEN EXISTS (SELECT 1 FROM cleanup_items i JOIN artifacts a ON a.id = NEW.recheck_id
        WHERE i.plan_id = NEW.plan_id AND i.item_id = NEW.item_id
        AND (i.artifact_id = a.id OR (i.root = a.root AND i.path = a.path AND i.sha256 = a.sha256)))
        THEN RAISE(ABORT, '이번 재대조 근거 자체를 정리할 수 없습니다') END;
END;
CREATE TRIGGER cleanup_observations_insert BEFORE INSERT ON cleanup_observations BEGIN
    SELECT CASE WHEN (SELECT kind FROM attempts WHERE id = NEW.attempt_id) <> 'cleanup'
        THEN RAISE(ABORT, '정리 시도의 관측이 필요합니다') END;
    SELECT CASE WHEN NEW.observation IN ('removed', 'absent') AND NOT EXISTS (
        SELECT 1 FROM cleanup_claims WHERE plan_id = NEW.plan_id AND item_id = NEW.item_id)
        THEN RAISE(ABORT, '정리 확정 없이 제거 완료를 기록할 수 없습니다') END;
    SELECT CASE WHEN NEW.previous_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cleanup_observations WHERE id = NEW.previous_id AND observation IN ('removed', 'absent'))
        THEN RAISE(ABORT, '완료한 정리 관측은 새 작업으로 구분해야 합니다') END;
END;

-- 새 소비에서만 거부한다. 과거 성공/실패와 완료 행은 그대로 보존한다.
CREATE TRIGGER artifacts_retired BEFORE INSERT ON artifacts BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM cleanup_items i JOIN cleanup_claims c
        ON c.plan_id = i.plan_id AND c.item_id = i.item_id
        WHERE i.root = NEW.root AND i.path = NEW.path AND i.sha256 = NEW.sha256)
        THEN RAISE(ABORT, '정리한 자료를 다른 ID로 다시 등록할 수 없습니다') END;
END;
CREATE TRIGGER changes_retired BEFORE INSERT ON changes BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.candidate_id)
        THEN RAISE(ABORT, '정리한 후보를 사용할 수 없습니다') END;
END;
CREATE TRIGGER result_artifacts_retired BEFORE INSERT ON result_artifacts BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.artifact_id)
        THEN RAISE(ABORT, '정리한 검사 자료를 사용할 수 없습니다') END;
END;
CREATE TRIGGER attempt_changes_retired BEFORE INSERT ON attempt_changes BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM changes c JOIN retired_artifacts r ON r.id = c.candidate_id
        WHERE c.plan_id = NEW.plan_id AND c.change_id = NEW.change_id)
        THEN RAISE(ABORT, '정리한 후보로 새 반영을 준비할 수 없습니다') END;
END;
CREATE TRIGGER attempt_files_retired BEFORE INSERT ON attempt_files BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.before_artifact_id)
        OR EXISTS (SELECT 1 FROM attempt_files f JOIN retired_artifacts r ON r.id = f.before_artifact_id
            WHERE f.attempt_id = NEW.restore_from AND f.change_id = NEW.change_id AND f.slot = NEW.slot)
        THEN RAISE(ABORT, '정리한 사본으로 새 반영이나 복원을 준비할 수 없습니다') END;
END;
CREATE TRIGGER unit_outcomes_retired BEFORE INSERT ON unit_outcomes BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.report_id)
        OR EXISTS (SELECT 1 FROM attempt_files f JOIN retired_artifacts r ON r.id = f.before_artifact_id
            WHERE f.attempt_id = NEW.attempt_id)
        OR EXISTS (SELECT 1 FROM attempt_files f JOIN attempt_files original
            ON original.attempt_id = f.restore_from AND original.change_id = f.change_id AND original.slot = f.slot
            JOIN retired_artifacts r ON r.id = original.before_artifact_id WHERE f.attempt_id = NEW.attempt_id)
        THEN RAISE(ABORT, '정리한 확인 자료로 완료할 수 없습니다') END;
END;
CREATE TRIGGER restore_outcomes_retired BEFORE INSERT ON restore_outcomes BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.report_id)
        OR EXISTS (SELECT 1 FROM restore_targets t JOIN retired_artifacts r ON r.id = t.report_id WHERE t.choice_id = NEW.choice_id)
        OR EXISTS (SELECT 1 FROM restore_targets t JOIN unit_outcomes o ON o.attempt_id = t.restore_attempt_id
            JOIN retired_artifacts r ON r.id = o.report_id WHERE t.choice_id = NEW.choice_id)
        THEN RAISE(ABORT, '정리한 확인 자료로 전체 복원을 완료할 수 없습니다') END;
END;

CREATE TRIGGER unit_checks_retired_insert BEFORE INSERT ON unit_checks BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_results WHERE id = NEW.result_id)
        THEN RAISE(ABORT, '정리한 근거의 결과를 새 의무에 연결할 수 없습니다') END;
END;

CREATE TRIGGER unit_checks_retired_update BEFORE UPDATE ON unit_checks BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_results WHERE id = NEW.result_id)
        THEN RAISE(ABORT, '정리한 근거의 결과를 새 의무에 연결할 수 없습니다') END;
END;

CREATE TRIGGER restore_checks_retired_insert BEFORE INSERT ON restore_checks BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_results WHERE id = NEW.result_id)
        THEN RAISE(ABORT, '정리한 근거의 결과를 새 의무에 연결할 수 없습니다') END;
END;

CREATE TRIGGER restore_checks_retired_update BEFORE UPDATE ON restore_checks BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_results WHERE id = NEW.result_id)
        THEN RAISE(ABORT, '정리한 근거의 결과를 새 의무에 연결할 수 없습니다') END;
END;

CREATE TRIGGER restore_targets_retired BEFORE UPDATE ON restore_targets BEGIN
    SELECT CASE WHEN EXISTS (SELECT 1 FROM retired_artifacts WHERE id = NEW.report_id)
        THEN RAISE(ABORT, '정리한 확인 자료를 복원 관측에 연결할 수 없습니다') END;
END;
CREATE TRIGGER backups_immutable BEFORE UPDATE ON backups BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER backups_preserve BEFORE DELETE ON backups BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER transitions_preserve BEFORE DELETE ON transitions BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER resource_holds_preserve BEFORE DELETE ON resource_holds BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER cleanup_plans_immutable BEFORE UPDATE ON cleanup_plans BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER cleanup_plans_preserve BEFORE DELETE ON cleanup_plans BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER cleanup_items_immutable BEFORE UPDATE ON cleanup_items BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER cleanup_items_preserve BEFORE DELETE ON cleanup_items BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER cleanup_decisions_immutable BEFORE UPDATE ON cleanup_decisions BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER cleanup_decisions_preserve BEFORE DELETE ON cleanup_decisions BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER cleanup_claims_immutable BEFORE UPDATE ON cleanup_claims BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER cleanup_claims_preserve BEFORE DELETE ON cleanup_claims BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
CREATE TRIGGER cleanup_observations_immutable BEFORE UPDATE ON cleanup_observations BEGIN SELECT RAISE(ABORT, '확정 원본은 변경할 수 없습니다'); END;
CREATE TRIGGER cleanup_observations_preserve BEFORE DELETE ON cleanup_observations BEGIN SELECT RAISE(ABORT, '정리 사실과 이력은 삭제할 수 없습니다'); END;
