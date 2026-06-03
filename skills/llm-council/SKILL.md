---
name: llm-council
description: "Convene a council of multiple models to deliberate on a question, then synthesize one answer. Ported from karpathy/llm-council. Fans a prompt out to several council members (Claude subagents given distinct adversarial roles), has each anonymously critique and rank the others' answers, then a Chairman model synthesizes the best-argued answer. This is a non-yes-man council: members are told to disagree where warranted and reviewers hunt for the weakest claim. Use when the user asks to 'convene the council', 'ask the llm council', 'run a council', wants multiple perspectives to deliberate, peer-review each other, or wants a higher-confidence, less sycophantic answer on a hard, open-ended, or high-stakes question."
---

# LLM Council

A multi-model deliberation skill, ported from [karpathy/llm-council](https://github.com/karpathy/llm-council).
The original is a FastAPI + React web app that gets cross-vendor diversity (GPT, Gemini, Claude,
Grok). This skill is Claude-only, so it manufactures diversity a different way: **distinct
adversarial roles + anonymous peer review**. That combination is what makes it a non-yes-man
council instead of three models politely agreeing.

## Core principle: this is NOT a yes-man council

Same-family models drift toward agreement, and a naive "synthesize everything" chairman just
averages opinions into mush. Three rules counter that, and they are load-bearing:

1. **Members get adversarial roles** and are told to disagree where the reasoning supports it.
2. **Review is anonymous.** A reviewer never knows which answer is its own, so it can't defer
   politely or protect its ego. This is the real anti-sycophancy engine.
3. **The Chairman picks the best-argued position**, including a minority one. It does not blend
   conflicting views into a vague compromise.

## The Process

When invoked with a question Q, run these three stages in order.

### Stage 1: Collect (fan-out with roles)

Dispatch Q to **3 council members in parallel**, each a subagent. Launch all three in a single
message (one `Agent` call each). Diversity comes from the **role**, not the model tier:

| Member | `model` | role | `subagent_type` |
|--------|---------|------|-----------------|
| Member A | `opus`   | First-principles thinker | `general-purpose` |
| Member B | `opus`   | Skeptic / devil's advocate | `general-purpose` |
| Member C | `sonnet` | Pragmatist (real-world constraints) | `general-purpose` |

Each member's prompt is the shared block plus its role line:

> You are a member of a deliberative council answering a question. Give your strongest
> independent answer. Be substantive and concrete. Do NOT hedge by deferring to other models,
> and do NOT soften your view to sound agreeable. State your reasoning and be explicit about
> what you are uncertain about and why.
>
> YOUR ROLE: {role}
> - First-principles thinker: ignore convention and received wisdom. Reason up from
>   fundamentals. Question assumptions baked into the question itself.
> - Skeptic / devil's advocate: assume the obvious answer is wrong. Attack the strongest
>   counter-position. Surface failure modes, risks, and what everyone tends to overlook.
> - Pragmatist: optimize for what actually works in the real world given cost, time, and
>   constraints. Call out where the theoretically-best answer breaks down in practice.
>
> QUESTION:
> {Q}

Collect the three responses verbatim. Label them internally R_A, R_B, R_C but **do not reveal
which model or role produced which** in the next stage.

### Stage 2: Review (anonymous peer review)

Dispatch **3 reviewer subagents in parallel** (reuse opus/opus/sonnet). Each reviewer receives
all three answers presented **anonymously and shuffled** as "Response 1 / 2 / 3". Do not tell a
reviewer its own answer, its role, or which model wrote what. Each reviewer's prompt:

> Below are anonymous responses to the same question. Be a tough, fair critic, not a cheerleader.
> For EACH response: find its single weakest claim or biggest gap and say why it is weak. Flag
> anything factually shaky, hand-wavy, or unsupported. Do not praise without evidence. Then rank
> all three best to worst and justify the ranking on reasoning quality, not tone or confidence.
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

### Stage 3: Chairman (synthesis, not averaging)

Act as the **Chairman yourself** (the main model), or dispatch one `opus` subagent if you want
isolation. Given Q, the three original answers, and the three anonymous reviews:

> You are the Chairman of the council. You have the original answers and the council's anonymous
> critiques. Your job is to deliver the single best answer, NOT a diplomatic blend.
>
> - Side with the position that has the strongest reasoning, even if only one member held it.
> - Do NOT average conflicting views into a vague middle. If members disagree, pick a side and
>   say why the other side is weaker.
> - Fold in any errors or gaps the reviewers caught and correct them.
> - State the genuine remaining uncertainty honestly. Do not paper over it to sound confident.
>
> Produce the answer a sharp, skeptical expert would actually endorse.

## Output to the user

Present:
1. **Final answer** (the Chairman's call). This is the headline.
2. A short **council notes** section: where the members disagreed, which position won and why,
   and what the reviews changed. Surface real dissent here. Do not hide it.

Optionally, if the user asks to "show the work", include each member's full response and review.

## Tuning

- **Default council**: opus (first-principles) + opus (skeptic) + sonnet (pragmatist). Diversity
  is driven by role, not model strength.
- **Max quality**: make all three `opus`.
- **Quick / cheap mode**: only if the user explicitly asks for fast-and-cheap, you may use
  sonnet/sonnet/haiku. Note that haiku is the weak link and likelier to defer, which undercuts
  the non-yes-man goal, so do not use it by default.
- **Council size**: default 3. If the user wants more members, add more roles (e.g. a
  domain-expert, a contrarian), do not just duplicate the same role.
- **Skip review**: only if the user asks for plain parallel answers. Skipping review removes the
  main anti-sycophancy mechanism, so warn them it becomes a weaker council.

## Notes

- Keep member identities, models, and roles hidden during review. Anonymity is what keeps the
  critique honest. It is the core mechanic.
- Run each stage's subagents in parallel (multiple `Agent` calls in one message) for speed.
