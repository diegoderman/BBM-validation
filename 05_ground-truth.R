#' Compare engagement maps from BBM with ground truth derived from MSC parcellations
#' This scripts takes




subid <- "MSC01"
sub_string <- paste0("sub-", subid)

dir_parcel <- file.path(dir_base, "MSC", "derivatives", "surface_pipeline", sub_string, "surface_parcellation")

#################################
# Load Ground truth

gt_cifti <- read_cifti(file.path(dir_parcel, paste0(sub_string, "_parcel_networks.dscalar.nii")))

gt_mat <- as.matrix(gt_cifti)
gt_29 <- gt_mat

gt_29[gt_mat != 29] <- 0
gt_29[gt_mat == 29] <- 1

# plot class 29
plot(newdata_xifti(gt_cifti, gt_29))

# plot class 0
gt_0 <- gt_mat

gt_0[gt_mat != 0] <- 0
gt_0[gt_mat == 0] <- 1

# plot class 0
plot(newdata_xifti(gt_cifti, gt_0))

#####################################
# Load dlabel file

label_cifti <- read_cifti(file.path(dir_parcel, paste0(sub_string, "_parcels.dtseries.nii")))

plot(label_cifti)

####################################
# Networks file 

dir_parcel <- file.path(dir_base, "MSC", "derivatives", "surface_pipeline", sub_string, "cifti_networks")
gt_cifti <- read_cifti(file.path(dir_parcel, paste0(sub_string, "_networks.dscalar.nii")))

plot(gt_cifti, zlim = c(21, 21), colors = "Paired")#, color_mode = "qualitative")
