# renv::install("ciftiTools")            
# renv::install("mandymejia/fMRIscrub@14.0")        
# renv::install("mandymejia/fMRItools@7.0")
# renv::install("mandymejia/BayesBrainMap@2.0")
# renv::install("doParallel")
# renv::install("mandymejia/BayesBrainMap@3.0", library = "renv/library-bbm/3.0")
# renv::install("mandymejia/BayesBrainMap@2.0", library = "renv/library-bbm/2.0")

bbm_lib <- if (bold_scaling == "mean") "renv/library-bbm/3.0" else "renv/library-bbm/2.0"
.libPaths(c(bbm_lib, .libPaths()))                      # BBM from target, deps from main
library(BayesBrainMap)

stopifnot(
  "BayesBrainMap loaded from the wrong library" =
    identical(
      normalizePath(dirname(find.package("BayesBrainMap")), winslash = "/", mustWork = TRUE),
      normalizePath(bbm_lib,                                winslash = "/", mustWork = TRUE)
    )
)

# Load packages
library(ciftiTools)      # version 0.17.4
library(fMRIscrub)       # version 0.14.7
library("doParallel")
#renv::snapshot()

# DEFINITIONS
TR_MSC <- 2.2
Q <- 17 # number of independent components (networks) from the priors After removing the first (medial wall) component from the MSC template.

# Define hostname and system information
# initialize
IU_HPC <- FALSE
MACPRO <- FALSE
# check hostname to set flags and hostname variable
if (grepl("quartz.uits.iu.edu$", Sys.info()[["nodename"]])){
  IU_HPC <- TRUE 
  hostname <- "quartz"
} else if (grepl("red.uits.iu.edu$", Sys.info()[["nodename"]])){
  quartz <- TRUE
  hostname <- "quartz"
} else if (Sys.info()[["sysname"]] == "Darwin"){
  MACPRO <- TRUE
  hostname <- "macpro"
} else if (Sys.info()[["sysname"]] == "Windows"){
  hostname <- "windows"
} else {
  hostname <- "linux"
}

# Set CIFTI Workbench path
wb_path <- switch(hostname,
                   "macpro" = "~/Downloads/workbench/bin_macos64", # Path to Slate project on IU HPC
                   "quartz" = "~/Downloads/workbench/bin_rh_linux64", # Path to Slate project on mac pro
                   "linux" = "~/workbench-linux64-v2.1.0/workbench/bin_linux64", # Default path to Slate
                   "windows" = paste0(Sys.getenv("HOME"), "\\..\\Downloads\\workbench\\bin_windows64")) # Default path to Slate on Windows)
# Check if the path exists, otherwise throw an error
if (!file.exists(wb_path)) {
  stop(paste("Workbench path does not exist:", wb_path))
}
ciftiTools.setOption("wb_path", wb_path) 

# set up paths within slate project with switch case
dir_base <- switch(hostname,
                      "quartz" = "/N/project/BayesianBrainMapping", # Path to Slate project on IU HPC
                      "macpro" = "~/Documents/BayesianBrainMapping", # Path to Slate project on mac pro
                      "windows" = "Z:\\N\\project\\BayesianBrainMapping", # Default path to Slate on Windows
                      "~/Documents/BayesianBrainMapping") # Default path to Slate

# set up derived paths
dir_priors <- file.path(dir_base, "priors") # Path to priors folder
dir_output <- paste0(file.path(dir_base, "BBM-validation"), bold_suffix) # suffix _sd when bold_scaling != "mean"
dir_msc <- file.path(dir_base, "MSC/derivatives/surface_pipeline")


# set number of concurrent threads
Sys.setenv("OMP_NUM_THREADS" = "10")
