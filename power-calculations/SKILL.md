---
name: power-calculations
description: Power, minimum detectable effect (MDE) and sample-size calculations in R for randomized experiments and survey experiments - two-arm and multi-arm designs with a shared control, ANCOVA vs change-score vs post-only, binary outcomes, within-subject differences, interactions/heterogeneity, clustered assignment, attrition and exclusions, and multiple-testing adjustment (per-test, Bonferroni bound, Holm/Romano-Wolf). Combines closed-form MDEs with Monte Carlo simulation of the exact pre-registered regression, including size checks. Use whenever the user asks for power calculations, an MDE table, "how many respondents do we need", "is N big enough", "what effect can we detect", power for a PAP or grant, or wants to check/redo an existing power analysis (including translating Stata power .do files to R).
---

# Power calculations (R)

Reusable tools live in `scripts/power_tools.R`; a fill-in-the-parameters script is
`scripts/power_template.R`; formulas, rules of thumb and worked reference numbers are in
`references/formulas.md`; `tests/test_power_tools.R` checks the tools (run it after
editing them).

Always write R (tidyverse style), run as a standalone script with `Rscript <file>`, never
inline R. Source the tools with
`source("~/.claude/skills/power-calculations/scripts/power_tools.R")` or copy them into
the project's code folder.

## Workflow

### 1. Pin down the design before computing anything

Get each of these from the user, the PAP, the survey file or a pilot. If one is missing,
ask; do not invent it:

- Arms and allocation (shared control? unequal ratios?), N randomized per arm.
- The pre-registered estimating equation for each primary hypothesis: outcome,
  baseline control or change score, other controls, SE type (HC1, clustered).
- Outcome type and scale: continuous (SD known or z-scored?), binary (base rate),
  within-subject difference, index.
- Correlation between baseline and outcome (rho), if the design uses a baseline.
- Attrition (panels: by wave) and pre-registered exclusions (attention, speeding).
- Clustering: cluster size and ICC.
- Hypothesis family for multiple testing (how many tests, which adjustment).
- alpha, sidedness, target power (default 0.05, two-sided, 0.80).
- Benchmark effect sizes from prior studies. Per the user's rules, ask the user to
  confirm any cited paper's effect, direction and year; never quote one from memory.

### 2. Analytic MDEs first

Use `mde_analytic()`, `power_analytic()`, `n_required()`, `mde_binary()`,
`mde_interaction()`. All arguments accept vectors and return one row per scenario, so
pass grids (e.g. `rho = c(0.5, 0.6, 0.7)`, `mcp = c("none", "bonferroni")`,
`exclusion = c(0, 0.1)`) rather than looping.

### 3. Simulate the estimator you will actually run

Use `simulate_power(dgp, estimator, effects, tested_terms, ...)` with a DGP
(`dgp_arms`, `dgp_within_binary`, `dgp_cluster`, or a custom function(effect, ...)) and
`est_feols(formula, vcov)` matching the PAP regression exactly. Rules:

- Include `effect = 0` in `effects` and keep untreated arms at the null: their
  rejection rates are the empirical size and must be close to alpha. If not, the SEs or
  the DGP are wrong.
- Check the simulation reproduces the analytic power in the simple case before
  trusting it in the complicated one.
- Compare `sd_estimate` with `mean_se`: they should match (SE calibration).
- Report Monte Carlo SEs; use at least 1,000 reps for final numbers (2,000 for PAPs).
- Simulation is required, not optional, for: binary outcomes near 0/1, within-subject
  designs, few clusters, multiple arms with a family-wise adjustment, non-standard
  estimators.

### 4. Multiple testing

Report two columns: per-test alpha and the Bonferroni bound (alpha / k). State that
Holm and Romano-Wolf power lie between them, closer to the per-test column when the
tested estimates are correlated. Confirm which adjustment the PAP uses before writing
it up; if the existing power script and the PAP disagree, flag it.

### 5. Report

A table with one row per hypothesis: design, N analysed per arm, assumptions (rho,
attrition, exclusions, ICC), MDE in SD units at alpha and at the Bonferroni bound, and
the MDE in natural units (pp, euros, coins, thermometer points). Then 3-5 sentences
covering:

- which assumptions drive the numbers;
- what the pilot must confirm (usually rho and the outcome SD);
- how the MDE compares with benchmark effects the user has confirmed;
- for interactions or differences in changes, the arithmetic of what underlying
  effects an MDE of that size requires.

Do not call results "good" or "bad"; state what is and is not detectable.

## Pitfalls to flag

- Power computed for a different estimator than the PAP (e.g. difference in means
  in the power script, ANCOVA in the PAP).
- Change scores used when rho < 0.5 (worse than post-only); ANCOVA dominates both.
- Controlling for a post-treatment variable (e.g. Belief 1 when testing Belief 2).
- Interactions powered as if they were main effects (they need about 4x N).
- Shared control in multi-arm designs: each comparison uses n_T + n_C, not total N;
  simulate if a family-wise adjustment covers several arms.
- Attrition and exclusions forgotten, or applied to the wrong wave.
- Binary outcomes: variance depends on the base rate; 0.5 is the conservative case.
- Clustered assignment analysed with individual SEs; few clusters need simulation
  (and possibly wild-cluster bootstrap).
- Effect sizes "aspirational" rather than benchmarked: survey treatments typically
  move attitudes by 0.1-0.2 SD.
- Correlations (rho) assumed without a pilot: show a range and say the pilot decides.

## Function reference (scripts/power_tools.R)

| Function | Purpose |
|---|---|
| `mde_analytic(n_treat, ratio, alpha, power, sd, design, rho, r2_covariates, n_tests, mcp, sides, attrition, exclusion, cluster_size, icc)` | MDE grid |
| `power_analytic(effect, n_treat, ...)` | Power for given effect |
| `n_required(mde, ...)` | Units to recruit per arm (inflated for attrition/exclusion) |
| `power_binary(p0, p1, n_treat, ...)`, `mde_binary(p0, n_treat, ..., direction)` | Binary outcomes |
| `mde_interaction(n_cells, ...)` | 2x2 / moderator interactions |
| `dgp_arms(effect, n_per_arm, arms, effect_on, sd, rho, outcome, p0)` | Multi-arm DGP with baseline y0, outcome y, change |
| `dgp_within_binary(effect, n_per_arm, arms, effect_on, p, rho)` | Correlated binary pair, y = z_high - z_low |
| `dgp_cluster(effect, n_clusters_per_arm, cluster_size, icc, sd)` | Cluster-randomized DGP |
| `est_feols(formula, vcov = "hetero")` | Estimator wrapper (HC1 default; `vcov = ~cluster` for clusters) |
| `simulate_power(dgp, estimator, effects, tested_terms, reps, alpha, mcp, seed, parallel, ...)` | Monte Carlo power, size, bias, SE calibration |
| `mde_from_sim(sim, term, target)` | Interpolated MDE from a simulated power curve |

Arm dummies are named `d_<arm>` (e.g. `d_treat`); the DGP also returns `y0` and
`change` for continuous outcomes. Set `parallel = TRUE` after `future::plan(multisession)`
for long runs.
