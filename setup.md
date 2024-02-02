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
> greta_sitrep()
✔ python (v3.9) available     
✔ TensorFlow Probability (v0.23.0) available  
2024-02-01 23:39:04.425108: E external/local_xla/xla/stream_executor/cuda/cuda_dnn.cc:9261] Unable to register cuDNN factory: Attempting to register factory for plugin cuDNN when one has already been registered
2024-02-01 23:39:04.425223: E external/local_xla/xla/stream_executor/cuda/cuda_fft.cc:607] Unable to register cuFFT factory: Attempting to register factory for plugin cuFFT when one has already been registered
2024-02-01 23:39:05.376304: E external/local_xla/xla/stream_executor/cuda/cuda_blas.cc:1515] Unable to register cuBLAS factory: Attempting to register factory for plugin cuBLAS when one has already been registered
✔ TensorFlow (v2.15.0) available  
✔ greta conda environment available            
✔ Initialising python and checking dependencies ... done!               
```

Note that there might be some angry red test mentioning cuDNN. This is something to do with CUDA graphics card setup, and I believe might mostly be an issue on posit cloud instances. But it will not impact your use of greta.

8. Check that you can fit a model with code like:

```r
library(greta)
normal(0,1)
m <- model(normal(0,1))
mcmc(m)
```
