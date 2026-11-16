# Power formulas and worked numbers

All formulas are normal approximations for a two-sided test of a treatment-control
difference. `z_a = qnorm(1 - alpha/2)` (or `1 - alpha/(2k)` under Bonferroni with k
tests), `z_b = qnorm(power)`.

## Core

    MDE = (z_a + z_b) * SE
    SE  = sigma * f * sqrt(1/n_T + 1/n_C) * sqrt(DEFF)

| Piece | Formula | Notes |
|---|---|---|
| Design factor f, post-only | 1 | |
| f, ANCOVA (control for baseline y0) | sqrt(1 - rho^2) | rho = cor(y0, y1). Always at least as good as change scores |
| f, change score (y1 - y0) | sqrt(2 (1 - rho)) | Beats post-only only if rho > 0.5 |
| Extra covariates | multiply f by sqrt(1 - R^2) | R^2 of the residual explained by other pre-treatment covariates |
| Clustering | DEFF = 1 + (m - 1) * ICC | m = cluster size; cluster SEs in the estimator |
| Attrition / exclusions | n_eff = n * (1 - attrition) * (1 - exclusion) | 10% exclusions raise the MDE by about 5% |
| Unequal allocation | n_C = ratio * n_T | Fixed N: power is maximized at ratio 1 unless costs differ |
| Required N per arm | n_T = ((z_a + z_b) * sigma * f / MDE)^2 * DEFF * (1 + 1/ratio) | Divide by (1 - attrition)(1 - exclusion) to get recruitment |

Rule of thumb at alpha = 0.05, power = 0.80: z_a + z_b = 2.80. With equal arms of n,
MDE = 2.80 * sigma * f * sqrt(2/n). Halving the MDE needs 4x the sample.

## Binary outcomes

    SE = sqrt(p0 (1 - p0) / n_C + p1 (1 - p1) / n_T)

Solve for p1 numerically (`mde_binary`). Variance peaks at p = 0.5, so a base rate of
0.5 is the conservative case when the base rate is unknown.

## Within-subject binary difference

D = z_high - z_low with z ~ Bernoulli(p) and cor(z_high, z_low) = rho:

    Var(D) = 2 p (1 - p) (1 - rho)        (= 0.5 (1 - rho) at p = 0.5)

Use sigma = sqrt(Var(D)) in the core formula, or simulate exactly with
`dgp_within_binary`.

## Interactions and differences in effects

    SE_interaction = sigma * f * sqrt(1/n_00 + 1/n_01 + 1/n_10 + 1/n_11)

In a balanced 2x2 this is twice the SE of a main effect pooling all cells: the same
effect size needs about 4x the sample. For "does the treatment reduce the fall after
a second shock" (a difference in changes), an interaction of 0.15 SD needs, e.g., the
shock to move the outcome by 0.3 SD in control and the treatment to offset half of it.
State this arithmetic in the PAP; it disciplines what "plausible" means.

## Multiple testing

- Per-test column: alpha.
- Bonferroni bound: alpha / k. Conservative.
- Holm and Romano-Wolf step-down: power between the two columns; Romano-Wolf gains
  most when the tested estimates are correlated (e.g. two outcomes built from the
  same giving decisions). Report both columns and say the true MDE lies between.
- Exact Romano-Wolf power requires a bootstrap inside every simulation replication;
  only do this if the user asks and accepts the run time.

## Worked numbers (from real survey-experiment designs; used as unit tests)

| Design | Inputs | MDE (SD) |
|---|---|---|
| 4-arm RCT, each arm vs control | 375 per arm, post-only, alpha 0.05, power 0.80 | 0.205 (an independent Stata simulation gave power 0.781 at 0.20) |
| Two-arm, endline outcome controlling for baseline | 450 vs 450, ANCOVA, rho 0.6 / 0.7 | 0.149 / 0.133; Bonferroni (k = 3) 0.173 / 0.154 |
| Two-arm, change scores | 450 vs 450, change, rho 0.7 / 0.8 | 0.145 / 0.118; Bonferroni 0.167 / 0.136 |
| Binary outcome, base rate 76% | 375 per arm | +8.1 pp (to 84.1%) |
| Within-subject gap between two binary choices | 375 per arm, p = 0.5, rho = 0.3 | sigma_D = 0.59; power about 0.64 at a 10 pp shift |
