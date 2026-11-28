import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, unlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { checkRepository } from '../tools/check-links.js';

const script = fileURLToPath(new URL('../tools/check-links.js', import.meta.url));

function fixture(t, files) {
  const root = mkdtempSync(path.join(tmpdir(), 'oneploom-wiki-links-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  execFileSync('git', ['init', '--quiet', root], { stdio: 'pipe' });
  for (const [name, content] of Object.entries(files)) {
    mkdirSync(path.dirname(path.join(root, name)), { recursive: true });
    writeFileSync(path.join(root, name), content);
  }
  return root;
}

function run(root, ...args) {
  return spawnSync(process.execPath, [script, '--root', root, ...args], { encoding: 'utf8' });
}

test('files, directories, Korean titles and GitHub anchors resolve without modifying files', (t) => {
  const files = {
    'README.md': '# 시작\n[파일](docs/안내.md) [폴더](docs/) [전체](.)\n[제목](docs/안내.md#사용%20방법) [앵커](docs/안내.md#사용-방법)\n',
    'docs/안내.md': '# 사용 방법\n[상위](../README.md#시작)\n',
  };
  const root = fixture(t, files);
  const result = checkRepository(root);
  assert.deepEqual(result.errors, []);
  assert.deepEqual(result.counts, { documents: 2, local: 6, external: 0, titleOnly: 1 });
  for (const [name, text] of Object.entries(files)) assert.equal(readFileSync(path.join(root, name), 'utf8'), text);
});

test('references, images, tables, parentheses and encoded path characters are parsed', (t) => {
  const root = fixture(t, {
    'README.md': '[ref][guide]\n\n[guide]: <docs/a (b).md#제목>\n\n![그림](image.png)\n\n| 연결 |\n| --- |\n| [행](docs/a%20(b).md) |\n\n[percent](100%25.md) [hash](a%23b.md)\n',
    'docs/a (b).md': '# 제목\n', 'image.png': Buffer.from([1, 2, 3]), '100%.md': '# 비율\n', 'a#b.md': '# 이름\n',
  });
  const result = checkRepository(root);
  assert.deepEqual(result.errors, []);
  assert.equal(result.counts.local, 5);
});

test('GitHub duplicate headings, inline markup, setext and Unicode headings are recognized', (t) => {
  const root = fixture(t, {
    'README.md': '# **API** `start` &amp; 끝!\n# 중복\n# 중복\n# 중복-1\n제목\n===\n# 😄 Emoji\n[1](#api-start--끝) [2](#중복-1) [3](#중복-1-1) [4](#제목) [5](#-emoji)\n',
  });
  assert.deepEqual(checkRepository(root).errors, []);
});

test('fenced/indented code, inline code and HTML comments are not links', (t) => {
  const root = fixture(t, {
    'README.md': '# 시작\n`[inline](missing.md)`\n\n```md\n[fence](missing.md)\n```\n\n    [code](missing.md)\n\n<!-- [comment](missing.md) -->\n',
  });
  const result = checkRepository(root);
  assert.deepEqual(result.errors, []);
  assert.equal(result.counts.local, 0);
});

test('external links are counted and never requested', (t) => {
  const root = fixture(t, { 'README.md': '[web](https://does-not-exist.invalid/a) [mail](mailto:test@example.com) [host](//example.invalid/x)\n' });
  const result = checkRepository(root);
  assert.deepEqual(result.errors, []);
  assert.equal(result.counts.external, 3);
  assert.equal(result.counts.local, 0);
});

for (const [name, destination, message] of [
  ['missing file', 'missing.md', '대상이 없거나'],
  ['wrong case on Windows', 'guide.md', '대소문자'],
  ['missing heading', 'Guide.md#없는-제목', '제목/앵커'],
  ['missing numbered heading', 'Guide.md#안내-1', '제목/앵커'],
  ['outside repository', '../outside.md', '저장소 밖'],
  ['encoded escape', '%2e%2e/outside.md', '저장소 밖'],
  ['absolute path', '/Guide.md', '상대 경로'],
  ['Windows path', 'C:/private.md', 'scheme'],
  ['local file URL', 'file:///C:/private.md', 'scheme'],
  ['unsupported query', 'Guide.md?raw=1', 'query'],
  ['non-Markdown section', 'LICENSE#조건', '지원하지 않는 파일'],
]) {
  test(`rejects ${name} with a nonzero exit code`, (t) => {
    const root = fixture(t, { 'README.md': `[검사](${destination})\n`, 'Guide.md': '# 안내\n', LICENSE: 'license\n' });
    const result = run(root);
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stderr, new RegExp(message));
    assert.match(result.stderr, /README\.md:1:/);
  });
}

test('ignored documents are excluded, but links to them fail', (t) => {
  const root = fixture(t, {
    '.gitignore': '/private/\n', 'README.md': '[개인](private/note.md)\n', 'private/note.md': '[깨짐](not-found.md)\n',
  });
  const result = checkRepository(root);
  assert.equal(result.counts.documents, 1);
  assert.equal(result.errors.length, 1);
  assert.match(result.errors[0], /Git 공유 대상/);
});

test('tracked missing files and malformed UTF-8 are errors, not skipped successes', (t) => {
  const root = fixture(t, { 'README.md': '# 정상\n', 'removed.md': '# 지워짐\n', 'broken.md': Buffer.from([0xc3, 0x28]) });
  execFileSync('git', ['-C', root, 'add', 'removed.md'], { stdio: 'pipe' });
  unlinkSync(path.join(root, 'removed.md'));
  const result = checkRepository(root);
  assert.equal(result.errors.length, 2);
  assert.ok(result.errors.some((error) => error.startsWith('removed.md:')));
  assert.ok(result.errors.some((error) => error.startsWith('broken.md:')));
});

test('directory junctions cannot supply document contents outside the repository', (t) => {
  const root = fixture(t, { 'README.md': '[외부](linked/other.md)\n' });
  const outside = fixture(t, { 'other.md': '# 외부\n' });
  symlinkSync(outside, path.join(root, 'linked'), 'junction');
  const result = run(root);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /공유 대상|symlink\/junction/);
  assert.equal(readFileSync(path.join(outside, 'other.md'), 'utf8'), '# 외부\n');
});

test('BOM, CRLF and a final line without newline are accepted', (t) => {
  const root = fixture(t, { 'README.md': '\ufeff# 제목\r\n[확인](#제목)' });
  assert.equal(run(root).status, 0);
});

test('unknown arguments and a subdirectory root fail before a partial scan', (t) => {
  const root = fixture(t, { 'README.md': '# 루트\n', 'docs/a.md': '# 하위\n' });
  assert.equal(run(root, '--typo').status, 2);
  const partial = run(path.join(root, 'docs'));
  assert.equal(partial.status, 2);
  assert.match(partial.stderr, /최상위 폴더/);
});

test('Windows case aliases of the repository root do not cause a partial-scan error', (t) => {
  const root = fixture(t, { 'README.md': '# Root\n[local](#root)\n' });
  const aliases = process.platform === 'win32' ? [root.toUpperCase(), root.toLowerCase()] : [root];
  for (const alias of aliases) {
    const result = run(alias);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /문서 1개, 내부 링크 1개/);
  }
});

test('the Git metadata directory is not a document worktree root', (t) => {
  const root = fixture(t, { 'README.md': '# Root\n' });
  const result = run(path.join(root, '.git'));
  assert.equal(result.status, 2);
  assert.match(result.stderr, /최상위 폴더/);
});

test('bare repositories are rejected before scanning Git metadata', (t) => {
  const root = fixture(t, { 'README.md': '# Root\n' });
  const bare = path.join(root, 'bare');
  execFileSync('git', ['init', '--bare', '--quiet', bare], { stdio: 'pipe' });
  const result = run(bare);
  assert.equal(result.status, 2);
  assert.match(result.stderr, /최상위 폴더/);
});

test('an empty repository does not pass', (t) => {
  const root = fixture(t, {});
  const result = run(root);
  assert.equal(result.status, 2);
  assert.match(result.stderr, /Markdown 파일이 없습니다/);
});

test('Git preparation errors are not mistaken for an empty successful scan', (t) => {
  const root = fixture(t, { 'README.md': '# 문서\n' });
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => key.toLowerCase() !== 'path'));
  env.PATH = '';
  const result = spawnSync(process.execPath, [script, '--root', root], { encoding: 'utf8', env });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /검사를 시작하지 못했습니다/);
});

test('help succeeds without a checkout, while a missing root fails', () => {
  assert.equal(spawnSync(process.execPath, [script, '--help']).status, 0);
  assert.equal(run(path.join(tmpdir(), 'oneploom-missing-root-for-link-test')).status, 2);
});
