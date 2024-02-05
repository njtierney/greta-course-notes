# Example code demonstrating Neal's funnel, and why hierarchical decentring
# helps sampling in hierarchical models

# here's a longer explainer:
# https://mc-stan.org/docs/2_18/stan-users-guide/reparameterization-section.html


# we set up a hierarchical model with the standard deviation as lognormal
# (parameters chosen to be a bit pathological)
log_sigma <- normal(0, 3)
sigma <- exp(log_sigma / 2)

# 5 random variables from this distribution
x <- normal(0, sigma, dim = 5)

# simulate IID samples from the *prior* density
sims_prior <- calculate(log_sigma, x[1],
                        nsim = 10000)

# the prior has a horrible geometry. MCMC samplers can't be tuned to explore
# efficiently in the wide part of the funnel and the narrow part of the funnel
par(mfrow = c(2, 2))
plot(sims_prior$log_sigma ~ sims_prior$`x[1]`,
     cex = 0.1,
     main = "prior - standard")

m <- model(x, log_sigma)
draws <- mcmc(m)
sims_post <- calculate(log_sigma, x[1],
                       values = draws,
                       nsim = 10000)

plot(sims_post$log_sigma ~ sims_post$`x[1]`,
     cex = 0.1,
     main = "posterior - standard")

# we can instead reparameterise x to make sampling a bit easier

# sigma is the same
log_sigma <- normal(0, 3)
sigma <- exp(log_sigma / 2)

# 5 random variables from this distribution
x_raw <- normal(0, 1, dim = 5)
x <- x_raw * sigma

# the prior density is the same:
sims_prior_reparam <- calculate(log_sigma, x[1],
                                nsim = 10000)
plot(sims_prior_reparam$log_sigma ~ sims_prior_reparam$`x[1]`,
     cex = 0.1,
     main = "prior - reparam")

# but the posterior has better sampling in the narrow part of the funnel
m <- model(x, log_sigma)
draws <- mcmc(m)
sims_post_reparam <- calculate(log_sigma, x[1],
                       values = draws,
                       nsim = 10000)

plot(sims_post_reparam$log_sigma ~ sims_post_reparam$`x[1]`,
     cex = 0.1,
     main = "posterior - reparam")


# this is because the MCMC sampler is now *looking at* (sampling in the space
# defined on) log_sigma and x_raw, and those variables don't have a dependency
sims_x_raw <- calculate(log_sigma, x_raw[1],
                       nsim = 10000)
par(mfrow = c(1, 1))
plot(sims_x_raw$log_sigma ~ sims_x_raw$`x_raw[1]`,
     cex = 0.1)

