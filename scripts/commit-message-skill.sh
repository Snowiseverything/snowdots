----
#!/usr/bin/env bash
set -euo pipefail

NAME="commit-message-skill"
DIR="${PWD}/${NAME}"
INSTALL_GLOBAL=true

if [ -d "$DIR" ]; then
  echo "Directory $DIR already exists. Aborting." >&2
  exit 1
fi

mkdir -p "$DIR"
cd "$DIR"

# Prompt for LICENSE
read -r -p "Add an MIT license file to the repo? (y/N) " add_license
if [ "${add_license,,}" = "y" ] || [ "${add_license,,}" = "yes" ]; then
  cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOF
  LICENSE_ADDED=true
else
  echo "Skipping LICENSE creation."
  LICENSE_ADDED=false
fi

cat > package.json <<'EOF'
{
  "name": "commit-message-skill",
  "version": "0.1.0",
  "description": "OpenCode skill / CLI to remove specified entries from a GitHub profile README and create a Conventional Commit/PR.",
  "main": "src/index.js",
  "bin": {
    "commit-message-skill": "src/cli.js"
  },
  "scripts": {
    "test": "mocha",
    "lint": "eslint ."
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/yourname/commit-message-skill.git"
  },
  "keywords": ["opencode","skill","github","readme","cli","commit"],
  "author": "Your Name <you@example.com>",
  "license": "MIT",
  "dependencies": {
    "@octokit/rest": "^20.0.0",
    "commander": "^11.0.0",
    "simple-git": "^3.19.0",
    "diff": "^5.1.0",
    "tmp": "^0.2.1"
  },
  "devDependencies": {
    "mocha": "^10.2.0",
    "chai": "^4.3.8",
    "eslint": "^8.50.0"
  }
}
EOF

cat > README.md <<'EOF'
# commit-message-skill

CLI and OpenCode skill to remove specified entries from a GitHub profile README, commit with Conventional Commits, and optionally open a PR.

Usage:
  commit-message-skill --repo owner/repo --remove "Rust" --dry-run --token $GITHUB_TOKEN
EOF

cat > SKILL.md <<'EOF'
Name: commit-message-skill
Description: Removes unwanted items from profile README skills section; creates branch, commit, and optional PR.
Entry: commit-message-skill (executable)
Auto-discover paths: ~/.config/opencode/skills/, ~/.agents/skills/
EOF

cat > .gitignore <<'EOF'
node_modules/
dist/
.tmp/
.env
EOF

mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm test
EOF

mkdir -p src test

cat > src/cli.js <<'EOF'
#!/usr/bin/env node
const { program } = require('commander');
const main = require('./index');

program
  .requiredOption('--repo <owner/repo>', 'GitHub repo (e.g., user/user)')
  .option('--file <path>', 'README file path', 'README.md')
  .requiredOption('--remove <item...>', 'Items to remove (repeatable)')
  .option('--branch <name>', 'branch name')
  .option('--commit-template <tpl>', 'commit message template', 'chore(profile): remove {{item}} from skills')
  .option('--pr', 'open a pull request')
  .option('--dry-run', 'show diff and proposed commit without pushing')
  .option('--token <token>', 'GitHub token (or use GITHUB_TOKEN env)')
  .parse(process.argv);

main(program.opts()).catch(err => {
  console.error(err.message || err);
  process.exit(1);
});
EOF

cat > src/index.js <<'EOF'
const fs = require('fs');
const path = require('path');
const tmp = require('tmp');
const simpleGit = require('simple-git');
const { Octokit } = require('@octokit/rest');
const parser = require('./parser');
const child = require('child_process');

module.exports = async function run(opts) {
  const token = opts.token || process.env.GITHUB_TOKEN;
  if (!token) throw new Error('GitHub token required via --token or GITHUB_TOKEN env');

  const [owner, repo] = opts.repo.split('/');
  if (!owner || !repo) throw new Error('--repo must be owner/repo');

  const octokit = new Octokit({ auth: token });

  const tmpdir = tmp.dirSync({ unsafeCleanup: true });
  const git = simpleGit(tmpdir.name);

  const cloneUrl = `https://x-access-token:${token}@github.com/${owner}/${repo}.git`;
  await git.clone(cloneUrl, tmpdir.name, ['--depth', '1']);
  await git.cwd(tmpdir.name);

  const filePath = path.join(tmpdir.name, opts.file);
  if (!fs.existsSync(filePath)) throw new Error(`File not found: ${opts.file}`);

  const text = fs.readFileSync(filePath, 'utf8');
  const res = parser.removeItems(text, opts.remove);

  if (res.removed.length === 0) {
    tmpdir.removeCallback();
    console.log('No matching items found.');
    return;
  }

  const newText = res.newText;
  fs.writeFileSync(filePath, newText, 'utf8');

  const branch = opts.branch || `chore/remove-${opts.remove[0].toLowerCase().replace(/\\s+/g,'-')}`;
  await git.checkoutLocalBranch(branch);
  await git.add(opts.file);
  const commitMsg = (opts.commitTemplate || 'chore(profile): remove {{item}} from skills').replace('{{item}}', opts.remove[0]);
  await git.commit(commitMsg);
  if (opts.dryRun) {
    const diff = child.execSync('git --no-pager --no-color diff HEAD~1 HEAD', { cwd: tmpdir.name }).toString();
    console.log(diff);
    tmpdir.removeCallback();
    return;
  }
  await git.push('origin', branch);

  if (opts.pr) {
    const title = commitMsg;
    const body = `- Remove \"${opts.remove[0]}\" from profile README skills list — was added mistakenly after forking a project.\n\nNo code changes; README only.`;
    const pr = await octokit.pulls.create({ owner, repo, title, head: branch, base: 'main', body });
    console.log('PR created:', pr.data.html_url);
  } else {
    console.log('Pushed branch:', branch);
  }

  tmpdir.removeCallback();
};
EOF

cat > src/parser.js <<'EOF'
const diff = require('diff');

function findSkillsSectionLines(text) {
  const lines = text.split(/\\r?\\n/);
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^#{1,3}\\s*(Skills|Tech|Technologies|Languages|Stack)/i);
    if (m) {
      let start = i + 1;
      while (start < lines.length && lines[start].trim() === '') start++;
      let end = start;
      while (end < lines.length && /^(\\s*[-*]\\s+|\\s*\\d+\\.\\s+|[^#])/.test(lines[end])) end++;
      return { start, end, headingLine: i };
    }
  }
  return null;
}

function removeFromListLines(lines, items) {
  const removed = [];
  const lower = items.map(i => i.toLowerCase());
  const out = lines.filter(line => {
    const m = line.match(/^\\s*[-*]\\s+(.*)$/);
    if (!m) return true;
    const item = m[1].trim().replace(/[.,;]+$/,'');
    if (lower.includes(item.toLowerCase())) {
      removed.push(item);
      return false;
    }
    return true;
  });
  return { out, removed };
}

function removeItems(text, items) {
  const lines = text.split(/\\r?\\n/);
  const section = findSkillsSectionLines(text);
  let removed = [];
  if (section) {
    const slice = lines.slice(section.start, section.end);
    const r = removeFromListLines(slice, items);
    removed = r.removed;
    lines.splice(section.start, section.end - section.start, ...r.out);
  } else {
    const lower = items.map(i => i.toLowerCase());
    let final = text;
    lower.forEach(tok => {
      const re = new RegExp('\\\\b' + tok.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + '\\\\b', 'ig');
      final = final.replace(re, '');
    });
    const r = diff.createPatch('README.md', text, final);
    return { newText: final, diff: r, removed };
  }
  const newText = lines.join('\\n');
  const patch = diff.createPatch('README.md', text, newText);
  return { newText, diff: patch, removed };
}

module.exports = { removeItems };
EOF

cat > test/parser.test.js <<'EOF'
const { expect } = require('chai');
const parser = require('../src/parser');

describe('parser.removeItems', () => {
  it('removes an item from a bullet skills list', () => {
    const before = '## Skills\\n\\n- JavaScript\\n- Rust\\n- Python\\n';
    const res = parser.removeItems(before, ['Rust']);
    expect(res.removed).to.include('Rust');
    expect(res.newText).to.not.include('- Rust');
  });
});
EOF

chmod +x src/cli.js

echo "Installing npm dependencies..."
npm install

git init -b main >/dev/null
if [ "$LICENSE_ADDED" = true ]; then
  git add LICENSE
fi
git add .
git commit -m "chore: initial commit for commit-message-skill" >/dev/null

# Global install
echo "Installing package globally with npm..."
npm install -g "$DIR"

echo "Done.

Example usage:
  # dry-run (no push)
  commit-message-skill --repo youruser/youruser --remove \"Rust\" --dry-run --token \$GITHUB_TOKEN

  # commit + push + PR (requires token with repo scope)
  commit-message-skill --repo youruser/youruser --remove \"Rust\" --pr --token \$GITHUB_TOKEN
"
----
