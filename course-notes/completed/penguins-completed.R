library(palmerpenguins)
library(tidyverse)
library(bayesplot)
library(DiagrammeR)

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
# distribution(penguins_for_modelling$is_female_numeric) <- bernoulli(probability_female)
y <- as_data(penguins_for_modelling$is_female_numeric)
distribution(y) <- bernoulli(probability_female)

# combine into a model object
m <- model(intercept, coef_flipper_length, coef_body_mass)

plot(m)

# do MCMC - 4 chains, 1000 on each after 1000 warmuup (the default)
draws <- mcmc(m)

# visualise the MCMC traces
plot(draws)

# we can also use bayesplot to explore the convergence of the model
bayesplot::mcmc_trace(draws)
bayesplot::mcmc_dens(draws)

# check convergence (we already discarded burn-in and don't need the
# multivariate stat)
coda::gelman.diag(draws, autoburnin = FALSE, multivariate = FALSE)

# look at the parameter estimates
summary(draws)

## doing prediction
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
# to do this we need some simulated predictions
# in a regular glm model, you might do something like:
# predict(glm_model)
# which would produce a vector of model predictions the same length as the
# data
# we will use greta's `calculate` function, which will act in a similar way
# but has a lot of other uses and is very flexible
n_sims <- 200
sims <- calculate(
  probability_female_pred,
  values = draws,
  nsim = n_sims
)

penguins_prediction <- sims$probability_female_pred[, , 1] %>%
  t() %>%
  as_tibble(.name_repair = "unique") %>%
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
# recall: the mean flipper length has been scaled to have mean of 0 and SD of 1
# also recall: we created a sequence from the min to max scaled flipper length
# so although we want to say "filter to the mean value, which is zero", we
# instead say: "filter to the mean value, which is the smallest absolute value"
# which will be very close to zero.
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
    linewidth = 0.1
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


## Posterior predictive check

# we want to see how well the data match the predictions from the model that
# we have fit
# to do this we are going to do a graphical "posterior predictive check" (or
# PPC for short).
# you can think of this as being analogous to comparing your data to the model
# predictions. If the model and the data are similar, we've done a good job
# fitting our model. If they are not similar, our model doesn't represent the
# data very well
# There are some helpful ways to visualise this build into the "bayesplot" R
# package. But we need to do some summaries of the data first.
# this next step is inspired by the well worked vignette,
# "graphical PPCs", found at:
# https://cran.r-project.org/web/packages/bayesplot/vignettes/graphical-ppcs.html
library(bayesplot)

# to do this we need some simulated predictions
# in a regular glm model, you might do something like:
# predict(glm_model)
# which would produce a vector of model predictions the same length as the
# data
# we will use greta's `calculate` function, which will act in a similar way
# but has a lot of other uses and is very flexible
# for the moment, we will focus on this specific use, for calculating predictions
# We take our vector, y, which is out outcome
# then we tell it to use the draws object
# and to calculate 500 simulations
sims_model <- calculate(
  y,
  values = draws,
  nsim = 500
)

# each row represents a draw from the posterior predictive distribution
# There is one element for each of the datapoints in Y
# there were 333 rows in the data:
length(y)
# and then there are 500 rows, one for each simulation we drew earlier.
# given that there are
dim(sims_model$y)
str(y)
# What we require here is a matrix
# where the rows are the number of draws
# and the columns are the number of observations
# this object is actully a 3 dimensional array.
# We want to keep everything in the first two
# TODO explain unpacking this
# sims_y_mat <- sims_model$y
# dim(sims_y_mat) <- c(500, 333)
yrep_matrix <- sims_model$y[ , ,1]
y_values <- as.integer(y)

## distribution of test statistics

# we can  look at the distribution of ones over the replicated datasets
# from the posterior predictive distribution in yrep_matrix and compare to the
# proportion of observed ones in y.

# we define a function that tells us the proportion of ones
prop_ones <- function(x) mean(x == 1)
prop_ones(y_values) # check proportion of ones in y

# We can visualise the proportion of ones in the simulations from the model
ppc_stat(y_values,
         yrep_matrix,
         stat = "prop_ones",
         binwidth = 0.005)

ppc_stat_grouped(y_values,
                 yrep_matrix,
                 stat = "prop_ones",
                 penguins_for_modelling$sex,
                 binwidth = 0.005)

# there are other uses of PPC
# see
# https://cran.r-project.org/web/packages/bayesplot/vignettes/graphical-ppcs.html


###
# we can also do *Prior* predictive checks
sims_prior <- calculate(
  y,
  nsim = 500
)

yrep_prior_matrix <- sims_prior$y[,,1]

## distribution of test statistics

# we define a function that tells us the proportion of ones
# We can visualise the proportion of ones in the simulations from the model
ppc_stat(y_values,
         yrep_prior_matrix,
         stat = "prop_ones",
         binwidth = 0.005)

ppc_stat_grouped(y_values,
                 yrep_prior_matrix,
                 stat = "prop_ones",
                 penguins_for_modelling$sex,
                 binwidth = 0.005)

# there are other uses of PPC

# how to check your priors
sims_params_prior <- calculate(
  probability_female[1,],
  eta[1,],
  intercept,
  coef_flipper_length,
  coef_body_mass,
  nsim = 500
)

hist(sims_params_prior$`probability_female[1, ]`)
hist(sims_params_prior$`eta[1, ]`)
hist(sims_params_prior$intercept)
hist(sims_params_prior$coef_flipper_length)
hist(sims_params_prior$coef_body_mass)

# your turn: how to visualise your posterior samples
###

