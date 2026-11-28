import { execFileSync } from 'node:child_process';
import { lstatSync, readFileSync, realpathSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';
import GithubSlugger from 'github-slugger';
import MarkdownIt from 'markdown-it';

function headingText(tokens) {
  return tokens.map((token) => {
    if (['text', 'code_inline'].includes(token.type)) return token.content;
    if (['softbreak', 'hardbreak'].includes(token.type)) return ' ';
    if (token.type === 'image') return headingText(token.children ?? []);
    return '';
  }).join('');
}

export function readDocument(filename) {
  const parser = new MarkdownIt('commonmark').enable(['table', 'strikethrough']);
  // Parse unsafe schemes for diagnostics only. This checker never renders HTML.
  parser.validateLink = () => true;
  const text = new TextDecoder('utf-8', { fatal: true }).decode(readFileSync(filename));
  const tokens = parser.parse(text, {});
  const result = { links: [], titles: new Set(), anchors: new Set() };
  const slugger = new GithubSlugger();
  for (const [index, token] of tokens.entries()) {
    if (token.type !== 'inline') continue;
    const children = token.children ?? [];
    if (tokens[index - 1]?.type === 'heading_open') {
      const title = headingText(children);
      result.titles.add(title);
      result.anchors.add(slugger.slug(title));
    }
    for (const child of children) {
      const attribute = { link_open: 'href', image: 'src' }[child.type];
      if (attribute) {
        // Inline tokens identify the containing paragraph/table cell's start line.
        result.links.push({ url: child.attrGet(attribute), line: (token.map?.[0] ?? 0) + 1 });
      }
    }
  }
  return result;
}

function repositoryFiles(root) {
  const options = { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] };
  const top = execFileSync('git', ['rev-parse', '--show-toplevel'], options).trim();
  if (realpathSync(top) !== realpathSync(root)) {
    throw new Error('--root에는 Git 저장소의 최상위 폴더를 지정하세요');
  }
  const output = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], options);
  return new Set(output.split('\0').filter(Boolean));
}

function checkedPath(root, name, directory = false) {
  let current = root;
  for (const part of name.split('/')) {
    current = path.join(current, part);
    if (lstatSync(current).isSymbolicLink()) {
      throw new Error('symlink/junction 경로는 검사하지 않습니다');
    }
  }
  const stat = lstatSync(current);
  if (directory ? !stat.isDirectory() : !stat.isFile()) {
    throw new Error('작업 트리에 해당 파일/폴더가 없습니다');
  }
  return current;
}

function localTarget(source, destination) {
  if (/^(https?:|mailto:|\/\/)/i.test(destination)) return null;
  if (/^[a-z][a-z\d+.-]*:/i.test(destination)) {
    throw new Error('지원하지 않는 링크 scheme입니다');
  }
  const [beforeHash, ...fragmentParts] = destination.split('#');
  if (beforeHash.includes('?')) throw new Error('로컬 링크의 query는 지원하지 않습니다');
  const relative = decodeURIComponent(beforeHash);
  const fragment = decodeURIComponent(fragmentParts.join('#'));
  if (/[\\\0]/.test(relative) || relative.startsWith('/')) {
    throw new Error('저장소 내부의 상대 경로를 사용하세요');
  }
  const target = relative
    ? path.posix.normalize(path.posix.join(path.posix.dirname(source), relative)).replace(/\/$/, '')
    : source;
  if (target === '..' || target.startsWith('../')) throw new Error('저장소 밖을 가리킵니다');
  return { target, fragment };
}

export function checkRepository(root) {
  const files = repositoryFiles(root);
  const markdown = [...files].filter((name) => path.posix.extname(name).toLowerCase() === '.md').sort();
  if (!markdown.length) throw new Error('검사할 Markdown 파일이 없습니다');
  const documents = new Map();
  const errors = [];
  for (const name of markdown) {
    try {
      documents.set(name, readDocument(checkedPath(root, name)));
    } catch (error) {
      errors.push(`${name}: ${error.message}`);
    }
  }
  const counts = { documents: markdown.length, local: 0, external: 0, titleOnly: 0 };
  for (const [source, document] of documents) {
    for (const link of document.links) {
      counts.local++;
      try {
        const location = localTarget(source, link.url);
        if (!location) {
          counts.local--;
          counts.external++;
          continue;
        }
        const { target, fragment } = location;
        if (!files.has(target)) {
          const prefix = target === '.' ? '' : `${target}/`;
          if (!fragment && [...files].some((name) => name.startsWith(prefix))) {
            checkedPath(root, target, true);
            continue;
          }
          throw new Error('대상이 없거나 Git 공유 대상이 아닙니다 (대소문자 확인)');
        }
        checkedPath(root, target);
        if (fragment) {
          const headings = documents.get(target);
          if (!headings) throw new Error('읽지 못한 Markdown 또는 지원하지 않는 파일의 섹션입니다');
          if (headings.anchors.has(fragment)) continue;
          if (headings.titles.has(fragment)) {
            counts.titleOnly++;
            continue;
          }
          throw new Error(`대상 제목/앵커가 없습니다: ${fragment}`);
        }
      } catch (error) {
        errors.push(`${source}:${link.line}: ${link.url} — ${error.message}`);
      }
    }
  }
  return { counts, errors };
}

export function main(args = process.argv.slice(2)) {
  try {
    const { values } = parseArgs({ args, options: { root: { type: 'string' }, help: { type: 'boolean' } } });
    if (values.help) {
      console.log('node tools/check-links.js [--root <Git 저장소 루트>]');
      return 0;
    }
    const root = path.resolve(values.root ?? fileURLToPath(new URL('../', import.meta.url)));
    const { counts, errors } = checkRepository(root);
    for (const error of errors) console.error(error);
    console.log(`문서 ${counts.documents}개, 내부 링크 ${counts.local}개, 외부 링크 ${counts.external}개 제외, 오류 ${errors.length}개`);
    console.log(`제목 원문으로 확인한 링크 ${counts.titleOnly}개. GitHub/Obsidian의 클릭 동작 일치를 보장하지 않습니다.`);
    return errors.length ? 1 : 0;
  } catch (error) {
    console.error(`검사를 시작하지 못했습니다: ${error.message}`);
    return 2;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  process.exitCode = main();
}
