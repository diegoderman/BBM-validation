# create png visualization files from BBM RDS files.

# load packages
source("./setup.R")

# load parameters
source("./parameters.R")

# for each subject and session, load the fitted BBM model and create visualizations
# for subjects and sessions
for (subid in subjects) {
  for (sesid in sessions) {
    print(paste("Processing subject", subid, "session", sesid))
    
    # Define output dir
    dir_input_sub <- file.path(dir_output, paste0("sub-", subid))
    
    # load FC estimates
    rds_fname <- file.path(dir_input_sub, paste0("fit_BBM_", subid, "_", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    msc01_bbm <- readRDS(rds_fname)
    
    plot(msc01_bbm, what = "mean")

    
  }
}