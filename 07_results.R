# Summarise 06_dice matched-pair Dice outputs across subjects, one plot per
# matched component. Each plot: boxplot per subject over the 10 individual
# sessions, plus overlaid points for the odd/even concatenated-session fits.

source("./parameters.R")  # must precede setup.R -- setup.R reads bold_scaling
source("./setup.R")

library(dplyr)
library(tibble)
library(tidyr)
library(readr)
library(ggplot2)
library(purrr)

dir_dice <- file.path(dir_output, "dice")
dir_out  <- file.path(dir_dice, "summary")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

tag_suffix <- paste0(method_variance, "_", method_FC, "_", gsr)

# ---- load prior to get component names ----
# mean vs sd BOLD-scaling variant, matches 01_fitMSC.r
prior_msc_fname <- ifelse(bold_scaling == "mean",
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")),
                          file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, "_sd.rds")))
prior_msc <- readRDS(prior_msc_fname)

# Try common name-holder fields in a BayesBrainMap prior; fall back to "Network N".
# Candidates evaluated lazily so a missing field never runs as.matrix(NULL).
bbm_net_name <- function(idx, prior) {
  sprintf("Network %s", rownames(prior_msc$template_parc_table)[idx])
}

matched_path <- function(subid, sesid) {
  file.path(dir_dice, paste0("sub-", subid),
            paste0("matched_ses-", sesid, "_", tag_suffix, ".csv"))
}

# read one matched CSV -> tibble with (bbm_network, gt_network, dice); NULL if absent
read_matched <- function(subid, sesid) {
  p <- matched_path(subid, sesid)
  if (!file.exists(p)) {
    warning("Missing: ", p)
    return(NULL)
  }
  suppressMessages(read_csv(p, show_col_types = FALSE)) |>
    mutate(subject = subid, session = sesid)
}

# ---- collect per-network Dice across all subjects & sessions ----
grid <- bind_rows(
  crossing(subject = subjects, session = sessions)         |> mutate(kind = "individual"),
  crossing(subject = subjects, session = c("odd", "even")) |> mutate(kind = session)
) |> as_tibble()

net_dice <- grid |>
  pmap_dfr(function(subject, session, kind) {
    d <- read_matched(subject, session)
    if (is.null(d)) return(NULL)
    mutate(d, kind = kind)
  }) |>
  mutate(subject = factor(subject, levels = subjects))

write_csv(net_dice,
          file.path(dir_out, paste0("network_dice_", tag_suffix, ".csv")))

# ---- one plot per BBM component ----
# Group by bbm_network only: the MSC prior guarantees the BBM<->canonical
# correspondence; per-subject gt_network values that differ (e.g. MSC08/MSC09
# whose parcellations carry a slightly different label set) are folded into
# the title rather than triggering a separate plot.
plot_one_component <- function(df_component, bbm) {
  ind <- filter(df_component, kind == "individual", !is.na(dice))
  par <- filter(df_component, kind %in% c("odd", "even"), !is.na(dice))

  net_name <- bbm_net_name(bbm+1, prior_msc)

  p <- ggplot(ind, aes(subject, dice)) +
    geom_jitter(
      width = 0.15, height = 0,
      colour = "grey35", alpha = 0.7, size = 1.8
    ) +
    geom_point(
      data = par,
      aes(x = subject, y = dice, colour = kind, shape = kind),
      position = position_dodge(width = 0.5),
      size = 3, stroke = 1
    ) +
    scale_colour_manual(values = c(odd = "steelblue3", even = "firebrick3")) +
    scale_shape_manual (values = c(odd = 16,           even = 17)) +
    labs(
      title    = sprintf("Dice: %s  (BBM component %d, %s)",
                         net_name, bbm, tag_suffix),
      x        = "Subject",
      y        = "Diagonal Dice",
      colour   = "Concatenated fit",
      shape    = "Concatenated fit"
    ) +
    theme_bw(base_size = 13) +
    theme(legend.position = "right")

  fname <- file.path(
    dir_out,
    sprintf("network_dice_bbm%02d_%s.png", bbm, tag_suffix)
  )
  ggsave(fname, p, width = 11, height = 5.5, dpi = 130)
  fname
}

written <- net_dice |>
  group_by(bbm_network) |>
  group_map(~ plot_one_component(.x, .y$bbm_network)) |>
  unlist()

message("Wrote ", length(written), " component plots to ", dir_out)
