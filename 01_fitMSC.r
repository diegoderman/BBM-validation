# fit a single session of MSC data to the MSC GSR priors.

# all definitions in parameters
source("./parameters.R")

# source setup script, which loads libraries and paths
source("./setup.R") # updated setup to 3.0, uses local mean BOLD normalization


# load prior
prior_msc_fname <- ifelse(bold_scaling == "mean",
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")),
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, "_sd.rds")))

prior_msc <- readRDS(prior_msc_fname)

# for subjects and sessions
# debugging
# subid <- subjects[1]
# sesid <- sessions[1]

# run thourgh all the selected subjects and sessions
for (subid in subjects) {
  
  subid_str <- paste0("sub-", subid)
  
  midthicknessL_fname <- file.path(dir_msc, subid_str, "fs_LR_Talairach", "fsaverage_LR32k", paste0(subid, ".L.midthickness.32k_fs_LR.surf.gii"))
  midthicknessR_fname <- file.path(dir_msc, subid_str, "fs_LR_Talairach", "fsaverage_LR32k", paste0(subid, ".R.midthickness.32k_fs_LR.surf.gii"))
  
  for (sesid in sessions) {
    print(paste("Processing subject", subid, "session", sesid))
    
    # Define output dir
    dir_output_sub <- file.path(dir_output, "fit_BBM-rds", paste0("sub-", subid))
    dir.create(dir_output_sub, showWarnings = FALSE, recursive = TRUE)
    
    # load preprocessed bold timeseries
    cifti_fname <- file.path(dir_msc, paste0("sub-", subid, "/processed_restingstate_timecourses/ses-", sesid, "/cifti"),
                             paste0("sub-", subid, "_ses-", sesid, "_task-rest_bold_32k_fsLR.dtseries.nii"))
    bold_cifti <- read_cifti(cifti_fname)
    
    bold_cifti_s <- smooth_cifti(bold_cifti, surf_FWHM = 5, vol_FWHM = 5,
                               surfL_fname = midthicknessL_fname,
                               surfR_fname = midthicknessR_fname)
     
    # plot mean time series of bold
    msc01_bbm <- fit_BBM(
      BOLD = bold_cifti_s,
      prior = prior_msc,
      var_method = method_variance,
      method_FC = method_FC,
      TR = TR_MSC,
      drop_first = 5,
      GSR = FALSE, # GSR is already applied to the MSC data.
      scrub = FALSE,
      usePar = nThreads)
    
    # debug, load rds 
    rds_fname <- file.path(dir_output_sub, paste0("fit_BBM_", subid, "_ses-", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    #msc01_bbm <- readRDS(rds_fname)
    # save model fit
    saveRDS(msc01_bbm, rds_fname)
    
    # save mean spatial map on project directory for quick visualization.
    #meanmap_dir <- file.path(".", paste0("output", bold_suffix), "rds", subid)
    #dir.create(meanmap_dir, showWarnings = FALSE, recursive = TRUE)
    #meanmap_fname <- file.path(meanmap_dir, paste0("fit_BBM_", subid, "_ses-", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    #saveRDS(msc01_bbm$subjNet_mean, meanmap_fname)
    
  }
}
