---
name: naturalize-ukrainian
description: >
  Edit Ukrainian texts to sound natural without loss of meaning. Specialized for three problem types:
  (1) texts translated into Ukrainian (human, DeepL, Google Translate) that carry English or Russian
  syntax and calques; (2) texts written by AI directly in Ukrainian; (3) texts written by AI in English
  and then translated into Ukrainian - the worst case, combining AI cliches with translationese.
  Trigger whenever the user asks to edit, polish, naturalize, or de-AI a Ukrainian text, says a text
  "звучить як переклад", "звучить штучно", "звучить не по-людськи", asks to "відредагуй", "зроби
  природнішим", "перепиши людською мовою", "прибери кальки", "прибери русизми", or shares Ukrainian
  text that reads as machine-translated or AI-generated. Also trigger when the user asks to translate
  something INTO Ukrainian and wants it to sound native, not translated.
---

# Naturalize Ukrainian Text

Edit Ukrainian text so it reads as if written by a competent native speaker - while preserving every fact, claim, number, and nuance of the original. This is editing, not rewriting: the author's meaning and voice survive; the translationese and AI residue do not.

## Reference files

Load these as needed during the diagnostic and lexical passes:

- `references/calques-and-russisms.md` - substitution tables: English calques, Russisms, active participles, nominalization chains, bureaucratese.
- `references/ai-markers.md` - AI-writing patterns in Ukrainian: cliche inventory, structural tells, and what to do with each.

## Step 1: Diagnose the text type

Read the whole text first. Classify it - each type has a distinct signature and needs different emphasis:

| Type | Signature | Priority fixes |
|---|---|---|
| **Translated from English** | Rigid SVO word order, overt pronouns everywhere, redundant possessives (свої руки), passive with agent, analytic comparatives (більш швидкий), lexical calques | Syntax pass first, then calques |
| **Translated via/from Russian, or written by a Russian-dominant author** | Russisms (приймати участь, на протязі, у відповідності), active participles (існуючий, працюючий), bureaucratic nominal style | Lexicon pass first |
| **AI-written in Ukrainian** | Cliche openers (У сучасному світі), triads, "важливо зазначити", uniform paragraph rhythm, bold-term lists, hollow conclusions starting with Отже | AI-markers pass, then rhythm |
| **AI-written in English, then translated** | All of the above at once: AI cliches THAT ARE ALSO calques (відіграє ключову роль, розкрити потенціал, ландшафт, безшовний) | Full treatment, all passes |
| **Human draft needing polish** | Isolated issues, natural core | Light touch only - fix errors, keep voice |

Also fix the register: academic paper, official correspondence (formal Ви, capitalized in direct address), business, web copy, informal. The register of the original is preserved unless the user asks otherwise.

Note protected material before touching anything (see Step 4).

## Step 2: Edit in passes

Work through the text in this order. Later passes are cheaper when earlier ones are done first.

### Pass 1 - Syntax (de-anglicization)

1. **Word order / information structure.** Ukrainian orders information theme → rheme: known information first, new information last. English SVO carried into Ukrainian buries the point mid-sentence.
   - "Нова політика була запроваджена урядом у 2022 році" → "У 2022 році уряд запровадив нову політику."
2. **Drop redundant pronouns.** Ukrainian is pro-drop; the verb carries person.
   - "Я вважаю, що я зможу це зробити" → "Вважаю, що зможу це зробити."
3. **Drop redundant possessives.** English requires them; Ukrainian does not.
   - "Він поклав свої руки у свої кишені" → "Він поклав руки в кишені."
4. **Convert passive to active** where an agent exists, or to the natural Ukrainian impersonal -но/-то form where it does not.
   - "Звіт був підготовлений командою" → "Звіт підготувала команда."
   - "Було ухвалено рішення" → "Ухвалено рішення" (the -но/-то form is good Ukrainian; "було + passive participle + agent in instrumental" is not).
5. **Synthetic comparatives and superlatives.** "більш ефективний" → "ефективніший"; "найбільш важливий" → "найважливіший"; "один з найбільш поширених" → "один з найпоширеніших".
6. **Kill dummy constructions.** "Існує потреба в тому, щоб..." → "потрібно..."; "той факт, що" → "те, що"; copular "є + instrumental" padding: "Це є свідченням того, що" → "Це свідчить, що".
7. **Remove fake articles.** "певний", "даний", "деякий" standing in for English a/the → usually delete, or "цей".

### Pass 2 - Lexicon

Go through `references/calques-and-russisms.md`. Replace calques, Russisms, active participles in -учий/-ючий, and unwind nominalization chains (здійснити оцінювання впливу → оцінити вплив). Keep frequency in mind: one "в рамках" in a long text is fine; five are a pattern.

### Pass 3 - AI residue

Go through `references/ai-markers.md`. Cut cliche openers and hollow intensifiers, break triads, dissolve unnecessary bullet lists into prose, rewrite the "Отже"-restatement conclusion so it says something. If every "важливо зазначити" were true, nothing would be.

### Pass 4 - Rhythm and discourse

- **Vary sentence length.** Translated and AI text runs at uniform 20-25-word sentences. Natural Ukrainian mixes short and long. Break some, join others.
- **Use native connectives and particles** instead of calqued ones: адже, втім, а втім, щоправда, зрештою, власне, натомість, водночас, тож, принаймні, до речі. These carry the texture that machine output lacks - but add them only where the logic already implies them; never add a connective that changes the argument.
- **Synthetic imperatives** for we-forms: "давайте розглянемо" → "розгляньмо".
- **Vocative case** in correspondence: "Шановний пане Андрію!", never "Шановний пан Андрій".

### Pass 5 - Orthography and mechanics

- Apply the 2019 orthography (чинний правопис): проєкт not проект, indeclinable words, feminatives (дослідниця, авторка) where register allows. Where the pravopys permits variants (етер/ефір, павза/пауза), keep the author's existing choice; do not flip it.
- Ukrainian quotation marks «...» in formal text.
- Never use "—" (em dash) - use "-" instead (user's global preference, applies to Ukrainian text too).
- Capitalized Ви in direct formal correspondence; lowercase ви in general prose about a plural/generic audience.

## Step 3: Verify meaning preservation

Re-read edited text against the original, sentence by sentence. Confirm:

- No factual content dropped, no claims added, no hedges strengthened or weakened (a "може свідчити" must not become "свідчить").
- All numbers, dates, names, citations, URLs verbatim.
- Negations and scope intact (especially after restructuring word order).
- Terminology consistent: the same concept keeps the same term throughout.

If the original is ambiguous and any natural rendering forces a choice of meaning, do not guess - flag the sentence and ask, or present both readings.

## Step 4: Protected material - never touch

- Direct quotations (edit only the text around them).
- Legal/official wording, titles of laws, institutions, cited paper titles.
- Established domain terminology. In the user's field (economics/econometrics) terms like робастний, інструментальна змінна, диференціація різниць/DiD, специфікація are terminology, not calques. When unsure whether a word is jargon or a calque, keep it and note the question.
- Markdown/LaTeX/HTML markup, code, variable names - edit only the human-language content between them.
- Anything the user marked as final.

## Degrees of intervention

Default is **full naturalization**: restructure sentences freely as long as meaning is intact. Two other modes when the context calls for them:

- **Light touch** ("виправ тільки помилки", text going into someone else's document, quoted material): fix only outright errors, Russisms, and the worst calques; do not restructure.
- **Deep rewrite** (explicitly requested): may also tighten, cut redundancy, reorder paragraphs - still zero loss of substantive content, and list what was cut.

Avoid hypercorrection in every mode: do not push accepted common words toward puristic or archaic alternatives (аеропорт stays аеропорт, not летовище) unless the user asks for that style. The target is natural contemporary Ukrainian, not a purity contest.

## Output format

- **Pasted text** → return the edited text in the reply, followed by a short change summary grouped by category (word order, calques, Russisms, AI cliches, orthography) with 2-4 representative examples each - not an exhaustive log. Flag any spots where meaning was ambiguous as explicit questions.
- **Short correspondence (emails, messages)** → provide two variants per the user's global preference: a conservative edit and a fuller naturalization.
- **Files** → write the edited version to a new file next to the original (`name_edited.ext`) unless the user says to edit in place. For .docx, use pandoc or python-docx per the user's global rules - never raw text manipulation - and verify the output opens correctly.
- **Long texts** (over ~2 pages) → after editing, also give a one-paragraph verdict: what type of text it was, the dominant problems, and whether any passages need the author's judgment.
