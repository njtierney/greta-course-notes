
# An introduction to Bayesian modelling using `greta`

<!-- badges: start -->
<!-- badges: end -->

This is the course repository for the course, "An introduction to Bayesian modelling using `greta`", run on February 7 through the Statistical Society of Australia ([course advertisement](https://statsoc.org.au/event-5513733?CalendarViewType=1&SelectedDate=1/29/2024)).

This course is designed for those who want to learn how to do Bayesian modelling using the `greta` software. We assume users have the following background/experience:

- Familiarity with R
- Experience using linear models
- A rudimentary understanding of Bayesian inference

After this course you will be able to:

- Fit and predict from Bayesian generalised linear models in greta
- Check model convergence and fit (including prior and posterior predictive checks)
- Summarise MCMC outputs
- Be able to fit more advanced models including mixture and hierarchical models
- Create visualisations and tables of the model outputs for use in understanding model fit and for publication.

We will start with simple linear models on real ecological data, and gradually expand the models to be more complex and better represent the data. We will also have time at the end of the course to discuss fitting models specific to your own work - so feel free to bring along a problem you’d like to discuss!

The course will be delivered virtually, in two 4 hour blocks over two days.

# Installation instructions

This course will be run on the posit cloud service, which (should) mean that all of the R packages will be installed and ready to use. This is done to save time in the course so you can get up and running faster with greta. 

However, we do want you to be able to use greta locally on your own machine! So here are installation instructions, but note that these are not required for the course.

Before you can fit models with greta, you will also need to have a working installation of Google’s TensorFlow and the tensorflow-probability python modules.

To assist with installing these Python modules, greta provides an installation helper, `install_greta_deps()`, which installs the exact pythons package versions needed. It also places these inside a “greta-env” conda environment. This isolates these exact python modules from other python installations, so that only greta will see them. This helps avoids installation issues, where previously you might update tensorflow on your computer and overwrite the current version needed by greta. Using this “greta-env” conda environment means installing other python packages should not be impact the Python packages needed by greta.

If these python modules aren’t yet installed, when greta is used, it provides instructions on how to install them for your system. If in doubt follow those.

Currently, the best way to install `greta` for the course is to install a development branch, like so:

```r
# install.packages("remotes")
# install the "TF2 greta course" branch:
remotes::install_github("njtierney/greta@tf2-gc")
```

Then, load `greta` with library, and run the installation helper:

```r
library(greta)
install_greta_deps()
```

This might take a few minutes. It should then come up with some instructions on restarting R. Restart R, then try the following:

```r
library(greta)
# greta situation report
greta_sitrep()
```

You should then be all good to go!

# How to get the course details:

```r
use_course("course-link-info-coming-soon")
```
