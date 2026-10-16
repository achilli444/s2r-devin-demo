#!/usr/bin/env python3
"""Port the Spec2RTL (Claude Code / OpenCode / Gemini) plugin into Devin repo skills.

Input : upstream/spec2rtl-plugin/{commands/s2r/*.md, spec2rtl/{agents,workflows,templates,references}}
Output: .devin/skills/s2r-<command>/SKILL.md   (one skill per slash command)
        .devin/skills/s2r-core/{agents,workflows,templates,references}/  (shared material)

Only text rewrites; the methodology is untouched. Re-run after bumping upstream/.
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UP = ROOT / "upstream" / "spec2rtl-plugin"
SKILLS = ROOT / ".devin" / "skills"
CORE = SKILLS / "s2r-core"
CORE_REL = ".devin/skills/s2r-core"

# Claude-Code-only commands with no Devin equivalent.
SKIP_COMMANDS = {"update", "join-discord"}

RUNTIME_NOTE = """> **Devin runtime.** This skill is a port of the Spec2RTL `/s2r:{cmd}` command.
> Before following it, read `{core}/SKILL.md` (tool mapping, path conventions, what to ignore).
> Any path under `{core}/` or `.planning/` that this skill lists is a file you must read.
> `Task(...)` = spawn a subagent whose prompt starts with the named agent file from `{core}/agents/`;
> if no subagent tool is available, read that agent file and do its work inline, one Task at a time.
> `AskUserQuestion` = ask the user with `message_user` (`content_type=user_question`).
> `model=...` / model profiles are ignored on Devin.
"""


def rewrite_body(text: str) -> str:
    # Claude-Code "@file" includes -> explicit read instructions when the include is the whole line.
    def include_line(m):
        indent, path = m.group(1), m.group(2)
        path = path.replace("~/.claude/spec2rtl/", f"{CORE_REL}/")
        return f"{indent}Read `{path}`"

    text = re.sub(r"^(\s*)@(~/\.claude/spec2rtl/[^\s`]+)\s*$", include_line, text, flags=re.M)
    text = re.sub(r"^(\s*)@(\.planning/[^\s`]+)\s*$", include_line, text, flags=re.M)
    # Remaining inline "@path" references -> plain paths.
    text = re.sub(r"@(~/\.claude/spec2rtl/)", r"\1", text)
    text = re.sub(r"@(\.planning/)", r"\1", text)
    # Install-location paths.
    text = text.replace("~/.claude/spec2rtl/", f"{CORE_REL}/")
    text = text.replace("~/.claude/agents/", f"{CORE_REL}/agents/")
    text = text.replace("~/.claude/commands/gsd/", f"{SKILLS.relative_to(ROOT)}/")
    # Drop model selection args; Devin has no per-subagent model switch.
    text = re.sub(r",\s*model=\"[^\"]*\"", "", text)
    text = re.sub(r"^\s*model=\"[^\"]*\",?\s*\n", "", text, flags=re.M)
    # Leftover upstream (GSD) naming.
    text = re.sub(r"\bgsd:", "s2r:", text)
    text = text.replace('"gsd/', '"s2r/')
    text = re.sub(r"^\s*Co-Authored-By: Claude.*\n", "", text, flags=re.M)
    # Vendor/runtime naming.
    text = text.replace("Claude Code", "Devin")
    text = re.sub(r"\bClaude's\b", "Devin's", text)
    text = re.sub(r"\bClaude\b(?! (Opus|Sonnet|Haiku|model))", "Devin", text)
    return text


def parse_frontmatter(text: str):
    if not text.startswith("---"):
        return {}, text
    end = text.index("\n---", 3)
    fm_raw = text[3:end].strip("\n")
    body = text[end + 4:].lstrip("\n")
    fm = {}
    for line in fm_raw.splitlines():
        m = re.match(r"^([a-z-]+):\s*(.*)$", line)
        if m:
            fm[m.group(1)] = m.group(2).strip().strip('"')
    return fm, body


def port_commands():
    out = []
    for src in sorted((UP / "commands" / "s2r").glob("*.md")):
        cmd = src.stem
        if cmd in SKIP_COMMANDS:
            continue
        fm, body = parse_frontmatter(src.read_text())
        desc = rewrite_body(fm.get("description", f"Spec2RTL {cmd}"))
        hint = fm.get("argument-hint", "")
        body = rewrite_body(body)
        skill_dir = SKILLS / f"s2r-{cmd}"
        skill_dir.mkdir(parents=True, exist_ok=True)
        usage = f"Usage: `/s2r:{cmd} {hint}`".rstrip() + "\n\n" if hint else f"Usage: `/s2r:{cmd}`\n\n"
        trigger = f"Use when the user types `/s2r:{cmd}` or asks for this step of the Spec2RTL hardware spec-driven flow."
        skill = (
            "---\n"
            f"name: s2r-{cmd}\n"
            f"description: {desc}. {trigger}\n"
            "---\n\n"
            + RUNTIME_NOTE.format(cmd=cmd, core=CORE_REL)
            + "\n"
            + usage
            + body
        )
        (skill_dir / "SKILL.md").write_text(skill)
        out.append(cmd)
    return out


def port_core():
    for sub in ("agents", "workflows", "templates", "references"):
        dst = CORE / sub
        if dst.exists():
            shutil.rmtree(dst)
        dst.mkdir(parents=True)
        for src in sorted((UP / "spec2rtl" / sub).rglob("*")):
            rel = src.relative_to(UP / "spec2rtl" / sub)
            if src.is_dir():
                (dst / rel).mkdir(parents=True, exist_ok=True)
                continue
            if src.suffix == ".md":
                (dst / rel).write_text(rewrite_body(src.read_text()))
            else:
                shutil.copy2(src, dst / rel)


def check_leftovers():
    bad = []
    for p in SKILLS.rglob("*.md"):
        if p == CORE / "SKILL.md":
            continue
        t = p.read_text()
        for pat in (r"~/\.claude", r"\bClaude Code\b", r"^\s*@~", r"subagent_type=\"[^\"]*\", model="):
            if re.search(pat, t, flags=re.M):
                bad.append((str(p.relative_to(ROOT)), pat))
    return bad


if __name__ == "__main__":
    cmds = port_commands()
    port_core()
    print(f"ported {len(cmds)} commands -> {SKILLS.relative_to(ROOT)}/s2r-*/SKILL.md")
    print(f"core    -> {CORE_REL}/{{agents,workflows,templates,references}}")
    left = check_leftovers()
    for f, pat in left:
        print(f"LEFTOVER {pat!r} in {f}", file=sys.stderr)
    sys.exit(1 if left else 0)
