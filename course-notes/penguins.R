library(palmerpenguins)
library(tidyverse)

# we are going to build a model to predict the sex of an individual penguin
# based on measurements of that individual.

# this is a thing people do
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0090081

# here's the data from that paper (from the palmerpenguins package)
head(penguins)

# The package also has some great artwork:
# https://github.com/allisonhorst/palmerpenguins#artwork

# before we can fit a model, we need to tidy up the data and transform some variables
penguins_for_modelling <- penguins %>%
  # remove missing value records
  drop_na() %>%
  # rescale the length and mass variables to make the coefficient priors easier
  # to define
  mutate(
    across(
      c(bill_length_mm,
        bill_depth_mm,
        flipper_length_mm,
        body_mass_g),
      .fns = list(scaled = ~scale(.x))
    ),
    # code the sex as per a Bernoulli distribution
    is_female_numeric = if_else(sex == "female", 1, 0),
    .after = island
  )

# an aside - if you haven't seen `across` before, here is what it is
# equivalent to:
#  penguins %>%
#    # remove missing value records
#    drop_na() %>%
#    # rescale the length and mass variables to make the coefficient priors easier
#    # to define
#    mutate(
#         bill_length_mm_scaled = scale(bill_length_mm_scaled),
#         bill_depth_mm_scaled = scale(bill_depth_mm_scaled),
#         flipper_length_mm_scaled = scale(flipper_length_mm_scaled),
#         body_mass_g_scaled = scale(body_mass_g_scaled)
#       )
#    )

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

plot(m)

# do MCMC - 4 chains, 1000 on each after 1000 warmuup (the default)
draws <- mcmc(m)

# visualise the MCMC traces
plot(draws)

# check convergence (we already discarded burn-in and don't need the
# multivariate stat)
coda::gelman.diag(draws, autoburnin = FALSE, multivariate = FALSE)

# look at the parameter estimates
summary(draws)

# Instructors proceed with live coding
