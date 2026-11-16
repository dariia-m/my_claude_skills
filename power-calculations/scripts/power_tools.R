# =============================================================================
# power_tools.R
#
# Power and minimum detectable effect (MDE) tools for randomized experiments:
#   * analytic MDE / power / required N for two-arm comparisons, with
#     post-only, ANCOVA (baseline control) and change-score designs,
#     covariate R^2, attrition, exclusions, clustering and multiple testing;
#   * MDE for binary outcomes (unpooled normal approximation);
#   * MDE for interactions (2x2 factorial or heterogeneity by a moderator);
#   * Monte Carlo power for the estimator you will actually pre-register,
#     with data-generating processes (DGPs) for multi-arm, ANCOVA, binary,
#     within-subject binary differences and cluster-randomized designs.
#
# Usage: source("power_tools.R") from a standalone script run with Rscript.
# Conventions: effects are in outcome units; with sd = 1 they are in SD units.
#              Two-sided tests unless `sides = 1`.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
})

# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

# Critical value. With mcp = "bonferroni" the per-test size is alpha / n_tests,
# which gives the conservative bound. Holm and Romano-Wolf have power between
# the per-test ("none") and Bonferroni columns, so report both columns.
.crit <- function(alpha, n_tests, mcp, sides) {
  a <- ifelse(mcp == "bonferroni", alpha / n_tests, alpha)
  qnorm(1 - a / sides)
}

# Residual-SD factor relative to the raw outcome SD.
#   post   : y1 only                               -> 1
#   ancova : y1 on treatment + y0 (rho = cor(y0,y1)) -> sqrt(1 - rho^2)
#   change : (y1 - y0) on treatment                 -> sqrt(2 * (1 - rho))
# ANCOVA is never worse than change scores; change scores beat post-only only
# when rho > 0.5 (McKenzie 2012 logic). r2_covariates is the share of the
# remaining residual variance explained by other pre-treatment covariates.
.design_factor <- function(design, rho, r2_covariates) {
  f <- dplyr::case_when(
    design == "post"   ~ 1,
    design == "ancova" ~ sqrt(1 - rho^2),
    design == "change" ~ sqrt(2 * (1 - rho)),
    TRUE ~ NA_real_
  )
  if (any(is.na(f))) stop("design must be 'post', 'ancova' or 'change'")
  f * sqrt(1 - r2_covariates)
}

# Standard error of the treatment-control difference for each row of a grid.
# Attrition and exclusions shrink the analysed sample; clustering inflates the
# variance by the design effect 1 + (m - 1) * icc.
.se_grid <- function(g) {
  g |>
    mutate(
      n_t_eff = n_treat * (1 - attrition) * (1 - exclusion),
      n_c_eff = n_t_eff * ratio,
      deff    = 1 + (cluster_size - 1) * icc,
      factor  = .design_factor(design, rho, r2_covariates),
      se      = sd * factor * sqrt(1 / n_t_eff + 1 / n_c_eff) * sqrt(deff),
      crit    = .crit(alpha, n_tests, mcp, sides)
    )
}

.make_grid <- function(...) {
  # expand_grid over every argument (auto-named from the argument symbols),
  # so any input can be a vector of scenarios
  tidyr::expand_grid(!!!rlang::dots_list(..., .named = TRUE))
}

# -----------------------------------------------------------------------------
# Analytic MDE, power and sample size (continuous outcomes, two groups)
# -----------------------------------------------------------------------------

#' Minimum detectable effect for a treatment-control comparison.
#'
#' Every argument may be a vector; the result has one row per combination.
#' n_treat   : randomized units in the treatment arm (before attrition)
#' ratio     : n_control / n_treat (1 = equal arms; in a multi-arm design with
#'             a shared control, use the control size of that comparison)
#' design    : "post", "ancova" or "change" (see .design_factor)
#' rho       : correlation between baseline and endline outcome
#' n_tests   : number of tests in the family; mcp = "bonferroni" uses alpha/n_tests
#' Returns MDE in outcome units (mde) and in SD units (mde_sd).
mde_analytic <- function(n_treat, ratio = 1, alpha = 0.05, power = 0.80, sd = 1,
                         design = "post", rho = 0, r2_covariates = 0,
                         n_tests = 1, mcp = "none", sides = 2,
                         attrition = 0, exclusion = 0,
                         cluster_size = 1, icc = 0) {
  .make_grid(n_treat, ratio, alpha, power, sd, design, rho, r2_covariates,
             n_tests, mcp, sides, attrition, exclusion, cluster_size, icc) |>
    .se_grid() |>
    mutate(mde = (crit + qnorm(power)) * se,
           mde_sd = mde / sd) |>
    select(-crit)
}

#' Power to detect a given effect (outcome units). Two-sided power includes the
#' (negligible) probability of rejecting in the wrong direction.
power_analytic <- function(effect, n_treat, ratio = 1, alpha = 0.05, sd = 1,
                           design = "post", rho = 0, r2_covariates = 0,
                           n_tests = 1, mcp = "none", sides = 2,
                           attrition = 0, exclusion = 0,
                           cluster_size = 1, icc = 0) {
  .make_grid(effect, n_treat, ratio, alpha, sd, design, rho, r2_covariates,
             n_tests, mcp, sides, attrition, exclusion, cluster_size, icc) |>
    .se_grid() |>
    mutate(power = pnorm(effect / se - crit) +
             ifelse(sides == 2, pnorm(-effect / se - crit), 0)) |>
    select(-crit)
}

#' Randomized units needed in the treatment arm to reach `power` for effect `mde`.
#' Inflates for attrition/exclusions so the answer is the number to RECRUIT.
n_required <- function(mde, ratio = 1, alpha = 0.05, power = 0.80, sd = 1,
                       design = "post", rho = 0, r2_covariates = 0,
                       n_tests = 1, mcp = "none", sides = 2,
                       attrition = 0, exclusion = 0,
                       cluster_size = 1, icc = 0) {
  .make_grid(mde, ratio, alpha, power, sd, design, rho, r2_covariates,
             n_tests, mcp, sides, attrition, exclusion, cluster_size, icc) |>
    mutate(
      deff   = 1 + (cluster_size - 1) * icc,
      factor = .design_factor(design, rho, r2_covariates),
      crit   = .crit(alpha, n_tests, mcp, sides),
      # Var(diff) = s^2 (1/n_t + 1/(ratio n_t)) = s^2 (1 + 1/ratio) / n_t
      n_treat_analysed = ((crit + qnorm(power)) * sd * factor / mde)^2 *
        deff * (1 + 1 / ratio),
      n_treat   = ceiling(n_treat_analysed / ((1 - attrition) * (1 - exclusion))),
      n_control = ceiling(n_treat * ratio),
      n_total   = n_treat + n_control
    ) |>
    select(-crit)
}

# -----------------------------------------------------------------------------
# Binary outcomes
# -----------------------------------------------------------------------------

#' Power for a difference in proportions p0 -> p1 (unpooled normal
#' approximation; matches an LPM with HC1 SEs asymptotically).
power_binary <- function(p0, p1, n_treat, ratio = 1, alpha = 0.05,
                         n_tests = 1, mcp = "none", sides = 2,
                         attrition = 0, exclusion = 0) {
  .make_grid(p0, p1, n_treat, ratio, alpha, n_tests, mcp, sides,
             attrition, exclusion) |>
    mutate(
      n_t_eff = n_treat * (1 - attrition) * (1 - exclusion),
      n_c_eff = n_t_eff * ratio,
      se      = sqrt(p0 * (1 - p0) / n_c_eff + p1 * (1 - p1) / n_t_eff),
      crit    = .crit(alpha, n_tests, mcp, sides),
      power   = pnorm(abs(p1 - p0) / se - crit) +
        ifelse(sides == 2, pnorm(-abs(p1 - p0) / se - crit), 0)
    ) |>
    select(-crit)
}

#' Smallest increase (direction = "up") or decrease ("down") from base rate p0
#' detectable with the given power. Returns p1 and the MDE in percentage points.
mde_binary <- function(p0, n_treat, ratio = 1, alpha = 0.05, power = 0.80,
                       n_tests = 1, mcp = "none", sides = 2,
                       attrition = 0, exclusion = 0, direction = "up") {
  .make_grid(p0, n_treat, ratio, alpha, power, n_tests, mcp, sides,
             attrition, exclusion, direction) |>
    mutate(p1 = pmap_dbl(
      list(p0, n_treat, ratio, alpha, power, n_tests, mcp, sides,
           attrition, exclusion, direction),
      function(p0, n_treat, ratio, alpha, power, n_tests, mcp, sides,
               attrition, exclusion, direction) {
        upper <- if (direction == "up") 1 - 1e-9 else p0 - 1e-9
        lower <- if (direction == "up") p0 + 1e-9 else 1e-9
        f <- function(p1) {
          power_binary(p0, p1, n_treat, ratio, alpha, n_tests, mcp, sides,
                       attrition, exclusion)$power - power
        }
        if (sign(f(lower)) == sign(f(upper))) return(NA_real_)  # not reachable
        uniroot(f, c(lower, upper), tol = 1e-8)$root
      }),
      mde_pp = 100 * abs(p1 - p0))
}

# -----------------------------------------------------------------------------
# Interactions
# -----------------------------------------------------------------------------

#' MDE for an interaction (difference in treatment effects between two groups).
#' n_cells = c(control_g0, treat_g0, control_g1, treat_g1).
#' In a balanced 2x2 the interaction SE is twice the SE of a main effect that
#' pools all cells, so detecting an interaction of the same size needs ~4x N.
mde_interaction <- function(n_cells, alpha = 0.05, power = 0.80, sd = 1,
                            design = "post", rho = 0, r2_covariates = 0,
                            n_tests = 1, mcp = "none", sides = 2) {
  stopifnot(length(n_cells) == 4)
  factor <- .design_factor(design, rho, r2_covariates)
  se <- sd * factor * sqrt(sum(1 / n_cells))
  crit <- .crit(alpha, n_tests, mcp, sides)
  tibble(se = se, mde = (crit + qnorm(power)) * se, mde_sd = mde / sd)
}

# -----------------------------------------------------------------------------
# Simulation: data-generating processes
# Each DGP takes `effect` first and returns a tibble with
#   arm (factor, first level = control), d_<arm> dummies, y (outcome) and,
#   where relevant, y0 (baseline) and change (y - y0).
# -----------------------------------------------------------------------------

.add_arm_dummies <- function(d, arms) {
  for (a in arms[-1]) d[[paste0("d_", a)]] <- as.integer(d$arm == a)
  d
}

#' Multi-arm (or two-arm) design with an optional baseline.
#' effect_on: arms that receive `effect`; other arms are at the null, so their
#' rejection rates estimate the test's size.
#' rho: cor(y0, y) in the control group; var(y) = sd^2 in every arm.
#' outcome = "binary": y ~ Bernoulli(p0 + effect * treated); no baseline.
dgp_arms <- function(effect, n_per_arm, arms = c("control", "treat"),
                     effect_on = arms[-1], sd = 1, rho = 0,
                     outcome = "continuous", p0 = 0.5) {
  n_per_arm <- rep_len(n_per_arm, length(arms))
  d <- tibble(arm = factor(rep(arms, times = n_per_arm), levels = arms)) |>
    mutate(treated = as.integer(arm %in% effect_on))
  n <- nrow(d)
  if (outcome == "continuous") {
    d <- d |>
      mutate(y0 = sd * rnorm(n),
             y  = effect * treated + rho * y0 + sqrt(1 - rho^2) * sd * rnorm(n),
             change = y - y0)
  } else if (outcome == "binary") {
    p1 <- p0 + effect
    if (p1 < 0 || p1 > 1) stop("p0 + effect must be in [0, 1]")
    d <- d |> mutate(y = rbinom(n, 1, ifelse(treated == 1, p1, p0)))
  } else stop("outcome must be 'continuous' or 'binary'")
  .add_arm_dummies(d, arms)
}

#' Within-subject binary pair (e.g. a choice in round High and round Low).
#' Marginals: P(z_high) = p + effect/2 and P(z_low) = p - effect/2 in treated
#' arms (so the treated arm shifts the High-Low gap by `effect`), p in others.
#' rho: correlation between z_high and z_low. Outcome y = z_high - z_low.
dgp_within_binary <- function(effect, n_per_arm, arms = c("control", "treat"),
                              effect_on = arms[-1], p = 0.5, rho = 0.3) {
  n_per_arm <- rep_len(n_per_arm, length(arms))
  d <- tibble(arm = factor(rep(arms, times = n_per_arm), levels = arms)) |>
    mutate(treated = as.integer(arm %in% effect_on),
           ph = ifelse(treated == 1, p + effect / 2, p),
           pl = ifelse(treated == 1, p - effect / 2, p))
  if (any(d$ph > 1 | d$pl < 0)) stop("p +/- effect/2 must stay in [0, 1]")
  # Joint distribution of two correlated Bernoullis with given marginals
  p11 <- with(d, ph * pl + rho * sqrt(ph * (1 - ph) * pl * (1 - pl)))
  p10 <- d$ph - p11
  p01 <- d$pl - p11
  p00 <- 1 - p11 - p10 - p01
  if (any(c(p11, p10, p01, p00) < -1e-12)) stop("rho infeasible for these marginals")
  u <- runif(nrow(d))
  d |>
    mutate(z_high = as.integer(u < p11 + p10),
           z_low  = as.integer(u < p11 | (u >= p11 + p10 & u < p11 + p10 + p01)),
           y = z_high - z_low) |>
    select(-ph, -pl) |>
    .add_arm_dummies(arms)
}

#' Cluster-randomized two-arm design. Treatment is assigned at cluster level;
#' icc = share of outcome variance between clusters.
dgp_cluster <- function(effect, n_clusters_per_arm, cluster_size, icc,
                        sd = 1, arms = c("control", "treat")) {
  cl <- tibble(cluster = seq_len(2 * n_clusters_per_arm),
               arm = factor(rep(arms, each = n_clusters_per_arm), levels = arms),
               u = rnorm(2 * n_clusters_per_arm, 0, sd * sqrt(icc)))
  cl |>
    tidyr::uncount(cluster_size) |>
    mutate(treated = as.integer(arm == arms[2]),
           y = effect * treated + u + rnorm(n(), 0, sd * sqrt(1 - icc))) |>
    select(-u) |>
    .add_arm_dummies(arms)
}

# -----------------------------------------------------------------------------
# Simulation: estimators
# -----------------------------------------------------------------------------

#' Build an estimator from a fixest formula. vcov = "hetero" is HC1;
#' pass e.g. vcov = ~cluster for clustered SEs. Returns a function(data) that
#' gives term / estimate / std.error / p.value.
est_feols <- function(fml, vcov = "hetero") {
  force(fml); force(vcov)
  function(d) {
    m <- fixest::feols(fml, data = d, vcov = vcov, notes = FALSE, warn = FALSE)
    ct <- fixest::coeftable(m)
    tibble(term = rownames(ct), estimate = ct[, 1], std.error = ct[, 2],
           p.value = ct[, 4])
  }
}

# -----------------------------------------------------------------------------
# Simulation: driver
# -----------------------------------------------------------------------------

#' Monte Carlo power for the pre-registered estimator.
#'
#' dgp          : function(effect, ...) returning a data set
#' estimator    : function(data) returning term / estimate / std.error / p.value
#' effects      : effect sizes to simulate; ALWAYS include 0 to check size
#' tested_terms : coefficients forming the hypothesis family
#' mcp          : "none", "bonferroni", "holm" (any p.adjust method), applied
#'                within each replication across tested_terms
#' ...          : passed to dgp (e.g. n_per_arm, rho, arms, effect_on)
#' Returns, per effect and term: rejection rate (power or size), its Monte
#' Carlo SE, mean estimate (bias check) and SD of estimates vs mean SE
#' (SE calibration: the two should be close).
simulate_power <- function(dgp, estimator, effects, tested_terms, reps = 1000,
                           alpha = 0.05, mcp = "none", seed = 20261116,
                           parallel = FALSE, ...) {
  dgp_args <- list(...)
  one_rep <- function(effect) {
    d <- do.call(dgp, c(list(effect = effect), dgp_args))
    est <- estimator(d) |> filter(term %in% tested_terms)
    method <- if (mcp == "none") "none" else mcp
    est |> mutate(p.adj = p.adjust(p.value, method = method),
                  reject = p.adj < alpha)
  }
  run_effect <- function(effect) {
    if (parallel) {
      reps_out <- furrr::future_map(seq_len(reps), \(i) one_rep(effect),
                                    .options = furrr::furrr_options(seed = TRUE))
    } else {
      reps_out <- map(seq_len(reps), \(i) one_rep(effect))
    }
    bind_rows(reps_out) |> mutate(effect = effect)
  }
  set.seed(seed)
  map(effects, run_effect) |>
    bind_rows() |>
    group_by(effect, term) |>
    summarise(rejection_rate = mean(reject),
              mc_se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
              mean_estimate = mean(estimate),
              sd_estimate = sd(estimate),
              mean_se = mean(std.error),
              reps = n(), .groups = "drop") |>
    mutate(mcp = mcp, alpha = alpha)
}

#' MDE from a simulated power curve: linear interpolation of the effect at
#' which the rejection rate first reaches `target` for `term`.
mde_from_sim <- function(sim, term, target = 0.80) {
  s <- sim |> filter(.data$term == !!term) |> arrange(effect)
  i <- which(s$rejection_rate >= target)[1]
  if (is.na(i)) return(NA_real_)
  if (i == 1) return(s$effect[1])
  x0 <- s$effect[i - 1]; x1 <- s$effect[i]
  y0 <- s$rejection_rate[i - 1]; y1 <- s$rejection_rate[i]
  x0 + (target - y0) * (x1 - x0) / (y1 - y0)
}
