library(greta)


# defining random effects with arbitrary covariance structures
 # (in this example hard-coded) - just model it as a multivariate normal
n_coefs <- 3

# hack to create a random valid covariance matrix
cov_raw <- matrix(rnorm(n_coefs ^ 2), n_coefs)
cov <- cov_raw %*% t(cov_raw)

# non-decentered version (do the other one)
coefs <- multivariate_normal(mean = t(rep(0, n_coefs)),
                             Sigma = cov)

# hierarchical decentring on MVN
coefs_raw <- normal(0, 1, dim = n_coefs)
C <- chol(cov)
coefs <- t(C) %*% coefs_raw


# note that an IID random effect (hierarchical normal with shared sd, no
# correlation) is just a multivariate normal with diagonal covariance structure
sd <- normal(0, 1, truncation = c(0, Inf))
cov_iid <- diag(n_coefs) * sd ^ 2
coefs_raw <- normal(0, 1, dim = n_coefs)
C <- chol(cov_iid)
coefs <- t(C) %*% coefs_raw

# simulate these and plot the joint distribution for the first two coefficients
# they are uncorrelated, so this is boring
sims <- calculate(coefs, values = list(sd = 2), nsim = 1000)
par(mfrow = c(1, 1))
plot(sims$coefs2[, 1:2, 1])

# plot the joint distribution for the first two coefficients
# with the correlated version, so this is boring
coefs_raw <- normal(0, 1, dim = n_coefs)
C <- chol(cov)
coefs <- t(C) %*% coefs_raw
sims <- calculate(coefs, values = list(sd = 2), nsim = 1000)
par(mfrow = c(1, 1))
plot(sims$coefs[, 1:2, 1])
cov[1:2, 1:2]

# using greta.gp:
library(greta.gp)

# define kernel functions and add them together
k1 <- rbf(lengthscales = c(1, 2), variance = 0.6)
k2 <- bias(variance = lognormal(0, 1))
K <- k1 + k2

# use this kernel in a full-rank Gaussian process
x <- seq(0, 10, length.out = 100)
f <- gp(x, K)
# simulate and draw
sims <- calculate(f, nsim = 1)
plot(sims[[1]][1, , 1] ~ x, type = "l")


# define a 2D GP over a grid of coordinates
coords_grid <- expand_grid(
  x = seq(0, 1, length.out = 100),
  y = seq(0, 1, length.out = 100)
)
plot(y ~ x, data = coords_grid)

lengthscale <- lognormal(0, 1)
variance <- normal(0, 1, truncation = c(0, Inf))
spatial_re <- mat32(lengthscales = c(lengthscale, lengthscale),
                    variance = variance)

# the covariance matrix will have 10,000^2 elements!
# cov <- spatial_re(coords_grid)
f <- gp(coords_grid, kernel = spatial_re)

# this will take some time because it's so big - this is why people always
# approximate GPs, especially in the spatial case. greta.gp does a sparse GP
# approximation (FITC). It's also possible to do other things, like SPDE matern
# on a mesh, like INLA, but the code is still in development. Get in touch if
# you are keen on that.
sims <- calculate(f, nsim = 1)

# you can see some waves (lazy plotting)
plot(y ~ x,
     data = coords_grid,
     cex = exp(sims$f),
     pch = 16)

# simulate species count data over 10 timesteps
n_times <- 10
times <- seq_len(n_times)
truth <- 100 * exp(sin(times))
y <- rpois(n_times, truth)
plot(y ~ times, type = "l")

# this didn't work in MCMC, we'll have to work out why.
# library(greta.gam)
# eta <- smooths(~ 1 + s(time), data = data.frame(time = times))
# lambda <- exp(eta)
# distribution(y) <- poisson(lambda)

len <- lognormal(0, 1)
var <- normal(0, 1, truncation = c(0, Inf))
k <- rbf(lengthscales = len, variance = var)
eta <- gp(times, k)
lambda <- exp(eta)
distribution(y) <- poisson(lambda)

m <- model(eta)
draws <- mcmc(m)

# plot credible intervals
coda::gelman.diag(draws, autoburnin = FALSE)
sims <- calculate(lambda, nsim = 100, values = draws)
dim(sims$lambda)
quants <- apply(sims$lambda[, , 1], 2, quantile, c(0.025, 0.975))
plot(quants[2, ] ~ times,
     ylim = c(0, max(c(quants, y))),
     type = "l")
lines(quants[1, ] ~ times)
points(y ~ times)

