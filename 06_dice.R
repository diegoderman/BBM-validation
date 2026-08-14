# Written by Claude Code.
# Dice between BBM engagement maps and MSC canonical-network ground truth.
# The MSC prior guarantees BBM network q corresponds to canonical network
# gt_labels[q], so the primary result is the matched-pair diagonal. The full
# Q x K matrix and argmax are kept as sanity checks.

source("./parameters.R")  # must precede setup.R -- setup.R reads bold_scaling
source("./setup.R")

# DEFINITIONS
engagement_threshold <- 0.1

# output dirs
dir_output_dice <- file.path(dir_output, "dice")
dir.create(dir_output_dice, showWarnings = FALSE, recursive = TRUE)

# vectorised Dice: E is V x Q logical, G is V x K logical
dice_matrix <- function(E, G) {
  inter  <- crossprod(E + 0, G + 0)                 # Q x K
  sizeE  <- colSums(E)
  sizeG  <- colSums(G)
  denom  <- outer(sizeE, sizeG, "+")
  out <- 2 * inter / denom
  out[denom == 0] <- NA_real_
  out
}

for (subid in subjects) {
  sub_string <- paste0("sub-", subid)
  message("=== ", sub_string, " ===")

  # ---- ground truth: 17 canonical networks ----
  gt_path <- file.path(dir_base, "MSC", "derivatives", "surface_pipeline",
                       sub_string, "cifti_networks",
                       paste0(sub_string, "_networks.dscalar.nii"))
  if (!file.exists(gt_path)) {
    warning("Missing GT for ", subid, ": ", gt_path, " -- skipping subject.")
    next
  }
  gt_cifti <- read_cifti(gt_path, brainstructures = c("left", "right"))
  gt_vec   <- as.matrix(gt_cifti)

  # canonical network labels: fixed 1..17 shared across subjects so the same
  # matched components can be compared cross-subject (0 = unassigned / medial wall).
  gt_labels <- 1:17

  # one-hot GT: V x K logical
  G <- vapply(gt_labels, function(k) gt_vec == k, logical(length(gt_vec)))
  colnames(G) <- paste0("net", gt_labels)

  dir_out_sub <- file.path(dir_output_dice, sub_string)
  dir.create(dir_out_sub, showWarnings = FALSE, recursive = TRUE)

  for (sesid in c(sessions, "odd", "even")) {
    rds_fname <- file.path(dir_output, "fit_BBM-rds", sub_string,
                           paste0("fit_BBM_", subid, "_ses-", sesid, "_",
                                  method_variance, "_", method_FC, "_",
                                  gsr, ".rds"))
    if (!file.exists(rds_fname)) {
      message("  ", sesid, ": no fit at ", rds_fname, " -- skipping.")
      next
    }
    message("  ", sesid)
    fit <- readRDS(rds_fname)


    engaged_mat <- matrix(data = 0, nrow = nrow(fit$subjNet_mean), ncol = ncol(fit$subjNet_mean)) 
    engaged_mat[as.matrix(fit$subjNet_mean) >= engagement_threshold] <- 1 
    eng <- newdata_xifti(gt_cifti, engaged_mat)
    # extract V x Q logical from id_engagements output; adjust if the
    # package version returns a different container shape.
    #E_mat <- as.matrix(eng$engaged)
    E_mat <- engaged_mat
    storage.mode(E_mat) <- "logical"

    # sanity: vertex counts must match GT
    if (nrow(E_mat) != nrow(G)) {
      stop("Vertex mismatch for ", subid, " ", sesid,
           " (BBM=", nrow(E_mat), ", GT=", nrow(G),
           "). Resample the parcellation to match the BOLD grayordinates.")
    }

      # delete medial wall column in E_mat
      E_mat <- E_mat[,-1]
      Q <- ncol(E_mat)
      colnames(E_mat) <- paste0("bbm", seq_len(Q))

      dmat <- dice_matrix(E_mat, G)

      tag <- paste0("ses-", sesid, "_",
                    method_variance, "_", method_FC, "_", gsr)

      # full Dice matrix
      write.csv(dmat,
                file = file.path(dir_out_sub, paste0("dice_", tag, ".csv")),
                row.names = TRUE)

      # PRIMARY: matched-pair diagonal (prior guarantees bbm_q <-> gt_labels[q]).
      # If Q != K the pairing is truncated to min(Q, K).
      n_match <- min(Q, ncol(dmat))
      matched_df <- data.frame(
        bbm_network = seq_len(n_match),
        gt_network  = gt_labels[seq_len(n_match)],
        dice        = vapply(seq_len(n_match), function(q) dmat[q, q], numeric(1))
      )
      write.csv(matched_df,
                file = file.path(dir_out_sub, paste0("matched_", tag, ".csv")),
                row.names = FALSE)

    }
}

############################
# Exploration


for (i in 1:18){
  plot(prior_msc, idx = i, fname = file.path(dir_output, "prior", paste0("prior_MSC_GSR_", i, ".png")))
}

plot(eng, idx = 5, colors = "Paired", color_mode = "qualitative")
plot(prior_msc, idx = 5)
