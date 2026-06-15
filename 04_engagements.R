# create png visualization files from BBM RDS files.

# load packages
source("./setup.R")

# load parameters
source("./parameters.R")

# Define output dir for engagement maps
dir_output_engagements <- file.path(dir_output, "engagement_maps-png")
dir.create(dir_output_engagements, showWarnings = FALSE)

# Define output dir for comparison maps
dir_output_comparison <- file.path(dir_output, "comparison_maps-png")
dir.create(dir_output_comparison, showWarnings = FALSE)


# for each subject and session, load the fitted BBM model and create visualizations
# for subjects and sessions
for (subid in subjects) {

  subject_engagements <- list()

  # define and create dir outout for subject
    dir_output_sub <- file.path(dir_output_engagements, paste0("sub-", subid))
    dir.create(dir_output_sub, showWarnings = FALSE)
    
  for (sesid in sessions) {
    print(paste("Processing subject", subid, "session", sesid))

    # define and create dir outout for session
    dir_output_ses <- file.path(dir_output_engagements, paste0("sub-", subid, "/ses-", sesid))
    dir.create(dir_output_ses, showWarnings = FALSE)
    
    
    # Define output dir
    dir_input_sub <- file.path(dir_output, paste0("fit_BBM-rds/sub-", subid))
    
    # load FC estimates
    rds_fname <- file.path(dir_input_sub, paste0("fit_BBM_", subid, "_ses-", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    msc01_bbm <- readRDS(rds_fname)

    # Calculate engagements for all networks
    z = c(1, 2, 3)
    eng <- id_engagements(
      msc01_bbm,
      z = z,
      method_p = "bonferroni"
    )

    # Plot brainmap and engagement for each network separately
    for (i in 1:Q){
      
        # plot brainMap scalar maps
        fname = file.path(dir_output_ses, paste0("sub_", subid, "_ses-", sesid, "_engagement_", method_variance, "_", method_FC, "_", gsr, "_", i , ".png"))
    
        # Generate engagement map ############## FIGURE FOCAL ENGAGEMENT MAP ##############
        plot(eng, idx = i, stat = "engaged", title = "", cex.title = 1e-6, legend_embed = FALSE, fname=fname) 


    }
    
    # Save engagement map at Z>1 for comparison between sessions

    #subject_engagements[[sesid]] <- engagements(bMap, z = 1, method_p = "bonferroni")

    
  }
}
