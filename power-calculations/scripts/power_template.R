# =============================================================================
# power_<project>.R   (template from the power-calculations skill)
#
# Copy into the project's code folder, rename, fill in the PARAMETERS block and
# run standalone:  Rscript power_<project>.R
#
# Produces:
#   output/tables/power_mde.csv     analytic MDE table (per-test and Bonferroni)
#   output/tables/power_sim.csv     simulated power / size for the PAP estimator
#   output/figures/power_curve.pdf  simulated power curve
#
# Methodology:
#   1. Analytic MDEs (normal approximation) for each primary hypothesis, under
#      the pre-registered design (post-only, ANCOVA or change score), with the
#      per-test column and the Bonferroni bound. Holm / Romano-Wolf power lies
#      between the two columns.
#   2. Monte Carlo simulation of the exact pre-registered regression (same
#      controls, same SEs), including effect = 0 so the size can be checked and
#      untreated arms held at the null.
#   3. The simulated and analytic numbers must agree in the simple case; if
#      they do not, the DGP or the formula inputs are wrong.
# =============================================================================

library(tidyverse)
library(here)
source("~/.claude/skills/power-calculations/scripts/power_tools.R")  # adjust path if copied

# ------------------------------- PARAMETERS ---------------------------------
# Every number below must come from the user, a pilot, or a cited source the
# user has confirmed. Do not fill in guesses silently.
arms        <- c("control", "treat")  # first element = control
n_per_arm   <- 450                    # randomized per arm (before attrition)
attrition   <- 0.00                   # share lost before the outcome is measured
exclusion   <- 0.10                   # share expected to fail pre-registered exclusions
alpha       <- 0.05
target_pow  <- 0.80
n_tests     <- 3                      # size of the primary hypothesis family
design      <- "ancova"               # "post", "ancova" or "change"
rho_grid    <- c(0.5, 0.6, 0.7)       # cor(baseline, outcome); confirm with pilot
effects_sim <- c(0, 0.05, 0.10, 0.15, 0.20, 0.25)  # in SD units; keep 0
reps        <- 1000
set.seed(20261116)
# ----------------------------------------------------------------------------

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)

# --- 1. Analytic MDE table -----------------------------------------------------
mde_tab <- mde_analytic(
  n_treat = n_per_arm, alpha = alpha, power = target_pow,
  design = c("post", design), rho = rho_grid,
  n_tests = n_tests, mcp = c("none", "bonferroni"),
  exclusion = c(0, exclusion), attrition = attrition
) |>
  filter(!(design == "post" & rho != rho_grid[1])) |>   # rho irrelevant for post
  mutate(rho = if_else(design == "post", NA_real_, rho)) |>
  distinct() |>
  select(design, rho, mcp, exclusion, n_t_eff, mde_sd) |>
  mutate(mde_sd = round(mde_sd, 3)) |>
  pivot_wider(names_from = mcp, values_from = mde_sd,
              names_prefix = "mde_sd_") |>
  arrange(design, rho, exclusion)

print(mde_tab, n = Inf)
write_csv(mde_tab, here("output", "tables", "power_mde.csv"))

# --- 2. Simulation of the pre-registered estimator ----------------------------
# Example: ANCOVA, y on treatment dummy and baseline, HC1 SEs. Replace the
# formula with the exact PAP specification (add pre-registered controls by
# extending the DGP if they matter for the residual variance).
dummies <- paste0("d_", arms[-1])
fml <- as.formula(paste("y ~", paste(dummies, collapse = " + "),
                        if (design == "ancova") "+ y0" else ""))
outcome_var <- if (design == "change") "change" else "y"
if (design == "change") fml <- update(fml, change ~ .)

sim <- map(rho_grid, \(r)
  simulate_power(
    dgp = dgp_arms, estimator = est_feols(fml),
    effects = effects_sim, tested_terms = dummies, reps = reps,
    alpha = alpha, mcp = "none",
    n_per_arm = round(n_per_arm * (1 - attrition) * (1 - exclusion)),
    arms = arms, effect_on = arms[2], rho = r) |>
    mutate(rho = r)
) |> list_rbind()

print(sim, n = Inf)
write_csv(sim, here("output", "tables", "power_sim.csv"))

# Size check: at effect = 0 the rejection rate should be within ~2 MC SEs of alpha
size_check <- sim |> filter(effect == 0) |>
  mutate(ok = abs(rejection_rate - alpha) < 2 * sqrt(alpha * (1 - alpha) / reps))
if (!all(size_check$ok)) warning("Simulated size deviates from alpha: check the DGP/SEs")

# Simulated MDE per rho (interpolated), next to the analytic one
sim |>
  group_by(rho) |>
  summarise(mde_sim = mde_from_sim(pick(everything()), term = dummies[1],
                                   target = target_pow)) |>
  print()

# --- 3. Power curve ------------------------------------------------------------
p <- sim |>
  filter(term == dummies[1]) |>
  ggplot(aes(effect, rejection_rate, colour = factor(rho))) +
  geom_hline(yintercept = target_pow, linetype = "dashed") +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = rejection_rate - 1.96 * mc_se,
                    ymax = rejection_rate + 1.96 * mc_se), width = 0.005) +
  labs(x = "Effect (SD units)", y = "Power", colour = "rho") +
  theme_minimal()
ggsave(here("output", "figures", "power_curve.pdf"), p, width = 6, height = 4)
