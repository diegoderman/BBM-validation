# renv::install("ciftiTools")            
# renv::install("mandymejia/fMRIscrub@14.0")        
# renv::install("mandymejia/fMRItools@7.0")
# renv::install("mandymejia/BayesBrainMap@2.0")
# renv::install("doParallel")

# Load packages
library(ciftiTools)      # version 0.17.4
library(fMRIscrub)       # version 0.14.7
library(BayesBrainMap)   # version: 0.2.0
library("doParallel")
#renv::snapshot()

# DEFINITIONS
TR_MSC <- 2.2

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
dir_output <- file.path(dir_base, "BBM-validation") # Path to output folder
dir_msc <- file.path(dir_base, "MSC/derivatives/surface_pipeline")
