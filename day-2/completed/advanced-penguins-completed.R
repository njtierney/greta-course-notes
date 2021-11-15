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

# define a hierarchical random-intercepts and random-slopes model
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

# and the same for the slopes, for each coefficient
coef_flipper_length_mean <- normal(0, 10)
coef_flipper_length_sd <- normal(0, 1, truncation = c(0, Inf))
coef_species_flipper_length_raw <- normal(0, 1, dim = n_species)
coef_species_flipper_length <- coef_flipper_length_mean + coef_flipper_length_sd * coef_species_flipper_length_raw
coef_flipper_length <- coef_species_flipper_length[species_index]

coef_body_mass_mean <- normal(0, 10)
coef_body_mass_sd <- normal(0, 1, truncation = c(0, Inf))
coef_species_body_mass_raw <- normal(0, 1, dim = n_species)
coef_species_body_mass <- coef_body_mass_mean + coef_body_mass_sd * coef_species_body_mass_raw
coef_body_mass <- coef_species_body_mass[species_index]

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
           coef_flipper_length_mean, coef_flipper_length_sd,
           coef_body_mass_mean, coef_body_mass_sd)

# do MCMC - 4 chains, 1000 on each after 1000 warmup (the default)
draws <- mcmc(m)

plot(draws)

plot(calculate(coef_species_body_mass, values = draws))




# fitting a linear model with a design matrix and formula interface

# R's formula interface is a really nice way of:
# a) setting up all the covariates and interactions we want to model,
# b) converting categorical variables into separate columns of dummy variables,
# b) taking care of identifiability in those combinations (with contrasts)
# we can use it to quickly set up a matrix of covariates to use in modelling:
covariates <- model.matrix(
  ~ species * bill_length_mm_scaled +
    species * bill_depth_mm_scaled +
    species * flipper_length_mm_scaled +
    species * body_mass_g_scaled,
  data = penguins_for_modelling
)

dim(covariates)
head(covariates)


n_covariates <- ncol(covariates)

# we can then specify our coefficients as a vector to combine with these:
coef <- normal(0, 10, dim = n_covariates)

# the matrix multiply operator handles multiplying each coefficient by each
# covariate and then summing across the rows to get the linear predictor for
# each observation
eta <- covariates %*% coef

# apply link function
probability_female <- ilogit(eta)

# define likelihood
y <- as_data(penguins_for_modelling$is_female_numeric)
distribution(y) <- bernoulli(probability_female)

m <- model(coef)

draws <- mcmc(m)

plot(draws)
coda::gelman.diag(draws, autoburnin = FALSE, multivariate = FALSE)

# The downside of this is that we lose some control over our model - it becomes
# difficult to specify meaningful priors or encode hierarchical structure as
# part of this. It can be handy for setting up a part of a larger model however.
