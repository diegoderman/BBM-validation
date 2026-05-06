# install.packages("devtools")
# install.packages("gsignal")
# install.packages("ggcorrplot")
# install.packages("ciftiTools")            
# devtools::install_github("mandymejia/fMRIscrub", "14.0")          
# install.packages("fMRItools") # deprecated for new BBM
# devtools::install_github("mandymejia/fMRItools", "7.0", force=TRUE)
# install.packages("viridis")
# install.packages("BayesBrainMap")
# install.packages("doParallel")
# devtools::install_github("diegoderman/BayesBrainMap", ref = "2.0")

# Load packages
library(ggcorrplot)      # version 0.1.4.1
library(gsignal)         # version 0.3.7
library(ciftiTools)      # version 0.17.4
library(fMRIscrub)       # version 0.14.7
library(viridis)         # version 0.6.5
library(BayesBrainMap)   # version: 0.2.0
library(tidyverse)       # version: 2.0.0
library(purrr)           # version: 0.2.0
library("doParallel")

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
} else if (Sys.info()[["sysname"]] == "Darwin"){
  MACPRO <- TRUE
  hostname <- "macpro"
} else {
  hostname <- "linux"
}

# Set CIFTI Workbench path
wb_path <- "~/workbench-linux64-v2.1.0/workbench/bin_linux64" # Path to Workbench command, e.g. "~/workbench-command" or "C:/path/to/workbench-command.exe"
# Check if the path exists, otherwise throw an error
if (!file.exists(wb_path)) {
  stop(paste("Workbench path does not exist:", wb_path))
}
ciftiTools.setOption("wb_path", wb_path) 

# set up paths within slate project with switch case
dir_base <- switch(hostname,
                      "quartz" = "/N/project/BayesianBrainMapping", # Path to Slate project on IU HPC
                      "macpro" = "~/Documents/BayesianBrainMapping", # Path to Slate project on mac pro
                      "~/Documents/BayesianBrainMapping") # Default path to Slate

# set up derived paths
dir_priors <- file.path(dir_base, "priors") # Path to priors folder
dir_output <- file.path(dir_base, "BBM-validation", "output") # Path to output folder
dir_msc <- file.path(dir_base, "MSC/derivatives/surface_pipeline")
