# TEMPORARY: backfill CIFTI files from BBM fits already saved as RDS.
# Loads each full fit RDS under dir_output/fit_BBM-rds/sub-*/ and writes its
# mean spatial map ($subjNet_mean) as a CIFTI into dir_output/cifti/sub-*/,
# using the same basename as the main pipeline (03_BBM-cat.R).

source("./setup.R")
source("./parameters.r")

# locate already-saved full-fit RDS files
rds_files <- list.files(
  file.path(dir_output, "fit_BBM-rds"),
  pattern = "\\.rds$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(rds_files) == 0) {
  stop(paste("No RDS files found under", file.path(dir_output, "fit_BBM-rds")))
}

for (rds_fname in rds_files) {
  print(paste("Converting", rds_fname))

  # subject folder is the parent dir name (e.g. "sub-MSC01")
  sub_dir <- basename(dirname(rds_fname))

  # mirror the rds basename but as CIFTI dscalars (mean and SD)
  cifti_base    <- sub("\\.rds$", "_mean.dscalar.nii", basename(rds_fname))
  cifti_base_sd <- sub("\\.rds$", "_sd.dscalar.nii", basename(rds_fname))

  dir_cifti_sub <- file.path(dir_output, "cifti", sub_dir)
  dir.create(dir_cifti_sub, showWarnings = FALSE, recursive = TRUE)
  cifti_fname    <- file.path(dir_cifti_sub, cifti_base)
  cifti_fname_sd <- file.path(dir_cifti_sub, cifti_base_sd)

  if (file.exists(cifti_fname) && file.exists(cifti_fname_sd)) {
    print("  CIFTI exists, skipping.")
    next
  }

  msc_bbm <- readRDS(rds_fname)
  write_cifti(msc_bbm$subjNet_mean, cifti_fname)
  write_cifti(msc_bbm$subjNet_se, cifti_fname_sd)
}
