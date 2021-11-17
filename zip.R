library(greta)

lambda <- lognormal(1, 1)
count <- poisson(lambda)

prob_zero <- uniform(0, 1)
prob_positive <- 1 - prob_zero

zero <- poisson(.Machine$double.eps)

y <- as_data(rpois(100, pi))

distribution(y) <- mixture(zero, count, weights = c(prob_zero, prob_positive))
m <- model(lambda, prob_zero)
draws <- mcmc(m)

plot(draws)
summary(draws)


lambda <- lognormal(1, 1)
count <- poisson(lambda)

prob_zero <- uniform(0, 1)
prob_positive <- 1 - prob_zero

zero <- poisson(.Machine$double.eps)
z <- mixture(zero, count, weights = c(prob_zero, prob_positive))
sims <- calculate(z, nsim = 10000, values = list(lambda = 2, prob_zero = 0.7))

mean(sims$z == 0)
0.7 + (1 - 0.7) * dpois(0, 2)
