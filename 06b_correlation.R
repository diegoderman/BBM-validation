# 06b_correlation

source("./parameters.R")  # must precede setup.R -- setup.R reads bold_scaling
source("./setup.R")

# DEFINITIONS
library(tidyr)
library(dplyr)
library(ggplot2)

# output dirs
dir_output_cor <- file.path(dir_output, "correlation")
dir.create(dir_output_cor, showWarnings = FALSE, recursive = TRUE)

# Initialization
rows <- list()
ic_names <- rownames(prior_msc$template_parc_table)

############
# START DEBUG
#############

subjects <- subjects[-10]

############
# END DEBUG
#############

for (subid in subjects) {
  sub_string <- paste0("sub-", subid)
  message("=== ", sub_string, " ===")
  dir_BBM_sub <- file.path(dir_output, "fit_BBM-rds", sub_string) 
  
  # ---- ground truth: defined as dual regression result of odd session
  
  parity <- "odd"
  odd_results_fname <- file.path(dir_BBM_sub,
                                 paste0("fit_BBM_", subid, "_ses-", parity, "_",
                                 method_variance, "_", method_FC, "_", gsr, ".rds"))
  
  # load dual regression result
  dr_gt <- t(readRDS(odd_results_fname)$result_DR$S)
  
  
  for (sesid in c(sessions, "2ses", "3ses", "4ses", "even")) {
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
    
    cmat <- diag(cor(as.matrix(fit$subjNet_mean), dr_gt))
    rows[[length(rows) + 1L]] <- c(
      list(subject = subid, session = sesid),
      setNames(as.list(cmat), ic_names)
    )
    
  }
}

# Write final tibble.
# session_kind is ordered by number of sessions in the fit:
# individual (1) -> 2ses -> 3ses -> 4ses -> even (5)
result <- bind_rows(rows) %>%
  mutate(
    session_kind = factor(
      case_when(
        session %in% c("even", "2ses", "3ses", "4ses") ~ session,
        TRUE                                           ~ "individual"
      ),
      levels = c("individual", "2ses", "3ses", "4ses", "even")
    ),
    n_sessions = case_when(
      session == "even" ~ 5L,
      session == "4ses" ~ 4L,
      session == "3ses" ~ 3L,
      session == "2ses" ~ 2L,
      TRUE              ~ 1L
    )
  )

average <- result %>%
  summarize(mean = mean(Default))

# ---- faceted correlation plot ----

result_long <- result %>%
  select(-`Medial Wall`) %>%
  pivot_longer(cols = -c(subject, session, session_kind, n_sessions),
               names_to  = "component",
               values_to = "correlation") %>%
  mutate(
    subject   = factor(subject, levels = subjects),
    component = factor(component, levels = ic_names)   # preserve IC order
  )

p_cor <- ggplot(result_long, aes(x = session_kind, y = correlation, colour = subject)) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.4) +
  geom_jitter(width = 0.2, height = 0, alpha = 0.75, size = 1.8) +
  geom_boxplot(
    data          = result_long,
    mapping       = aes(x = session_kind, y = correlation),
    inherit.aes   = FALSE,
    width         = 0.5,
    fill          = "white",
    colour        = "grey20",
    alpha         = 0.55,
    outlier.shape = NA,
    linewidth     = 0.5
  ) +
  facet_wrap(~ component, ncol = 6) +
  scale_colour_viridis_d(option = "turbo", end = 0.92, name = "Subject") +
  guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1), ncol = 2)) +
  scale_y_continuous(limits = c(0.0, 1), breaks = seq(0.2, 1, 0.2)) +
  labs(
    title    = sprintf("Correlation of session BBM mean maps with odd-session ground truth (%s)",
                       paste(method_variance, method_FC, gsr, sep = "_")),
    subtitle = "One point per (subject, session); facet = IC component",
    x = NULL, y = "Pearson r"
  ) +
  theme_bw(base_size = 12) +
  theme(
    panel.grid.minor       = element_blank(),
    strip.background       = element_rect(fill = "grey92", colour = NA),
    strip.text             = element_text(face = "bold"),
    axis.text.x            = element_text(angle = 45, hjust = 1, size = 8),
    plot.title.position    = "plot",
    legend.position        = c(0.98, 0.08),           # bottom-right, floats inside plot area
    legend.justification   = c("right", "bottom"),
    legend.background      = element_blank(),#element_rect(fill = alpha("white", 0.85), colour = "grey60"),
    legend.key             = element_blank(),
    legend.title           = element_text(face = "bold")
  )

png_fname <- file.path(dir_output_cor,
                       paste0("correlation_by_component_",
                              method_variance, "_", method_FC, "_", gsr, ".png"))
ggsave(png_fname, p_cor, width = 17, height = 9, dpi = 130)
message("Wrote: ", png_fname)

# ---- second plot: correlation vs number of sessions, per-subject slope ----

p_trend <- ggplot(result_long,
                  aes(x = n_sessions, y = correlation, colour = subject)) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.4) +
  geom_jitter(width = 0.15, height = 0, alpha = 0.6, size = 1.4) +
  geom_smooth(aes(group = subject), method = "lm", se = FALSE,
              linewidth = 0.6, alpha = 0.9) +
  facet_wrap(~ component, ncol = 6) +
  scale_colour_viridis_d(option = "turbo", end = 0.92, name = "Subject") +
  guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1,
                                                   linewidth = 1), ncol = 2)) +
  scale_x_continuous(breaks = 1:5,
                     labels = c("1", "2", "3", "4", "5 (even)")) +
  scale_y_continuous(limits = c(0.0, 1), breaks = seq(0.2, 1, 0.2)) +
  labs(
    title    = sprintf("Correlation vs. #sessions in fit, per-subject linear trend (%s)",
                       paste(method_variance, method_FC, gsr, sep = "_")),
    subtitle = "Points: (subject, session); lines: OLS fit per subject; facet = IC component",
    x = "Number of sessions in BBM fit", y = "Pearson r"
  ) +
  theme_bw(base_size = 12) +
  theme(
    panel.grid.minor       = element_blank(),
    strip.background       = element_rect(fill = "grey92", colour = NA),
    strip.text             = element_text(face = "bold"),
    plot.title.position    = "plot",
    legend.position        = c(0.98, 0.08),
    legend.justification   = c("right", "bottom"),
    legend.background      = element_blank(),
    legend.key             = element_blank(),
    legend.title           = element_text(face = "bold")
  )

png_fname_trend <- file.path(dir_output_cor,
                             paste0("correlation_trend_by_nsessions_",
                                    method_variance, "_", method_FC, "_", gsr, ".png"))
ggsave(png_fname_trend, p_trend, width = 17, height = 9, dpi = 130)
message("Wrote: ", png_fname_trend)




