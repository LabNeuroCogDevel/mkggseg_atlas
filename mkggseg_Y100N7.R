#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dplyr))

# help from:
#  https://github.com/LCBC-UiO/ggsegExtra/blob/master/vignettes/customatlas3d.Rmd
#  https://github.com/ThomasYeoLab/CBIG

# not in CRAN. need to pull from github
#  remotes::install_github('LCBC-UiO/ggsegExtra')
#  remotes::install_github('LCBC-UiO/ggseg3d')

# need orca as an external dependency for 3d->2d
#   npm install -g electron@6.1.4 orca

library(ggsegExtra)
library(ggseg3d)

atlasdir<-"/Volumes/Hera/Datasets/YeoLabCBIG/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/FreeSurfer5.3"
outdir <- '/Volumes/Hera/Datasets/YeoLabCBIG/ggseg'

# setenv not need if we use `annot_dir`
# Sys.setenv(SUBJECTS_DIR=atlasdir) # also see system("env|grep SUBJ")
# use make_aparc_2_3datlas(...,subject='fsaverage6') 

# NOTE HERE -- using fsaverage5 -- maybe want 6 ?!
annote_dir <- file.path(atlasdir,'fsaverage5/label')

mesh_dt <- make_aparc_2_3datlas(annot = "Schaefer2018_100Parcels_7Networks_order",
                           annot_dir = annote_dir,
                           output_dir = outdir)


# to 2d
atlasname <- "Yeo100N7_3d"
# atlas name must end in 3d for make_ggseg3d_2_ggset!
# otherwise:
# > Errror in get_atlas "This is not a 3d atlas"

Y100N7_segs <- mesh_dt %>%
  mutate(atlas = atlasname)%>%
  unnest(ggseg_3d) %>%
  select(-region) %>%
  left_join(select(ggseg::dk$data, hemi, region, label)) %>%
  nest_by(atlas, surf, hemi, .key = "ggseg_3d") %>%
  ggseg3d::as_ggseg3d_atlas()

# this can be true, but will still fail if altlas name is not *_3d
is_ggseg3d_atlas(Y100N7_segs) # TRUE
# using 1core so errors are easy to spot
Y100N7_2datlas <- make_ggseg3d_2_ggseg(output_dir="2d_orca",
                                       ggseg3d_atlas=Y100N7_segs,
                                       ncores=1)

ggseg:::get_atlas(Y100N7_segs)

save(mesh_dt,Y100N7_segs, Y100N7_2datlas,
     file='/Volumes/Hera/Datasets/YeoLabCBIG/ggseg/Y100N7.Rdata')


## USE

load('./df.MTR.Rdata') # MTR_coef_Age 
# rename and reformat input dataframe
d <-
   # list areas
   MTR_coef_Age$Area$ct_full_list %>% 
   # remove lh_ and _thinkness
   gsub('^[lr]h_','', .) %>% 
   gsub('_thickness', '', .) %>%
   # put back into a dataframe
   data.frame(T_Value=MTR_coef_Age$T_Value, region=.)

# 3d -- BUG: does not color/fill faces with values!?
p <- ggseg3d::ggseg3d(d, atlas=mesh_dt, color="T_Value")
htmlwidgets::saveWidget(p, selfcontained=T, file=file.path(getwd(),"/example/index.html"))


ggseg::ggseg(d, atlas=Y100N7_2datlas) 
