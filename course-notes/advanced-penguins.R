library(palmerpenguins)
library(tidyverse)

# we are going to extend our model of the sex of an individual penguin to
# include a hierarchical (random effects) structure

# tidy up the data as before
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

# create numeric codes for the categorical variables we'd like to specify a hierarchical model over
all_species <- unique(as.character(penguins_for_modelling$species))
n_species <- length(all_species)
species_index <- match(penguins_for_modelling$species, all_species)

# define a hierarchical random-intercept model
library(greta)

# define non-hierarchical priors
coef_flipper_length <- normal(0, 10)
coef_body_mass <- normal(0, 10)

# define a hierarchical prior on the intercepts for each species
intercept_mean <- normal(0, 10)
intercept_sd <- normal(0, 1, truncation = c(0, Inf))

# # the more obvious way
# species_intercepts <- normal(intercept_mean, intercept_sd, dim = n_species)

# a slightly more numerically stable way - hierarchical decentreing:
species_intercepts_raw <- normal(0, 1, dim = n_species)
species_intercepts <- intercept_mean + intercept_sd * species_intercepts_raw

# compute the different intercept for each observation, by expanding out the
# vector of three intercepts
intercept <- species_intercepts[species_index]

# define linear predictor
eta <- intercept +
  coef_flipper_length * penguins_for_modelling$flipper_length_mm_scaled +
  coef_body_mass * penguins_for_modelling$body_mass_g_scaled

# apply link function
probability_female <- ilogit(eta)

# define likelihood
y <- as_data(penguins_for_modelling$is_female_numeric)
distribution(y) <- bernoulli(probability_female)

# combine into a model object
m <- model(intercept_mean, intercept_sd,
           coef_flipper_length, coef_body_mass)

# do MCMC - 4 chains, 1000 on each after 1000 warmup (the default)
draws <- mcmc(m)

plot(draws)

plot(calculate(species_intercepts, values = draws))
