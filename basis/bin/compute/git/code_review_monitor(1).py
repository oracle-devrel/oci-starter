#!/usr/bin/env python3
"""Generate HTML code-review reports for the latest git commit.

Features:
- Works in a target repo (default: $HOME/ai.git).
- Can run once, watch for HEAD changes, or install a post-commit hook.
- Uses the OpenAI Responses API via the official Python SDK.
- Writes reports to: $HOME/code_review/YYYY-MM-DD-<commit_id>.html
"""

from __future__ import annotations

import argparse
import html
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


RULES: List[Dict[str, Any]] = [
    {
        "id": 1,
        "title": "Clear naming",
        "description": "Names should communicate intent and avoid cryptic abbreviations.",
        "weight": 10,
    },
    {
        "id": 2,
        "title": "Small focused units",
        "description": "Functions and modules should do one thing and keep complexity low.",
        "weight": 10,
    },
    {
        "id": 3,
        "title": "Explicit error handling",
        "description": "Errors should be handled intentionally rather than ignored or swallowed.",
        "weight": 10,
    },
    {
        "id": 4,
        "title": "Avoid duplication",
        "description": "Repeated logic should be consolidated when doing so improves maintainability.",
        "weight": 10,
    },
    {
        "id": 5,
        "title": "Tests updated",
        "description": "Behavioral changes should be covered by tests or clearly justified.",
        "weight": 10,
    },
    {
        "id": 6,
        "title": "Readable structure",
        "description": "Code should be easy to scan, with sensible organization and flow.",
        "weight": 10,
    },
    {
        "id": 7,
        "title": "Security awareness",
        "description": "The change should not introduce obvious injection, auth, or secret-handling issues.",
        "weight": 10,
    },
    {
        "id": 8,
        "title": "Performance sanity",
        "description": "The patch should not introduce obvious performance regressions.",
        "weight": 10,
    },
    {
        "id": 9,
        "title": "Formatting and style",
        "description": "The change should respect project style and formatting conventions.",
        "weight": 10,
    },
    {
        "id": 10,
        "title": "Commit coherence",
        "description": "The commit message, scope, and diff should tell a coherent story.",
        "weight": 10,
    },
]


@dataclass
class RuleScore:
    id: int
    title: str
    score: float
    weight: int
    explanation: str
    evidence: List[str]


@dataclass
class ReviewResult:
    commit_sha: str
    commit_short: str
    commit_date: str
    author: str
    subject: str
    total_score: float
    summary: str
    strengths: List[str]
    risks: List[str]
    recommendations: List[str]
    rule_scores: List[RuleScore]


def run(cmd: List[str], cwd: Optional[Path] = None) -> str:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return proc.stdout.strip()


def git(repo: Path, *args: str) -> str:
    return run(["git", "-C", str(repo), *args])


def resolve_repo(repo_arg: Optional[str]) -> Path:
    if repo_arg:
        repo = Path(repo_arg).expanduser().resolve()
    else:
        repo = Path(os.environ.get("HOME", "~")).expanduser() / "ai.git"
    if not (repo / ".git").exists():
        raise SystemExit(f"Not a git repository: {repo}")
    return repo


def get_latest_commit(repo: Path) -> Dict[str, str]:
    sha = git(repo, "rev-parse", "HEAD")
    short_sha = git(repo, "rev-parse", "--short", "HEAD")
    subject = git(repo, "log", "-1", "--pretty=%s")
    author = git(repo, "log", "-1", "--pretty=%an <%ae>")
    commit_date = git(repo, "log", "-1", "--pretty=%cs")
    return {
        "sha": sha,
        "short_sha": short_sha,
        "subject": subject,
        "author": author,
        "commit_date": commit_date,
    }


def get_changed_files(repo: Path, sha: str) -> List[str]:
    out = git(repo, "diff-tree", "--no-commit-id", "--root", "--name-only", "-r", sha)
    if not out:
        return []
    return [line.strip() for line in out.splitlines() if line.strip()]


def get_commit_diff(repo: Path, sha: str, max_chars: int = 40000) -> str:
    show = git(
        repo,
        "show",
        "--no-ext-diff",
        "--format=fuller",
        "--stat",
        "--patch",
        "--unified=3",
        sha,
    )
    if len(show) <= max_chars:
        return show
    return show[:max_chars] + "\n\n[TRUNCATED]\n"


def get_head_marker(repo: Path) -> str:
    return git(repo, "rev-parse", "HEAD")


def build_prompt(commit_info: Dict[str, str], diff_text: str, changed_files: List[str]) -> str:
    rules_text = "\n".join(
        f"{rule['id']}. {rule['title']} (weight {rule['weight']}): {rule['description']}"
        for rule in RULES
    )
    return f"""You are a strict but fair senior engineer performing a code review of a single git commit.

Review this commit using the 10 rules below. Score each rule from 0 to 10, where 10 is best.
Give an overall score from 0 to 100. Use evidence from the diff. If the diff is missing tests or documentation, say so.
Do not invent facts beyond the commit.

Return valid JSON with exactly this shape:
{{
  "summary": "one paragraph",
  "total_score": 0-100 number,
  "strengths": ["..."],
  "risks": ["..."],
  "recommendations": ["..."],
  "rule_scores": [
    {{"id":1, "title":"...", "score":0-10 number, "explanation":"...", "evidence":["...", "..."]}}
  ]
}}

Rules:
{rules_text}

Commit metadata:
- SHA: {commit_info['sha']}
- Short SHA: {commit_info['short_sha']}
- Subject: {commit_info['subject']}
- Author: {commit_info['author']}
- Commit date: {commit_info['commit_date']}
- Changed files: {', '.join(changed_files) if changed_files else 'None'}

Diff:
{diff_text}
"""


def llm_review(commit_info: Dict[str, str], diff_text: str, changed_files: List[str]) -> Dict[str, Any]:
    model = os.environ.get("TF_VAR_responses_model_id")
    if not model:
        raise SystemExit("TF_VAR_responses_model_id is not set")

    try:
        from openai import OpenAI
    except ImportError as exc:  # pragma: no cover
        raise SystemExit(
            "Missing dependency: openai. Install it with: pip install openai"
        ) from exc

    client = OpenAI()
    prompt = build_prompt(commit_info, diff_text, changed_files)
    response = client.responses.create(
        model=model,
        input=prompt,
    )

    raw = getattr(response, "output_text", None)
    if not raw:
        raise RuntimeError("The model returned no text output")

    # Keep the parser forgiving: find the first JSON object in the output.
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise RuntimeError(f"Model did not return JSON:\n{raw}")
    json_text = raw[start : end + 1]
    data = json.loads(json_text)
    return data


def clamp_score(v: Any) -> float:
    try:
        n = float(v)
    except Exception:
        return 0.0
    return max(0.0, min(10.0, n))


def normalize_result(commit_info: Dict[str, str], data: Dict[str, Any]) -> ReviewResult:
    rule_map = {r["id"]: r for r in RULES}
    rule_scores: List[RuleScore] = []
    raw_rule_scores = data.get("rule_scores", []) or []
    by_id = {int(item.get("id")): item for item in raw_rule_scores if item.get("id") is not None}

    for rule in RULES:
        item = by_id.get(rule["id"], {})
        rule_scores.append(
            RuleScore(
                id=rule["id"],
                title=str(item.get("title") or rule["title"]),
                score=clamp_score(item.get("score", 0)),
                weight=int(rule["weight"]),
                explanation=str(item.get("explanation") or ""),
                evidence=[str(x) for x in (item.get("evidence") or [])][:5],
            )
        )

    total = data.get("total_score")
    if total is None:
        total = round(sum(rs.score for rs in rule_scores) / len(rule_scores) * 10, 1)
    else:
        total = max(0.0, min(100.0, float(total)))

    return ReviewResult(
        commit_sha=commit_info["sha"],
        commit_short=commit_info["short_sha"],
        commit_date=commit_info["commit_date"],
        author=commit_info["author"],
        subject=commit_info["subject"],
        total_score=round(float(total), 1),
        summary=str(data.get("summary") or ""),
        strengths=[str(x) for x in (data.get("strengths") or [])][:10],
        risks=[str(x) for x in (data.get("risks") or [])][:10],
        recommendations=[str(x) for x in (data.get("recommendations") or [])][:10],
        rule_scores=rule_scores,
    )


def score_band(score: float) -> str:
    if score >= 85:
        return "excellent"
    if score >= 70:
        return "good"
    if score >= 50:
        return "mixed"
    return "needs-work"


def html_page(result: ReviewResult, repo: Path, diff_text: str, changed_files: List[str]) -> str:
    safe = html.escape
    rule_rows = []
    for rule in result.rule_scores:
        bar_width = int(round(rule.score * 10))
        rule_rows.append(
            f"""
            <tr>
              <td>{rule.id}</td>
              <td><strong>{safe(rule.title)}</strong><div class="muted">{safe(rule.explanation)}</div></td>
              <td>
                <div class="score-row"><span>{rule.score:.1f}/10</span><div class="bar"><div class="fill" style="width:{bar_width}%"></div></div></div>
              </td>
              <td>{safe(' | '.join(rule.evidence) if rule.evidence else 'No evidence cited')}</td>
            </tr>
            """
        )

    def bullet_list(items: List[str]) -> str:
        if not items:
            return "<p class='muted'>None.</p>"
        return "<ul>" + "".join(f"<li>{safe(item)}</li>" for item in items) + "</ul>"

    def file_list(items: List[str]) -> str:
        if not items:
            return "<p class='muted'>No changed files detected.</p>"
        return "<ul>" + "".join(f"<li><code>{safe(item)}</code></li>" for item in items) + "</ul>"

    commit_short = safe(result.commit_short)
    score_class = score_band(result.total_score)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Code review {commit_short}</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 24px; color: #1f2937; background: #f9fafb; }}
    .card {{ background: white; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; margin-bottom: 18px; box-shadow: 0 1px 2px rgba(0,0,0,.04); }}
    h1, h2 {{ margin: 0 0 12px; }}
    .muted {{ color: #6b7280; font-size: 0.95em; }}
    .score {{ font-size: 48px; font-weight: 700; margin: 0; }}
    .excellent {{ color: #047857; }}
    .good {{ color: #0f766e; }}
    .mixed {{ color: #b45309; }}
    .needs-work {{ color: #b91c1c; }}
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ text-align: left; border-top: 1px solid #e5e7eb; padding: 12px 8px; vertical-align: top; }}
    th {{ font-size: 0.85rem; text-transform: uppercase; letter-spacing: .04em; color: #6b7280; }}
    .bar {{ width: 180px; height: 10px; background: #e5e7eb; border-radius: 999px; overflow: hidden; display: inline-block; vertical-align: middle; margin-left: 10px; }}
    .fill {{ height: 100%; background: #2563eb; }}
    .score-row {{ display: flex; align-items: center; gap: 8px; }}
    pre {{ white-space: pre-wrap; word-break: break-word; background: #111827; color: #f9fafb; padding: 16px; border-radius: 12px; overflow-x: auto; }}
    ul {{ margin: 8px 0 0 20px; }}
    .meta {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }}
    .pill {{ display: inline-block; background: #eef2ff; color: #3730a3; padding: 4px 10px; border-radius: 999px; font-size: 12px; margin-left: 10px; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>Commit review <span class="pill">{safe(result.commit_short)}</span></h1>
    <p class="muted">Repo: {safe(str(repo))} · Generated: {safe(now)}</p>
    <div class="meta">
      <div><strong>Commit</strong><br>{safe(result.commit_sha)}</div>
      <div><strong>Author</strong><br>{safe(result.author)}</div>
      <div><strong>Date</strong><br>{safe(result.commit_date)}</div>
      <div><strong>Subject</strong><br>{safe(result.subject)}</div>
    </div>
  </div>

  <div class="card">
    <h2>Total score</h2>
    <p class="score {score_class}">{result.total_score:.1f}<span style="font-size:20px"> / 100</span></p>
    <p class="muted">Overall assessment: <strong>{score_class.replace('-', ' ')}</strong></p>
  </div>

  <div class="card">
    <h2>Summary</h2>
    <p>{safe(result.summary) if result.summary else '<span class="muted">No summary returned.</span>'}</p>
  </div>

  <div class="card">
    <h2>Changed files</h2>
    {file_list(changed_files)}
  </div>

  <div class="card">
    <h2>Rule scores</h2>
    <table>
      <thead>
        <tr><th>#</th><th>Rule</th><th>Score</th><th>Evidence</th></tr>
      </thead>
      <tbody>
        {''.join(rule_rows)}
      </tbody>
    </table>
  </div>

  <div class="card">
    <h2>Strengths</h2>
    {bullet_list(result.strengths)}
  </div>

  <div class="card">
    <h2>Risks</h2>
    {bullet_list(result.risks)}
  </div>

  <div class="card">
    <h2>Recommendations</h2>
    {bullet_list(result.recommendations)}
  </div>

  <div class="card">
    <h2>Raw diff excerpt</h2>
    <pre>{safe(diff_text[:12000])}</pre>
  </div>
</body>
</html>
"""


def derive_appdirs(changed_files: List[str]) -> List[str]:
    import fnmatch

    patterns = ["Dockerfile", "build", "install.sh", "restart.sh", "k8s*"]
    dirs = set()
    for rel in changed_files:
        path = Path(rel)
        parts = [p for p in path.parts[:-1]]
        matched = False
        # Match either the file name itself or any directory segment in the path.
        if any(fnmatch.fnmatch(path.name, pat) for pat in patterns):
            matched = True
        elif any(fnmatch.fnmatch(part, pat) for part in parts for pat in patterns):
            matched = True
        if not matched:
            continue
        parent = path.parent
        if parent == Path('.'):
            continue
        if len(parent.parts) in (1, 2):
            dirs.add(parent.as_posix())
    return sorted(dirs)


def write_report(repo: Path, result: ReviewResult, diff_text: str, changed_files: List[str]) -> Path:
    out_dir = Path(os.environ.get("HOME", "~")).expanduser() / "code_review"
    out_dir.mkdir(parents=True, exist_ok=True)
    file_date = datetime.now().strftime("%Y-%m-%d")
    out_path = out_dir / f"{file_date}-{result.commit_short}.html"
    out_path.write_text(html_page(result, repo, diff_text, changed_files), encoding="utf-8")
    return out_path


def write_appdir(commit_short: str, appdirs: List[str]) -> Path:
    out_dir = Path(os.environ.get("HOME", "~")).expanduser() / "code_review"
    out_dir.mkdir(parents=True, exist_ok=True)
    file_date = datetime.now().strftime("%Y-%m-%d")
    out_path = out_dir / f"{file_date}-{commit_short}.appdir"
    out_path.write_text("\n".join(appdirs) + ("\n" if appdirs else ""), encoding="utf-8")
    return out_path


def generate_report(repo: Path) -> Path:
    commit_info = get_latest_commit(repo)
    changed_files = get_changed_files(repo, commit_info["sha"])
    diff_text = get_commit_diff(repo, commit_info["sha"])
    data = llm_review(commit_info, diff_text, changed_files)
    result = normalize_result(commit_info, data)
    html_path = write_report(repo, result, diff_text, changed_files)
    appdirs = derive_appdirs(changed_files)
    write_appdir(result.commit_short, appdirs)
    return html_path


def install_hook(repo: Path) -> Path:
    hooks_dir = repo / ".git" / "hooks"
    hooks_dir.mkdir(parents=True, exist_ok=True)
    hook_path = hooks_dir / "post-commit"
    script_path = Path(__file__).resolve()

    hook_content = f"""#!/bin/sh
set -eu
python3 {json.dumps(str(script_path))} --repo {json.dumps(str(repo))} --once >> {json.dumps(str(Path(os.environ.get('HOME', '~')).expanduser() / 'code_review' / 'hook.log'))} 2>&1
"""
    hook_path.write_text(hook_content, encoding="utf-8")
    hook_path.chmod(0o755)
    return hook_path


def watch(repo: Path, interval: int) -> None:
    last = None
    while True:
        try:
            current = get_head_marker(repo)
            if current != last:
                report = generate_report(repo)
                print(f"Generated {report}")
                last = current
        except subprocess.CalledProcessError as exc:
            print(f"git error: {exc.stderr}", file=sys.stderr)
        except Exception as exc:
            print(f"error: {exc}", file=sys.stderr)
        time.sleep(interval)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", help="Path to the git repo (default: $HOME/ai.git)")
    parser.add_argument("--once", action="store_true", help="Generate one report and exit")
    parser.add_argument("--watch", action="store_true", help="Poll HEAD and generate reports on commit changes")
    parser.add_argument("--interval", type=int, default=10, help="Polling interval in seconds for --watch")
    parser.add_argument("--install-hook", action="store_true", help="Install a git post-commit hook")
    args = parser.parse_args()

    repo = resolve_repo(args.repo)

    if args.install_hook:
        hook = install_hook(repo)
        print(f"Installed hook: {hook}")
        return 0

    if args.watch:
        watch(repo, args.interval)
        return 0

    report = generate_report(repo)
    print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
