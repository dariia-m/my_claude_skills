# Survey Experiment Diagnostic Checklist

This is the full diagnostic checklist. Read this before producing any evaluation. Not every item applies to every design - use judgment. Items marked with * are especially common failure points in economics survey experiments.

---

## 1. Research Question & Identification

- [ ] Is the causal estimand clearly stated? (e.g., "the effect of X on Y" not "the relationship between X and Y")
- [ ] Is the theoretical mechanism specified? Can you trace the causal chain from treatment to outcome?
- [ ] Is the experiment testing a theory or just measuring an empirical regularity?
- [ ] *Are there alternative mechanisms that could explain the same treatment-outcome pattern? (If yes, does the design distinguish between them?)
- [ ] Is this question answerable with a survey experiment, or does it fundamentally require behavioral/revealed-preference data?
- [ ] Is the question policy-relevant or theoretically novel enough to justify the study?
- [ ] Does the literature review establish a clear gap? Is it clear what this experiment adds beyond existing evidence?

## 2. Treatment Design

### Treatment content
- [ ] *Is the treatment strong enough to plausibly shift the outcome? (The "would this actually change my mind?" test)
- [ ] *Is the treatment short enough that respondents will actually process it? (For text treatments: under ~150 words is ideal; over 300 is risky)
- [ ] Is the treatment realistic/naturalistic? Would respondents encounter something like this outside the lab?
- [ ] *If using an informational treatment: does the control group already know this information? (Pre-treatment beliefs/knowledge should be measured or assumed with evidence)
- [ ] If using vignettes: are they concrete and vivid, or abstract and forgettable?
- [ ] Are treatment materials professionally produced? (Sloppy formatting signals "this is fake" to respondents)

### Treatment arms
- [ ] *Is the control condition well-defined? (Pure control vs. placebo vs. active control - each has different implications)
- [ ] If multiple treatment arms: is each arm testing a distinct theoretical prediction, or are they minor variants?
- [ ] Is there a "dose-response" logic across arms, or are they testing orthogonal mechanisms?
- [ ] *Can respondents guess which arm they're in? (If yes, demand effects are likely)
- [ ] Is there a risk of differential attrition across arms? (e.g., one treatment is boring/offensive and the other isn't)
- [ ] For factorial designs: is the interaction effect theoretically motivated, or just exploratory?
- [ ] Are the number of arms consistent with the available sample size? (k arms requires roughly k^2 times the sample of a 2-arm study for the same power on pairwise comparisons)

### Demand effects
- [ ] *Could respondents infer the hypothesis? (Read the survey from the respondent's perspective - is it obvious what the "right" answer is?)
- [ ] *Is there a within-subject component that makes the treatment transparent? (Before/after measurements on the same construct create strong demand)
- [ ] Are there design features to mitigate demand effects? (e.g., unrelated filler tasks, implicit measures, behavioral outcomes, time delay between treatment and outcome)
- [ ] Is there an experimenter demand check? ("What do you think this study was about?")

## 3. Outcome Measures

### Primary outcome
- [ ] *Is there a single pre-specified primary outcome, or will the researcher choose among many? (If many, is there an index?)
- [ ] Does the primary outcome measure what the theory says should change?
- [ ] *Is the outcome measured on a scale with enough variation? (Binary agree/disagree is usually underpowered compared to Likert or slider scales)
- [ ] *Are there ceiling or floor effects? (If the baseline is already very high/low, there's no room to move)
- [ ] Is the outcome susceptible to social desirability bias? (Especially for sensitive topics: immigration, race, redistribution)
- [ ] For attitudinal outcomes: is the measure validated, or was it constructed for this study?
- [ ] Is there a behavioral or incentivized outcome? (Even one - e.g., a real donation, a petition signature - greatly strengthens credibility)

### Secondary outcomes
- [ ] Are secondary outcomes clearly labeled as secondary?
- [ ] Is there a risk of p-hacking across many secondary outcomes?
- [ ] If there are many outcomes: is there a pre-specified plan for multiple hypothesis testing correction? (e.g., Bonferroni, Benjamini-Hochberg, Romano-Wolf, Anderson index)
- [ ] Do the secondary outcomes illuminate the mechanism, or are they just "we might as well ask"?

### Measurement quality
- [ ] Are survey items clear and unambiguous? (Pilot-test any novel items)
- [ ] *Is question order potentially biasing responses? (Asking about the treated topic before measuring the outcome can prime respondents)
- [ ] Are response scales balanced and labeled clearly?
- [ ] For Likert scales: is there a midpoint? (Dropping the midpoint forces a direction but may frustrate respondents; including it creates a pile-up)
- [ ] Is reverse-coding used for any items in indices? (Important for catching inattentive respondents)

## 4. Randomization & Assignment

- [ ] Unit of randomization: individual, household, classroom, village, etc.? Is this the right level for the question?
- [ ] *If cluster-randomized: how many clusters? (Fewer than 20-30 clusters per arm is generally insufficient without special methods)
- [ ] Is randomization stratified? On what variables? Are the strata variables prognostic of the outcome?
- [ ] Is block randomization used to ensure balance within strata?
- [ ] *SUTVA: can treated individuals influence control individuals? (Spillover is especially likely in classroom or community settings)
- [ ] Is compliance perfect (as in most survey experiments) or is there noncompliance? If noncompliance, is there an IV/LATE framework?
- [ ] Is randomization implemented in the survey platform (e.g., Qualtrics randomizer) or externally? Is the implementation documented and reproducible?
- [ ] Is there a randomization seed set for reproducibility?

## 5. Statistical Power

- [ ] *What is the assumed effect size, and where does the assumption come from? (Prior studies? Pilots? Wishful thinking?)
- [ ] Is the MDE (minimum detectable effect) meaningful? (Being powered to detect 0.05 SD is meaningless if the theoretically interesting effect is 0.2 SD)
- [ ] *Is the power calculation based on the correct test? (Two-sided vs. one-sided; t-test vs. regression; clustered vs. individual)
- [ ] If clustered: is the ICC accounted for?
- [ ] What's the assumed attrition/exclusion rate? Is the recruited N large enough to absorb it?
- [ ] For multiple arms: is power calculated for each pairwise comparison that will be tested, or just for treatment vs. control?
- [ ] If testing heterogeneous effects: is there power for subgroup analyses, or are they purely exploratory?
- [ ] Sensitivity analysis: what happens to power if the effect is half the assumed size?
- [ ] Are there pilot data to calibrate effect size expectations?

## 6. Survey Instrument Quality

- [ ] *Are there attention checks? (At least one, ideally two - one early, one late)
- [ ] What's the plan for failed attention checks? Pre-specified exclusion rule?
- [ ] *Is there a manipulation check confirming the treatment was received/understood?
- [ ] Is there a comprehension check for complex treatments? (Especially important for economic or policy information)
- [ ] Is survey length reasonable? (Under 15 minutes for online panels; under 10 is better. Every additional minute loses respondents)
- [ ] Is there a progress bar? (Mixed evidence, but respondents generally want to know how long is left)
- [ ] Are there open-ended questions? (Good for qualitative insight but require coding plans)
- [ ] Is the survey mobile-friendly? (A large share of online panel respondents use phones)
- [ ] Is the survey available in the respondents' language? Translation quality checked?
- [ ] Are there skip patterns or branching logic? If so, is the implementation verified?

## 7. Sample & External Validity

- [ ] *Is the sample appropriate for the research question? (MTurk for studying "Americans" is a stretch; Prolific with demographic quotas is better)
- [ ] Are there demographic quotas? On what variables?
- [ ] Is the sampling frame clearly described?
- [ ] *Are there obvious selection-into-the-study concerns? (People who agree to take surveys about politics are not a random sample of the population)
- [ ] For online panels: which platform? What are the known biases of that platform's population?
- [ ] For field surveys: what's the response rate? Is there attrition documentation?
- [ ] Is the target population for generalization explicitly stated?
- [ ] If the sample is from one country: is the question country-specific, or is the researcher making universal claims?

## 8. Pre-registration & Analysis Plan

- [ ] *Is the study pre-registered? Where? (AEA Registry, EGAP, OSF, AsPredicted)
- [ ] *Is the pre-registration detailed enough to actually constrain the analysis? (A one-paragraph PAP that says "we will test the effect of X on Y using OLS" is barely better than nothing)
- [ ] Are primary hypotheses clearly stated with predicted directions?
- [ ] Is the estimating equation written out?
- [ ] Are covariates pre-specified? (Including which ones and why)
- [ ] Is the plan for handling attrition pre-specified? (Bounds? Lee bounds? Inverse probability weighting?)
- [ ] Are subgroup analyses pre-specified with theoretical justification?
- [ ] Is there a clear line between confirmatory and exploratory analysis?
- [ ] Is the multiple testing correction procedure specified?
- [ ] What's the plan for null results? (Is the study designed so that a null is also informative?)

## 9. Ethics

- [ ] Has IRB/ethics approval been obtained or planned?
- [ ] Is there deception? If so, is it justified and is there a debriefing protocol?
- [ ] Is informed consent adequate? Does it reveal enough without spoiling the treatment?
- [ ] *Are there vulnerable populations? (Refugees, children, patients - require additional safeguards)
- [ ] Could participation cause harm? (Emotional distress from sensitive topics, privacy risks)
- [ ] Is data anonymization planned? How will PII be handled?
- [ ] For treatments involving misinformation: is there a debriefing/correction at the end?
- [ ] Is compensation fair and non-coercive? (Not so high that people who shouldn't participate are drawn in)
- [ ] For international research: are local ethical norms and regulations considered?

## 10. Implementation & Logistics

- [ ] Is there a pilot/soft launch planned before the full rollout?
- [ ] What's the recruitment timeline? Is there time pressure that could compromise quality?
- [ ] Are there quality control procedures during data collection? (Real-time monitoring of completion rates, speeders, response patterns)
- [ ] What's the plan for speeders? (Pre-specified minimum completion time)
- [ ] What's the plan for duplicates? (Especially on MTurk/Prolific)
- [ ] Is there a data management plan? Where will raw data be stored?
- [ ] Is the analysis code/pipeline planned in advance? (Pre-coded analysis scripts are the gold standard)
- [ ] If multiple waves or sessions: how will attrition between waves be handled?
- [ ] Budget: is funding secured? Is the per-respondent compensation realistic for the survey length?
- [ ] Is there a backup plan if recruitment is slower than expected?

---

## Quick Reference: Common Red Flags

These patterns should immediately raise flags in your evaluation:

1. **"We'll recruit 200 people per arm"** with no power justification - almost certainly underpowered for attitude effects
2. **Within-subject treatment/measurement on the same construct** - screams demand effects
3. **Ten outcome variables and no index or correction** - fishing expedition
4. **"Our treatment is a two-page article about..."** - nobody will read it
5. **No manipulation check** - you don't know if the treatment worked
6. **No attention check** - you don't know if respondents were paying attention
7. **"We will control for post-treatment variables"** - collider bias / bad controls
8. **"We will pre-register on OSF"** with no PAP details - performative pre-registration
9. **MTurk sample for a study about "the general public"** - external validity problem
10. **Asking sensitive questions right after the treatment** - social desirability + demand effects compounded
11. **Factorial design with 2x2x2 = 8 cells and N=800** - 100 per cell is almost never enough
12. **"We will look at heterogeneous effects by gender, age, income, education, and party"** - exploratory subgroups without power
13. **No pilot data and "we expect a 0.3 SD effect"** - based on what?
14. **Cluster randomization with 10 clusters** - insufficient degrees of freedom
15. **"We will also use machine learning to identify treatment effect heterogeneity"** - without pre-registration this is pure exploration
