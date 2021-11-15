library(palmerpenguins)
library(tidyverse)

# we are going to build a model to predict the sex of an individual penguin
# based on measurements of that individual.

# this is a thing people do
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0090081
# Ther eis some really nice data extracted from this paper
# It also has some great artwork:
# https://github.com/allisonhorst/palmerpenguins#artwork
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

## an aside - if you haven't seen `across` before, here is what it is
## equivalent to:
    ## penguins %>%
    ##   # remove missing value records
    ##   drop_na() %>%
    ##   # rescale the length and mass variables to make the coefficient priors easier
    ##   # to define
    ##   mutate(
    ##       bill_length_mm_scaled = scale(bill_length_mm_scaled),
    ##       bill_depth_mm_scaled = scale(bill_depth_mm_scaled),
    ##       flipper_length_mm_scaled = scale(flipper_length_mm_scaled),
    ##       body_mass_g_scaled = scale(body_mass_g_scaled)
    ##     )
    ##   )

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
y <- as_data(penguins_for_modelling$is_female_numeric)
# distribution(penguins_for_modelling$is_female_numeric) <- bernoulli(probability_female)
distribution(y) <- bernoulli(probability_female)

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

# bayesplot
## Look into PPCs:

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
yrep_model <- calculate(
  y,
  values = draws,
  nsim = 50
)

# each row represents a draw from the posterior predictive distribution
# There is one element for each of the datapoints in Y
# there were 333 rows in the data:
length(y)
# and then there are 500 rows, one for each simulation we drew earlier.
# given that there are
dim(yrep_model$y)
str(y)
# What we require here is a matrix
# where the rows are the number of draws
# and the columns are the number of observations
# we convert this with a special helper function, ppc_matrix
ppc_matrix <- function(x){
  matrix(data = x,
         nrow = dim(x)[1],
         ncol = dim(x)[2],
         byrow = TRUE)
}

yrep_matrix <- ppc_matrix(yrep_model$y)
y_values <- as.integer(y)

ppc_dens_overlay(y = y_values,
                 yrep = yrep_matrix)

# we see that there is wide variation in model estimates and data

# Another way to look at this is by looking at individual histograms
# of y and yrep data with ppc_hist
# here we control the number of plots by subsetting the matrix to be the first
# 5
ppc_hist(y = y_values,
         yrep = yrep_matrix[1:5,])

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

# we see there is variability in the estimate compared to the data

# some other ppc variants

ppc_ecdf_overlay(
  y_values,
  yrep_matrix
)

ppc_dens_overlay_grouped(y_values,
                         yrep_matrix,
                         group = penguins_for_modelling$island)

ppc_ecdf_overlay_grouped(y_values,
                         yrep_matrix,
                         group = penguins_for_modelling$island)
