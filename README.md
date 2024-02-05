
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

## Opening up the course locally on your machine

If you plan on following along locally on your machine instead of on posit cloud, you can download the course materials by copying this link and running it inside an RStudio session:

```r
use_course("https://github.com/njtierney/greta-course-notes/archive/refs/heads/master.zip")
```

Alternatively you can download the repository details by forking the repo, or pasting the above URL into the address bar of a browser.

## Schedule

The course will be delivered in person, see the [schedule](schedule.md) for more information.

## Setup & Installation

For instructions on installation see:

- [Cloud installation](setup-cloud.md)
- [Local installation](setup-local.md)
