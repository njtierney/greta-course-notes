# Setup

This course will be run on RStudio (Posit) cloud. This is so all required packages and software versions are pre-installed. There will be a small installation step that will take about 5 minutes.

The reason there are these extra installation steps is that greta uses Google's TensorFlow and the tensorflow-probability python modules under the hood. 

To assist with installing these Python modules, greta provides an installation helper, `install_greta_deps()`.

This installs the exact pythons package versions needed, and places these inside a "greta-env" conda environment. 

This isolates these exact python modules from other python installations, so that only greta will see them. This helps avoids installation issues, where previously you might update tensorflow on your computer and overwrite the current version needed by greta. 

Using this "greta-env" conda environment means installing other python packages should not be impact the Python packages needed by greta.

If these python modules aren't yet installed, when greta is used, it provides instructions on how to install them for your system. If in doubt follow those.

## Installing `greta`

We have recently improved how `greta` is installed. From scratch, installing `greta` should look like the following:

1. `install.packages("remotes")` (Skip on posit cloud)
2. `remotes::install_github("greta-dev/greta")` (Skip on posit cloud)
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

Note that there might be some angry red test mentioning cuDNN/cuFFT/cuBLAS. This is related to GPUs - CUDA graphics card setup. I believe this is mostly  an issue on posit cloud instances. It will not impact your use of greta during the course.

8. Check that you can fit a model with code like:

```r
library(greta)
normal(0,1)
m <- model(normal(0,1))
draws <- mcmc(m)
plot(draws)
```

If you get some output that looks [like the output here](https://gist.github.com/njtierney/5c0e7d9f8be79cb30c7131e0d2cfbdfb)

Then you are good to go!
