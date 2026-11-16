# =============================================================================
# test_power_tools.R
# Run: Rscript test_power_tools.R   (from this folder or with a full path)
#
# Checks the analytic formulas against power numbers documented for real
# survey-experiment designs (see references/formulas.md) and checks that the
# simulations agree with the formulas and hold their nominal size.
# =============================================================================

args <- commandArgs(trailingOnly = FALSE)
here_dir <- dirname(normalizePath(sub("^--file=", "", args[grep("^--file=", args)])))
source(file.path(here_dir, "..", "scripts", "power_tools.R"))

ok <- function(cond, msg) {
  cat(if (isTRUE(cond)) "PASS " else "FAIL ", msg, "\n", sep = "")
  if (!isTRUE(cond)) assign(".failed", TRUE, envir = globalenv())
}
.failed <- FALSE

# --- 1. Two-arm post-only: 375 per arm (4-arm RCT, 375 per arm) ----------------
# An independent Stata simulation gave power 0.781 at 0.20 SD, so the
# analytic MDE at 80% must be just above 0.20 SD.
m1 <- mde_analytic(n_treat = 375)
ok(abs(m1$mde_sd - 0.2046) < 0.001, sprintf("MDE 375/arm post = %.4f (expect 0.2046)", m1$mde_sd))
p1 <- power_analytic(effect = 0.20, n_treat = 375)
ok(abs(p1$power - 0.781) < 0.02, sprintf("power 0.20 SD at 375/arm = %.3f (Stata sim 0.781)", p1$power))

# --- 2. Two-arm design with a baseline (450 vs 450) -------------------------
# Documented: ANCOVA (rho 0.6-0.7) MDE 0.13-0.15; Bonferroni (alpha/3) 0.15-0.17
#             change scores (rho 0.7-0.8) MDE 0.12-0.15; Bonferroni 0.14-0.17
anc <- mde_analytic(n_treat = 450, design = "ancova", rho = c(0.6, 0.7),
                    n_tests = 3, mcp = c("none", "bonferroni"))
chg <- mde_analytic(n_treat = 450, design = "change", rho = c(0.7, 0.8),
                    n_tests = 3, mcp = c("none", "bonferroni"))
print(bind_rows(anc, chg) |> select(design, rho, mcp, mde_sd) |>
        mutate(mde_sd = round(mde_sd, 3)))
r <- \(x) round(x, 2)
ok(all(r(anc$mde_sd[anc$mcp == "none"]) %in% c(0.15, 0.13)), "ANCOVA per-test MDE in 0.13-0.15")
ok(all(r(anc$mde_sd[anc$mcp == "bonferroni"]) %in% c(0.17, 0.15)), "ANCOVA Bonferroni MDE in 0.15-0.17")
ok(all(r(chg$mde_sd[chg$mcp == "none"]) %in% c(0.14, 0.12)), "change per-test MDE in 0.12-0.15")
ok(all(r(chg$mde_sd[chg$mcp == "bonferroni"]) %in% c(0.17, 0.14)), "change Bonferroni MDE in 0.14-0.17")

# --- 3. n_required inverts mde_analytic ---------------------------------------
nr <- n_required(mde = m1$mde_sd)
ok(abs(nr$n_treat - 375) <= 1, sprintf("n_required round trip = %d (expect 375)", nr$n_treat))
nr_att <- n_required(mde = m1$mde_sd, attrition = 0.2)
ok(abs(nr_att$n_treat - 375 / 0.8) <= 1, "n_required inflates for 20% attrition")

# --- 4. Binary outcome: base rate 76% ------------------------------------------
b <- mde_binary(p0 = 0.76, n_treat = 375)
ok(b$p1 > 0.76 && b$p1 < 0.86, sprintf("binary MDE from 76%% at 375/arm: p1 = %.3f (%.1f pp)", b$p1, b$mde_pp))
pb <- power_binary(p0 = 0.76, p1 = b$p1, n_treat = 375)
ok(abs(pb$power - 0.80) < 1e-4, "power_binary at mde_binary p1 = 0.80")

# --- 5. Interaction SE is twice the pooled main-effect SE in a balanced 2x2 --
ia <- mde_interaction(n_cells = rep(225, 4))
me <- mde_analytic(n_treat = 450)
ok(abs(ia$se / me$se - 2) < 1e-9, "balanced 2x2 interaction SE = 2 x main-effect SE")

# --- 6. Simulation agrees with the formula and holds size ---------------------
sim <- simulate_power(
  dgp = dgp_arms, estimator = est_feols(y ~ d_T1 + d_T2 + d_T3),
  effects = c(0, 0.20), tested_terms = c("d_T1", "d_T2", "d_T3"),
  reps = 600, n_per_arm = 375, arms = c("control", "T1", "T2", "T3"),
  effect_on = "T1")
print(sim)
pow_sim <- sim |> filter(effect == 0.20, term == "d_T1") |> pull(rejection_rate)
size_sim <- sim |> filter(effect == 0.20, term != "d_T1") |> pull(rejection_rate)
ok(abs(pow_sim - p1$power) < 3 * sqrt(0.25 / 600), sprintf("sim power %.3f vs analytic %.3f", pow_sim, p1$power))
ok(all(abs(size_sim - 0.05) < 3 * sqrt(0.05 * 0.95 / 600)), "null arms reject at about 5%")

# ANCOVA simulation vs formula
sim_a <- simulate_power(
  dgp = dgp_arms, estimator = est_feols(y ~ d_treat + y0),
  effects = 0.14, tested_terms = "d_treat", reps = 600,
  n_per_arm = 450, rho = 0.7)
pa <- power_analytic(effect = 0.14, n_treat = 450, design = "ancova", rho = 0.7)
ok(abs(sim_a$rejection_rate - pa$power) < 3 * sqrt(0.25 / 600),
   sprintf("ANCOVA sim power %.3f vs analytic %.3f", sim_a$rejection_rate, pa$power))

# Within-subject binary difference (two correlated choices, rho = 0.3)
sim_w <- simulate_power(
  dgp = dgp_within_binary, estimator = est_feols(y ~ d_treat),
  effects = 0.10, tested_terms = "d_treat", reps = 600,
  n_per_arm = 375, p = 0.5, rho = 0.3)
sd_D <- sqrt(2 * 0.25 * (1 - 0.3))
pw <- power_analytic(effect = 0.10, n_treat = 375, sd = sd_D)
ok(abs(sim_w$rejection_rate - pw$power) < 3 * sqrt(0.25 / 600),
   sprintf("within-binary sim power %.3f vs normal approx %.3f", sim_w$rejection_rate, pw$power))

# Cluster design: simulated power vs design-effect formula
sim_c <- simulate_power(
  dgp = dgp_cluster, estimator = est_feols(y ~ d_treat, vcov = ~cluster),
  effects = 0.25, tested_terms = "d_treat", reps = 400,
  n_clusters_per_arm = 30, cluster_size = 20, icc = 0.05)
pc <- power_analytic(effect = 0.25, n_treat = 600, cluster_size = 20, icc = 0.05)
ok(abs(sim_c$rejection_rate - pc$power) < 0.08,
   sprintf("cluster sim power %.3f vs design-effect formula %.3f", sim_c$rejection_rate, pc$power))

cat(if (.failed) "\nSOME TESTS FAILED\n" else "\nALL TESTS PASSED\n")
quit(status = if (.failed) 1 else 0)
