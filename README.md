# LLM Council — a Claude Code skill

A multi-model deliberation skill for [Claude Code](https://claude.com/claude-code), ported from
[karpathy/llm-council](https://github.com/karpathy/llm-council).

Instead of running a separate web app, this reproduces the council's **three-stage process**
natively using Claude Code subagents — no API key, no server:

1. **Collect** — your question is fanned out to 3 council members in parallel, each on a
   different model (Opus / Sonnet / Haiku) so their reasoning diverges.
2. **Review** — each member *anonymously* peer-reviews and ranks all three answers.
3. **Chairman** — a final model synthesizes one best answer, correcting errors the reviews
   caught and flagging genuine uncertainty.

Use it for hard, open-ended, or high-stakes questions where multiple perspectives help.

---

## Install

### macOS / Linux

**One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/install.sh | bash
```

**Or from a clone:**
```bash
git clone https://github.com/joppe2001/llm-council-skill.git
cd llm-council-skill
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

**One-liner:**
```powershell
irm https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/install.ps1 | iex
```

**Or from a clone:**
```powershell
git clone https://github.com/joppe2001/llm-council-skill.git
cd llm-council-skill
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Both installers copy `SKILL.md` to `~/.claude/skills/llm-council/` (on Windows:
`%USERPROFILE%\.claude\skills\llm-council\`), which makes it a **global** skill available in
every project.

### Manual install

Just copy `skills/llm-council/SKILL.md` to `~/.claude/skills/llm-council/SKILL.md`.

---

## Usage

Start a new Claude Code session (skills load at startup), then either:

**Slash command:**
```
/llm-council should I use Postgres or SQLite for a local-first desktop app?
```

**Or natural language:**
```
convene the council on: <your question>
ask the llm council whether ...
run a council on this decision
```

### Tuning

- **Max quality:** ask for "all-Opus council".
- **Quick council:** ask for "sonnet/haiku council".
- **More members:** "run a 5-member council".
- **Skip peer review:** "just give me parallel answers, no review".

> Note: a full run uses several subagent calls (3 answers + 3 reviews + chairman), so it
> consumes more tokens than a normal reply. Best reserved for questions that warrant it.

---

## How it works

The skill is a single `SKILL.md` instruction file. Claude Code reads its description and either
exposes it as the `/llm-council` slash command or auto-triggers it from natural language. The
deliberation runs via the `Agent` tool with per-member `model` overrides.

## Credit

Concept and process by [Andrej Karpathy](https://github.com/karpathy/llm-council). This repo
is an unofficial port to the Claude Code skill format.

## License

MIT
