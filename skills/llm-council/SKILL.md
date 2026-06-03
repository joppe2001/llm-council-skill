---
name: llm-council
description: "Convene a council of multiple models to deliberate on a question, then synthesize one answer. Ported from karpathy/llm-council. Fans a prompt out to several council members (different Claude models as subagents), has each anonymously review and rank the others' responses, then a Chairman model synthesizes a single final answer. Use when the user asks to 'convene the council', 'ask the llm council', 'run a council', wants multiple models / multiple perspectives to deliberate, peer-review each other, or wants a higher-confidence synthesized answer on a hard, open-ended, or high-stakes question."
---

# LLM Council

A multi-model deliberation skill, ported from [karpathy/llm-council](https://github.com/karpathy/llm-council).
The original is a FastAPI + React web app calling OpenRouter; this skill reproduces its
**three-stage council process** natively in Claude Code using subagents — no API key, no web app.

## The Process

When invoked with a question Q, run these three stages in order.

### Stage 1 — Collect (fan-out)

Dispatch Q to **3 council members in parallel**, each a subagent on a different model so
their reasoning genuinely diverges. Launch all three in a single message (one `Agent` call each):

| Member | `model` | `subagent_type` |
|--------|---------|-----------------|
| Member A | `opus`   | `general-purpose` |
| Member B | `sonnet` | `general-purpose` |
| Member C | `haiku`  | `general-purpose` |

Each member's prompt is exactly:

> Answer the following question as well as you can. Be substantive, concrete, and honest
> about uncertainty. This is your independent answer; do not hedge by deferring to other models.
>
> QUESTION:
> {Q}

Collect the three responses verbatim. Label them internally R_A, R_B, R_C but **do not reveal
which model produced which** in the next stage.

### Stage 2 — Review (anonymous peer review)

Dispatch **3 reviewer subagents in parallel** (reuse the same three models). Each reviewer
receives all three answers presented **anonymously and shuffled** as "Response 1 / 2 / 3"
(do not tell a reviewer which one, if any, is its own). Each reviewer's prompt:

> Below are anonymous responses to the same question. Evaluate them on accuracy, depth,
> reasoning quality, and usefulness. Point out errors or gaps in each. Then rank them best to
> worst and justify the ranking. Be a tough, fair critic.
>
> QUESTION:
> {Q}
>
> RESPONSE 1:
> {first}
>
> RESPONSE 2:
> {second}
>
> RESPONSE 3:
> {third}

Collect the reviews and rankings.

### Stage 3 — Chairman (synthesis)

Act as the **Chairman yourself** (the main model) — or dispatch one `opus` subagent if you want
isolation. Given Q, the three original answers, and the three anonymous reviews, produce the
final answer. Chairman prompt / mindset:

> You are the Chairman of a council of models. You have the original answers and the council's
> anonymous peer reviews. Synthesize a single best answer to the question. Incorporate the
> strongest points, correct errors the reviewers caught, resolve disagreements explicitly, and
> note any remaining genuine uncertainty. Produce the answer the council would endorse.

## Output to the user

Present:
1. **Final answer** (the Chairman's synthesis) — this is the headline.
2. A short **council notes** section: the consensus, any notable disagreement between members,
   and what the reviews changed. Keep it tight.

Optionally, if the user asks to "show the work", include each member's full response and review.

## Tuning

- **Models**: default is opus/sonnet/haiku for diversity. If the user wants max quality and
  cost is no concern, use opus for all three members. For a quick council, use sonnet/haiku/haiku.
- **Council size**: default 3. Honor the user if they ask for more or fewer members.
- **Skip review**: if the user just wants parallel answers without peer review, run Stage 1 + 3 only.

## Notes

- Keep member identities hidden during review — anonymity is what makes the peer review honest;
  it's the core mechanic of the original project.
- Run each stage's subagents in parallel (multiple `Agent` calls in one message) for speed.
