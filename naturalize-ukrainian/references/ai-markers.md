# AI-writing markers in Ukrainian

Reference for Pass 3 (AI residue). Two layers: texts AI wrote directly in Ukrainian show mostly the structural tells (section 3) plus translated cliches; texts AI wrote in English and someone then translated show everything at once - the cliches arrive as calques.

The test for every item: does deleting or replacing it lose information? AI filler never does.

## 1. Cliche openers and framing

Delete or replace with substance. These sentences exist to warm up, not to inform.

| Маркер | Що робити |
|---|---|
| У сучасному світі... / У сучасному швидкоплинному світі... | Delete. Start with the actual point. |
| В умовах сьогодення... / На сьогоднішній день... | Delete, or "нині", "зараз" if time reference is needed |
| В епоху цифрових технологій... | Delete |
| Не секрет, що... / Як відомо,... | Delete (if it's known, don't say it; if not, it's not "відомо") |
| Давайте зануримося / розглянемо детальніше | Розгляньмо; or just proceed |
| У цій статті ми розглянемо... | Usually delete; academic texts may keep one roadmap sentence |
| Уявіть собі світ, де... | Delete, start with the fact |

## 2. Cliche inventory (translated AI-slop)

These are the Ukrainian shadows of "plays a key role", "unlock potential", "landscape", "seamless", "delve". Replace with a concrete verb or claim - the fix is almost never a synonym, it is saying what actually happens.

| Маркер | Що робити |
|---|---|
| відіграє ключову роль | Say what it does: "визначає", "уможливлює", "від нього залежить X" |
| важко переоцінити значення | State the significance or cut |
| невід'ємна частина | Usually cut; or "постійний складник" |
| розкрити потенціал | Concretize: "дасть змогу робити X" |
| вивести на новий рівень | Concretize the improvement |
| змінити правила гри (game-changer) | State the actual change |
| ландшафт (бізнес-ландшафт, цифровий ландшафт) | середовище, ринок, сфера, галузь |
| безшовний (seamless) | непомітний, цілісний, без розривів; often just cut |
| надійний (robust, everywhere) | Vary by meaning: стійкий, перевірений, витривалий. NB: "робастний" in econometrics is terminology - keep it |
| потужний інструмент | Cut "потужний" or state the capability |
| цінні інсайти | корисні спостереження, важливі висновки |
| передові технології / інноваційні рішення | Name the technology |
| критично важливо | важливо; or state the consequence of failure |
| ключовий (in every second sentence) | Keep one or two, vary: головний, основний, визначальний |
| ефективний та дієвий | Pick one |
| оптимізувати (as vague improvement) | State what is reduced/increased |
| сприяти розвитку | Concretize: what grows, by what mechanism |
| покращити ефективність | підвищити ефективність; or state the metric |
| у стрімкому/динамічному середовищі | Delete |
| відкривати нові горизонти/можливості | State which ones |
| це не просто X - це Y | Usually: keep Y, drop the frame |
| від студентів до пенсіонерів (fake range "from X to Y") | Name the actual audience or cut |
| Отже, підсумовуючи вищесказане/вищезазначене | If the conclusion adds nothing, cut it; if it adds something, start with that |

## 3. Structural tells

These survive translation untouched, which makes them the strongest evidence of AI origin - and the highest-value fixes.

**Uniform rhythm.** Every sentence 20-25 words, every paragraph 3-4 sentences. Fix: break some sentences, merge others, let one paragraph be two lines and another be eight. Natural prose is uneven.

**Triads.** "швидко, якісно та ефективно"; three examples, three benefits, three risks - everywhere. Fix: cut to the one or two items that carry information; keep a triad only where three things genuinely exist.

**Bold-term-colon lists.** "**Гнучкість:** система дозволяє..." repeated five times. Fix: dissolve into prose unless the content is genuinely enumerable (steps, specs, options). If a list survives, strip the bold labels or make them real headers.

**Connective inflation.** Крім того / Більше того / Окрім цього / Також / Варто зазначити opening every second sentence. Fix: delete most - juxtaposition usually carries the logic. Vary the survivors with natural connectives: до того ж, ба більше, водночас, натомість, а втім.

**Hedge stacking.** "може, певною мірою, у деяких випадках, як правило" piled into one sentence. Fix: one hedge per claim, chosen deliberately. But NEVER delete a hedge that carries epistemic content - "може свідчити" must not become "свідчить". When in doubt, keep the hedge.

**Symmetric fake contrast.** "З одного боку... з іншого боку..." where the two sides do not actually oppose. Fix: if there is real tension, sharpen it; if not, merge into one statement.

**Paragraph bookending.** Topic sentence restated as the paragraph's last sentence. Fix: cut the restatement.

**Hollow conclusion.** Final paragraph starts with "Отже" or "Підсумовуючи" and repeats the introduction. Fix: either give the conclusion actual content (implication, recommendation, open question) or end the text where the substance ends.

**Everything-is-important inflation.** важливо зазначити / варто підкреслити / слід наголосити sprinkled throughout. Fix: at most one per text, on the sentence that earns it. If everything is emphasized, nothing is.

**Em dashes everywhere.** AI text overuses "—". Per the user's global preference, replace all "—" with "-" (and often the sentence reads better restructured without the dash at all).

**Not-only-but-also.** "не тільки X, але й Y" as a default intensifier. Fix: usually "X і Y", or just Y if X was filler.

## 4. Metadiscourse budget

AI text narrates itself: announces what it will say, says it, then announces it said it. In an edited text the budget is roughly:

- one roadmap sentence maximum (academic texts only),
- zero "as mentioned above" back-references in short texts ("як зазначалося вище" in a two-page text means the structure has failed),
- zero self-praise of the text's own thoroughness ("детальний огляд", "комплексний аналіз" about itself).

## 5. What NOT to flag as AI residue

- Genuine enumerations, steps, and specs - lists are fine when content is list-shaped.
- Repetition of a key term in academic writing - terminological consistency beats elegant variation; do not introduce synonyms for the concept under study.
- Formulaic academic scaffolding the genre requires (дані, методи, результати announcements in a paper) - genre convention is not slop.
- A hedged claim - hedges in empirical writing are usually load-bearing.
