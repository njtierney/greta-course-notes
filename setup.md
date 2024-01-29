# Setup

We will be running the course on RStudio (Posit) cloud. This is so all required packages and software versions are pre-installed.

Before the course starts here is what you need to do:

- Create an account on rstudio.cloud (following instructions from the email sent out to all course attendees)

## Installing `greta` on your local machine.

We have recently improved how `greta` is installed. From scratch, installing `greta` should look like the following:

1. `install.packages("remotes")`
2. `remotes::install_github("greta-dev/greta")`
3. Restart R
4. `library(greta)`
5. `install_greta_deps()`
6. Follow the prompts from here:
  - Restart R
7. Check that greta is installed with:

```r
greta::greta_sitrep()
```

This should give you a happy message like:

```
```

8. Check that you can fit a model with code like:

```r
library(greta)
normal(0,1)
m <- model(normal(0,1))
mcmc(m)
```
