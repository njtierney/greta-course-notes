library(tidyverse)

fun <- function(temp, height, peak_temp, width) {
  height * exp( -(temp - peak_temp) ^ 2 / (2 * width ^ 2))
}
temp <- seq(0, 50, by = 1)
activity <- fun(temp, height = 10, peak_temp = 25, width = 5)
plot(activity ~ temp, type = "l")

n_nests <- 5
n_obs <- 500

peak_temps <- runif(n_nests, 20, 30)
heights <- rep(runif(1, 5, 20), n_nests)
widths <- rep(runif(1, 3, 5), n_nests)

data_full <- tibble(
  nest = sample(seq_len(n_nests), n_obs, replace = TRUE),
  temp = runif(n_obs, 10, 50)
) %>%
  mutate(
    peak_temp = peak_temps[nest],
    height = heights[nest],
    width = widths[nest],
  ) %>%
  mutate(
    expected_activity = fun(temp,
                            height = height,
                            peak_temp = peak_temp,
                            width = width),
    observed_activity = expected_activity + rnorm(n = n_obs, 0, 1),
    observed_activity = pmax(observed_activity, 0)
  )


data <- data_full %>%
  filter(observed_activity > 0)

data %>%
  ggplot(
    aes(
      x = temp,
      y = observed_activity,
      colour = nest
    )
  ) +
  geom_point()

library(greta)

peak_temp_mean <- normal(25, 10)
peak_temp_sd <- normal(0, 1, truncation = c(0, Inf))
peak_temp_nest_raw <- normal(0, 1, dim = n_nests)
peak_temp_nest <- peak_temp_mean + peak_temp_sd * peak_temp_nest_raw

height <- normal(20, 10, truncation = c(0, Inf))
width <- normal(10, 10, truncation = c(0, Inf))

peak_temp <- peak_temp_nest[data$nest]

expected_activity <- fun(data$temp,
                         height = height,
                         peak_temp = peak_temp,
                         width = width)

obs_sd <- normal(0, 1, truncation = c(0, Inf))

distribution(data$observed_activity) <- normal(expected_activity,
                                               obs_sd,
                                               truncation = c(0, Inf))

m <- model(peak_temp_mean, peak_temp_sd, height, width)
draws <- mcmc(m, chains = 10)

plot(draws)
coda::gelman.diag(draws, autoburnin = FALSE, multivariate = FALSE)

summary(draws)
peak_temp_nest_draws <- calculate(peak_temp_nest, values = draws)
plot(peak_temp_nest_draws)
summary(peak_temp_nest_draws)
peak_temps


width_draws <- calculate(width, values = draws)
plot(width_draws)

