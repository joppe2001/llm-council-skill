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

1. **Members get distinct personas** (a reasoning method plus a temperament) and are told to push
   their own angle hard rather than give the balanced answer.
2. **Review is anonymous.** A reviewer never knows which answer is its own, so it can't defer
   politely or protect its ego. This is the real anti-sycophancy engine.
3. **The Chairman picks the best-argued position**, including a minority one. It does not blend
   conflicting views into a vague compromise.

## The Process

When invoked with a question Q, run these three stages in order.

### Stage 1: Collect (fan-out with personas)

Dispatch Q to **3 council members in parallel**, each a subagent. Launch all three in a single
message (one `Agent` call each). Diversity comes from the **persona**, not the model tier. Each
persona is a real cognitive stance (a reasoning method, a thing it optimizes for, a failure mode
it is allergic to) wrapped in a light temperament so the members genuinely pull in different
directions instead of converging.

**Default council (3 members):**

| Member | `model` | persona |
|--------|---------|---------|
| Member A | `opus`   | First-principles engineer |
| Member B | `opus`   | Red-teamer / skeptic |
| Member C | `sonnet` | Pragmatist / operator |

**Persona library** (use the default 3; for a 5-member council add Systems thinker + Empiricist;
swap in User advocate when the question is about a product or human experience):

| persona | reasoning method | optimizes for | allergic to | temperament |
|---|---|---|---|---|
| First-principles engineer | strips assumptions, reasons up from fundamentals | correctness | cargo-culting, "that's just how it's done" | blunt, unsentimental |
| Red-teamer / skeptic | assumes the popular answer is wrong and attacks it | robustness | overconfidence, hand-waving | adversarial, relentless |
| Pragmatist / operator | what actually ships under time/money/people limits | shippability | ivory-tower purity | impatient, results-driven |
| Systems thinker | second-order effects, incentives, long-term dynamics | durability | local wins that blow up later | calm, big-picture |
| Empiricist | demands data, base rates, concrete examples | groundedness | vibes-based claims | dry, show-me-the-evidence |
| User advocate | the real human affected, plain language | real usefulness | technically-correct-but-useless | warm, human |

Each member's prompt is the shared block plus its persona card:

> You are a member of a deliberative council answering a question. Give your strongest
> independent answer. Be substantive and concrete. Do NOT hedge by deferring to other members,
> and do NOT soften your view to sound agreeable. State your reasoning and be explicit about
> what you are uncertain about and why.
>
> YOUR PERSONA: {persona name}
> - How you reason: {reasoning method}
> - What you optimize for: {optimizes for}
> - What you refuse to tolerate: {allergic to}
> - Your temperament: {temperament}. Let it color how you argue, but never at the expense of
>   substance. The temperament is how you say it; the reasoning is what matters.
>
> Answer in character, from your persona's angle. Do not try to give the balanced, all-sides
> answer. That is the Chairman's job later. Your job is to push your angle as hard as it honestly
> goes.
>
> QUESTION:
> {Q}

Collect the three responses verbatim. Label them internally R_A, R_B, R_C but **do not reveal
which model or persona produced which** in the next stage. Anonymity covers the persona too: a
reviewer who knows "this is the grumpy skeptic" will discount the tone instead of judging the
reasoning.

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

- **Default council**: opus (first-principles engineer) + opus (red-teamer) + sonnet
  (pragmatist). Diversity is driven by persona, not model strength.
- **Max quality**: make all three `opus`.
- **Quick / cheap mode**: only if the user explicitly asks for fast-and-cheap, you may use
  sonnet/sonnet/haiku. Note that haiku is the weak link and likelier to defer, which undercuts
  the non-yes-man goal, so do not use it by default.
- **Council size**: default 3. For a bigger panel add distinct personas from the library (e.g.
  systems thinker, empiricist), never duplicate a persona.
- **Match personas to the question**: swap in the User advocate for product/UX questions, the
  Empiricist for factual/data questions, the Systems thinker for strategy/architecture. Keep the
  red-teamer in almost every council, it is the main source of dissent.
- **Skip review**: only if the user asks for plain parallel answers. Skipping review removes the
  main anti-sycophancy mechanism, so warn them it becomes a weaker council.

## Notes

- Keep member identities, models, and personas hidden during review. Anonymity is what keeps the
  critique honest. It is the core mechanic. Personas make the inputs diverse; anonymity keeps the
  judging fair.
- Run each stage's subagents in parallel (multiple `Agent` calls in one message) for speed.
