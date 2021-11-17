# https://joss.theoj.org/papers/10.21105/joss.01601

library(MASS)
epil$trt_id <- as.numeric(epil$trt)
baseline_y <- epil$base[!duplicated(epil$subject)]

library(greta)

# priors
subject_mean <- normal(0, 10)
subject_sd <- cauchy(0, 1, truncation = c(0, Inf))

# hierararchical model for baseline rates (transformed to be positive)
subject_effects <- normal(subject_mean, subject_sd, dim = 59)
baseline_rates <- exp(subject_effects)

treatment_effects <- normal(1, 1, dim = 2, truncation = c(0, Inf))
post_treatment_rates <- treatment_effects[epil$trt_id] *
  baseline_rates[epil$subject]

# likelihood
distribution(baseline_y) <- poisson(baseline_rates * 8)
distribution(epil$y) <- poisson(post_treatment_rates * 2)

m <- model(treatment_effects, subject_sd)
draws <- mcmc(m, chains = 4)

library(bayesplot)
bayesplot::mcmc_trace(draws)

coda::gelman.diag(draws)

summary(draws)$statistics

# create a drug effect variable and calculate posterior samples
drug_effect <- treatment_effects[2] / treatment_effects[1]
drug_effect_draws <- calculate(drug_effect, values = draws)
summary(drug_effect_draws)$statistics

