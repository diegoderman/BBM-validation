# Fit BBM on concatenations of even and odd MSC sessions per subject.
# Concatenation is delegated to BayesBrainMap by passing a list of BOLDs
# (CIFTI file paths) to fit_BBM rather than concatenating manually.

# all definitions in parameters (must precede setup.R -- setup.R reads bold_scaling)
source("./parameters.R")

# source setup script, which loads libraries and paths
source("./setup.R")

# load prior (mean vs sd BOLD-scaling variant, matches 01_fitMSC.r)
prior_msc_fname <- ifelse(bold_scaling == "mean",
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")),
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, "_sd.rds")))
prior_msc <- readRDS(prior_msc_fname)

# session groupings. The list name becomes the parity tag in the output filenames
# (fit_BBM_<sub>_ses-<parity>_...), so keep them filesystem-safe.
session_groups <- list(
  odd   = sprintf("func%02d", seq(1, 10, by = 2)),
  even  = sprintf("func%02d", seq(2, 10, by = 2)),
  `2ses` = c("func02", "func10"),
  `3ses` = c("func04", "func08", "func02"),
  `4ses` = c("func06", "func08", "func10", "func04")
)

for (subid in subjects) {

  subid_str <- paste0("sub-", subid)

  # per-subject midthickness surfaces used by smooth_cifti (analogous to 01_fitMSC.r)
  midthicknessL_fname <- file.path(dir_msc, subid_str, "fs_LR_Talairach", "fsaverage_LR32k",
                                   paste0(subid, ".L.midthickness.32k_fs_LR.surf.gii"))
  midthicknessR_fname <- file.path(dir_msc, subid_str, "fs_LR_Talairach", "fsaverage_LR32k",
                                   paste0(subid, ".R.midthickness.32k_fs_LR.surf.gii"))

  for (parity in names(session_groups)) {
    ses_ids <- session_groups[[parity]]
    print(paste("Processing subject", subid, "parity", parity,
                "- sessions:", paste(ses_ids, collapse = ",")))

    # build list of CIFTI paths for this (subject, parity)
    cifti_fnames <- vapply(ses_ids, function(sesid) {
      file.path(dir_msc,
                paste0("sub-", subid, "/processed_restingstate_timecourses/ses-", sesid, "/cifti"),
                paste0("sub-", subid, "_ses-", sesid, "_task-rest_bold_32k_fsLR.dtseries.nii"))
    }, character(1), USE.NAMES = FALSE)

    # stop and skip if any input file is missing
    missing <- cifti_fnames[!file.exists(cifti_fnames)]
    if (length(missing) > 0) {
      stop(paste("Missing CIFTI input(s) for", subid, parity, "- skipping:\n  ",
                    paste(missing, collapse = "\n  ")))
      next
    }

    # output paths
    dir_output_sub <- file.path(dir_output, "fit_BBM-rds", paste0("sub-", subid))
    dir.create(dir_output_sub, showWarnings = FALSE, recursive = TRUE)
    rds_fname <- file.path(dir_output_sub,
                           paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                  method_variance, "_", method_FC, "_", gsr, ".rds"))

    meanmap_dir <- file.path(".", paste0("output", bold_suffix), "rds", subid)
    dir.create(meanmap_dir, showWarnings = FALSE, recursive = TRUE)
    meanmap_fname <- file.path(meanmap_dir,
                               paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                      method_variance, "_", method_FC, "_", gsr, ".rds"))

    # cifti output (mean spatial map as a CIFTI, in a cifti subdirectory of dir_output)
    dir_cifti_sub <- file.path(dir_output, "cifti", paste0("sub-", subid))
    dir.create(dir_cifti_sub, showWarnings = FALSE, recursive = TRUE)
    cifti_fname <- file.path(dir_cifti_sub,
                             paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                    method_variance, "_", method_FC, "_", gsr, "_mean.dscalar.nii"))
    cifti_fname_sd <- file.path(dir_cifti_sub,
                                paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                       method_variance, "_", method_FC, "_", gsr, "_sd.dscalar.nii"))

    # skip if all outputs already exist
    if (file.exists(rds_fname) && file.exists(meanmap_fname) &&
        file.exists(cifti_fname) && file.exists(cifti_fname_sd)) {
      print(paste("  Outputs exist, skipping."))
      next
    }

    # read + smooth each session CIFTI, then pass the list of smoothed xiftis
    # to fit_BBM (BayesBrainMap concatenates internally). Smoothing matches
    # 01_fitMSC.r: FWHM 5 mm on surface and volume with the subject's midthickness.
    bold_ciftis_s <- lapply(cifti_fnames, function(fn) {
      smooth_cifti(read_cifti(fn), surf_FWHM = 5, vol_FWHM = 5,
                   surfL_fname = midthicknessL_fname,
                   surfR_fname = midthicknessR_fname)
    })

    # fit BBM on the list of session CIFTIs; BayesBrainMap handles concatenation
    msc_bbm <- fit_BBM(
      BOLD = bold_ciftis_s,
      prior = prior_msc,
      var_method = method_variance,
      method_FC = method_FC,
      TR = TR_MSC,
      drop_first = 5,
      GSR = FALSE, # GSR is already applied to the MSC data.
      scrub = FALSE,
      usePar = nThreads)

    # save full fit and mean spatial map
    saveRDS(msc_bbm, rds_fname)
    #saveRDS(msc_bbm$subjNet_mean, meanmap_fname)

    # write mean and SD spatial maps as CIFTI
    write_cifti(msc_bbm$subjNet_mean, cifti_fname)
    #write_cifti(msc_bbm$subjNet_se, cifti_fname_sd)
  }
}
