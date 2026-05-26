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
    dir_input_sub <- normalizePath(file.path(".", "output", "rds", subid))
    dir_output_sub <- normalizePath(file.path("./output/png", paste0("sub-",subid)))
    
    # create output dir
    dir.create(dir_output_sub, showWarnings = FALSE, recursive = TRUE)
    
    # load FC estimates
    rds_fname <- file.path(dir_input_sub, paste0("fit_BBM_", subid, "_ses-", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    msc01_bbm <- readRDS(rds_fname)
    
    # get number of independent components
    Q <- dim(msc01_bbm$data$cortex_left)[2]
    
    for (i in 1:Q) {
      
      png_fname <- file.path(dir_output_sub, paste0("fit_BBM_", subid, "_ses-", sesid, "_", method_variance, "_", method_FC, "_", gsr, "_", i, ".png"))
      title <- paste0("Subject: ", subid, " Session: ", sesid, " Network: ", i)
      
      plot(
        msc01_bbm,
        fname = png_fname,
        idx = i,
        title = title
      )
    }
  }
}