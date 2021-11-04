library(palmerpenguins)
library(tidyverse)
library(bayesplot)

# we are going to build a model to predict the sex of an individual penguin
# based on measurements of that individual.

# this is a thing people do
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0090081

# here's the data from that paper
head(penguins)

# before we can fit a model, we need to tidy up the data and transform some variables
penguins_for_modelling <- penguins %>%
  # remove missing value records
  drop_na() %>%
  # rescale the length and mass variables to make the coefficient priors easier
  # to define
  mutate(
    across(
      c(ends_with("mm"), ends_with("g")),
      .fns = list(scaled = ~scale(.x))
    ),
    # code the sex as per a Bernoulli distribution
    is_female_numeric = if_else(sex == "female", 1, 0),
    .after = island
  )

# this is the model we are going to fit to start with:

# likelihood
#   is_female_numeric[i] ~ Bernoulli(probability_female[i])
# link function
#   logit(probability_female[i]) = eta[i]
# linear predictor
#   eta[i] = intercept + coef1 * flipper_length_mm_scaled[i] +
#              coef2 * body_mass_g_scaled[i]

# here's a non-bayesian (maximum-likelihood) version
non_bayesian_model <- glm(
  is_female_numeric ~ flipper_length_mm_scaled + body_mass_g_scaled,
  data = penguins_for_modelling,
  family = stats::binomial
)

summary(non_bayesian_model)

# now let's fit the Bayesian equivalent
library(greta)

# define priors
intercept <- normal(0, 10)
coef_flipper_length <- normal(0, 10)
coef_body_mass <- normal(0, 10)

# define linear predictor
eta <- intercept +
  coef_flipper_length * penguins_for_modelling$flipper_length_mm_scaled +
  coef_body_mass * penguins_for_modelling$body_mass_g_scaled

# apply link function
probability_female <- ilogit(eta)

# define likelihood
distribution(penguins_for_modelling$is_female_numeric) <- bernoulli(probability_female)


# combine into a model object
m <- model(intercept, coef_flipper_length, coef_body_mass)

# do MCMC - 4 chains, 1000 on each after 1000 warmuup (the default)
draws <- mcmc(m)

# visualise the MCMC traces
plot(draws)

# viasualise with bayesplot
bayesplot::mcmc_trace(draws)

# check convergence (we already discarded burn-in and don't need the
# multivariate stat)
coda::gelman.diag(draws, autoburnin = FALSE, multivariate = FALSE)

# look at the parameter estimates
summary(draws)



# predict to a new dataset - first the marginal effect of body mass on the link
# scale

penguins_for_prediction <- expand_grid(
  flipper_length_mm_scaled = seq(
    min(penguins_for_modelling$flipper_length_mm_scaled),
    max(penguins_for_modelling$flipper_length_mm_scaled),
    length.out = 50
  ),
  body_mass_g_scaled = seq(
    min(penguins_for_modelling$body_mass_g_scaled),
    max(penguins_for_modelling$body_mass_g_scaled),
    length.out = 50
  )
)

# predict to these data
eta_pred <- intercept +
  coef_flipper_length * penguins_for_prediction$flipper_length_mm_scaled +
  coef_body_mass * penguins_for_prediction$body_mass_g_scaled

probability_female_pred <- ilogit(eta_pred)

# compute posterior prediction simulations
n_sims <- 200
sims <- calculate(
  probability_female_pred,
  values = draws,
  nsim = n_sims
)

penguins_prediction <- sims$probability_female_pred[, , 1] %>%
  t() %>%
  as_tibble() %>%
  set_names(paste0("sim_", seq_len(n_sims))) %>%
  bind_cols(
    penguins_for_prediction,
    .
  ) %>%
  pivot_longer(
    cols = starts_with("sim"),
    names_to = "sim",
    values_to = "probability_female",
    names_prefix = "sim_"
  )

# plot the conditional effect of bodymass, for the mean flipper length
penguins_prediction_body_mass_conditional <- penguins_prediction %>%
  filter(
    abs(flipper_length_mm_scaled) == min(abs(flipper_length_mm_scaled))
  )

penguins_prediction_body_mass_conditional_summary <- penguins_prediction_body_mass_conditional %>%
  group_by(
    body_mass_g_scaled
  ) %>%
  summarise(
    probability_female_mean = mean(probability_female),
    probability_female_upper = quantile(probability_female, 0.975),
    probability_female_lower = quantile(probability_female, 0.025),
  )

penguins_prediction_body_mass_conditional_summary %>%
  ggplot(
    aes(
      x = body_mass_g_scaled
    )
  ) +
  geom_line(
    aes(
      x = body_mass_g_scaled,
      y = probability_female,
      colour = sim
    ),
    data = penguins_prediction_body_mass_conditional,
    size = 0.1
  ) +
  geom_ribbon(
    aes(
      ymax = probability_female_upper,
      ymin = probability_female_lower
    ),
    fill = "transparent",
    colour = "black",
    linetype = 2
  ) +
  geom_line(
    aes(
      y = probability_female_mean
    )
  ) +
  theme_minimal() +
  theme(
    legend.position = "none"
  )


