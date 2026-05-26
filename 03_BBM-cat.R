# Fit BBM on concatenations of even and odd MSC sessions per subject.
# Concatenation is delegated to BayesBrainMap by passing a list of BOLDs
# (CIFTI file paths) to fit_BBM rather than concatenating manually.

# source setup script, which loads libraries and paths
source("./setup.R")

# all definitions in parameters
source("./parameters.r")

# load prior
prior_msc <- readRDS(file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")))

# odd/even session groupings (func01..func10 -> odd: 1,3,5,7,9; even: 2,4,6,8,10)
session_groups <- list(
  odd  = sprintf("func%02d", seq(1, 10, by = 2)),
  even = sprintf("func%02d", seq(2, 10, by = 2))
)

for (subid in subjects) {
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

    meanmap_dir <- file.path(".", "output", "rds", subid)
    dir.create(meanmap_dir, showWarnings = FALSE, recursive = TRUE)
    meanmap_fname <- file.path(meanmap_dir,
                               paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                      method_variance, "_", method_FC, "_", gsr, ".rds"))

    # skip if both outputs already exist
    if (file.exists(rds_fname) && file.exists(meanmap_fname)) {
      print(paste("  Outputs exist, skipping."))
      next
    }

    # fit BBM on the list of session CIFTIs; BayesBrainMap handles concatenation
    msc_bbm <- fit_BBM(
      BOLD = as.list(cifti_fnames),
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
    saveRDS(msc_bbm$subjNet_mean, meanmap_fname)
  }
}
