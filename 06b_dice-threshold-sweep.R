# Sweep the mean-map threshold used to binarize BBM engagement, for a single
# subject across its sessions, and report the threshold that maximises the
# matched-pair Dice against the canonical-network ground truth.
#
# Mirrors the matching convention in 06_dice.R: drop the first `bbm_drop`
# BBM components, then pair the remaining bbm_{i} with gt_labels[i].

source("./parameters.R")  # must precede setup.R -- setup.R reads bold_scaling
source("./setup.R")

# -------- sweep configuration --------
subid_sweep <- "MSC01"
sesids      <- sessions                          # all sessions for that subject
thresholds  <- seq(0.05, 0.30, by = 0.01)
bbm_drop    <- 1L                                # number of leading BBM components to drop before matching

dir_out_sweep <- file.path(dir_output, "dice", paste0("sub-", subid_sweep), "threshold_sweep")
dir.create(dir_out_sweep, showWarnings = FALSE, recursive = TRUE)

# -------- ground truth --------
sub_string <- paste0("sub-", subid_sweep)
gt_path <- file.path(dir_base, "MSC", "derivatives", "surface_pipeline",
                     sub_string, "cifti_networks",
                     paste0(sub_string, "_networks.dscalar.nii"))
gt_cifti  <- read_cifti(gt_path, brainstructures = c("left", "right"))
gt_vec    <- as.matrix(gt_cifti)
gt_labels <- sort(unique(gt_vec))
gt_labels <- gt_labels[gt_labels > 0]
G <- vapply(gt_labels, function(k) gt_vec == k, logical(length(gt_vec)))
K <- ncol(G)

# vectorised Dice: E (V x Q) vs G (V x K) -> Q x K
dice_matrix <- function(E, G) {
  inter  <- crossprod(E + 0, G + 0)
  denom  <- outer(colSums(E), colSums(G), "+")
  out    <- 2 * inter / denom
  out[denom == 0] <- NA_real_
  out
}

# -------- sweep --------
rows <- list()

for (sesid in sesids) {
  rds_fname <- file.path(dir_output, "fit_BBM-rds", sub_string,
                         paste0("fit_BBM_", subid_sweep, "_ses-", sesid, "_",
                                method_variance, "_", method_FC, "_", gsr, ".rds"))
  if (!file.exists(rds_fname)) {
    message("  ", sesid, ": no fit -- skipping.")
    next
  }
  message("== ", sesid, " ==")
  fit <- readRDS(rds_fname)
  mean_mat <- as.matrix(fit$subjNet_mean)         # V x Q (full)
  Q <- ncol(mean_mat)
  if (bbm_drop >= Q)
    stop("bbm_drop=", bbm_drop, " drops all BBM components (Q=", Q, ").")

  # matched-pair diagonal after the drop: bbm_{i+bbm_drop} <-> gt_labels[i]
  n_match <- min(Q - bbm_drop, K)

  for (thr in thresholds) {
    # threshold first, then drop the first bbm_drop components -- matches 06_dice.R
    E_full <- mean_mat >= thr
    E      <- E_full[, -seq_len(bbm_drop), drop = FALSE]
    dmat   <- dice_matrix(E, G)
    matched_vals <- vapply(seq_len(n_match),
                           function(i) dmat[i, i],
                           numeric(1))
    rows[[length(rows) + 1L]] <- data.frame(
      session      = sesid,
      threshold    = thr,
      mean_dice    = mean(matched_vals, na.rm = TRUE),
      median_dice  = median(matched_vals, na.rm = TRUE),
      min_dice     = suppressWarnings(min(matched_vals, na.rm = TRUE)),
      max_dice     = suppressWarnings(max(matched_vals, na.rm = TRUE)),
      n_networks   = sum(!is.na(matched_vals))
    )
  }
}

sweep_df <- do.call(rbind, rows)
write.csv(sweep_df,
          file = file.path(dir_out_sweep,
                           paste0("sweep_", subid_sweep, "_",
                                  method_variance, "_", method_FC, "_", gsr, ".csv")),
          row.names = FALSE)

# -------- best threshold per session and overall --------
best_per_session <- do.call(rbind, by(sweep_df, sweep_df$session, function(d)
  d[which.max(d$mean_dice), , drop = FALSE]))

overall <- aggregate(mean_dice ~ threshold, data = sweep_df, FUN = mean)
best_overall_thr  <- overall$threshold[which.max(overall$mean_dice)]
best_overall_dice <- max(overall$mean_dice)

write.csv(best_per_session,
          file = file.path(dir_out_sweep,
                           paste0("best_per_session_", subid_sweep, ".csv")),
          row.names = FALSE)
write.csv(overall,
          file = file.path(dir_out_sweep,
                           paste0("overall_", subid_sweep, ".csv")),
          row.names = FALSE)

message("\n---- best threshold per session (max mean matched Dice) ----")
print(best_per_session[, c("session", "threshold", "mean_dice")])
message("\n---- overall best threshold (averaged over sessions) ----")
message(sprintf("  threshold = %.2f   mean matched Dice = %.4f",
                best_overall_thr, best_overall_dice))
