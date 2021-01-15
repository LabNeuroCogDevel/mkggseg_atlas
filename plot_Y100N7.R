#!/usr/bin/env Rscript

# depends on mkggseg_Y100N7.R generating Y100N7.Rdata

suppressPackageStartupMessages(library(dplyr))
library(tidyr)
library(ggplot2)
library(ggsegExtra)
library(ggseg3d)
load('./Y100N7.Rdata')
load('./df.MTR.Rdata') # MTR_coef_Age 
# rename and reformat input dataframe
d <-
   # list areas
   MTR_coef_Age$Area$ct_full_list %>% 
   # remove lh_ and _thinkness
   gsub('^[lr]h_','', .) %>% 
   gsub('_thickness', '', .) %>%
   # put back into a dataframe
   data.frame(T_Value=MTR_coef_Age$T_Value, region=.) %>%
   mutate(hemi=ifelse(grepl('LH_', region), 'left','right'))

# head(d)
#  T_Value             region hemi
# 3.483789 7Networks_RH_Vis_1 right
# 3.269782 7Networks_RH_Vis_2 right
# 3.754837 7Networks_RH_Vis_3 right


# BUG from mkggseg_Y100N7.R
# ggseg::ggseg(d, atlas=Y100N7_2datlas) # is all gray
# Y100N7_2datlas$data$region and label are all NA

# BUG: region is all NA in Y100N7_2datlas
ggplot(d) +
   aes(color=T_Value) +
  ggseg::geom_brain(atlas=Y100N7_2datlas)


# 3d -- BUG: does not color/fill faces with values!?
disp_hemi <- "right"
p <- ggseg3d::ggseg3d(d %>% filter(hemi == disp_hemi),
                      atlas=mesh_dt, color="T_Value",
                      hemisphere=c(disp_hemi))
htmlwidgets::saveWidget(p, selfcontained=T, file=file.path(getwd(),"/example/index.html"))




## DEBUG missing hemi -- takeway: need `hemi` col or only give hemisphere we will display.
#   add label (left/right) to d
#   OR filter just displayed: d %>% filter(grepl("RH_",region))  
#  
# nothing in d$region is not in the annotation labels
# > all_annots <- lapply(mesh_dt$ggseg_3d, `[[`, 'annot') %>% unlist %>% unique
# > setdiff(d$region, all_annots)
#   character(0)
# BUT we get an error that looks like it includes all the annotation names
#  Some data is not merged properly into the atlas. Check for spelling mistakes in:
#    7Networks_LH_Vis_1, 7Networks_LH_Vis_2, 7Networks_LH_Vis_3, 7Networks_LH_Vis_4,  ... [... truncated]
# >  grep("7Networks_LH_Vis_1", all_annots, value=T)
#    [1] "7Networks_LH_Vis_1"
# >  grep("7Networks_LH_Vis_1", d$region, value=T)
#    [1] "7Networks_LH_Vis_1"

# from 
#>  a <- ggseg3d:::get_atlas(mesh_dt, surface = "LCBC", hemisphere = ("right"))
# > x <- ggseg3d:::data_merge(a, d) 
# >   cols <- names(a)[names(a) %in% names(d)]  # c("hemi", "region")
# >   atlas3d <- dplyr::full_join(a, d, by=cols, copy=TRUE) # 101 rows (Background is NA), thows warning
# >   has_mesh <- !sapply(atlas3d$mesh,is.null)
# >   atlas3d[has_mesh,c('region','label','T_Value')][2:3,]
# >   atlas3d[!has_mesh,c('region','label','T_Value')][2:3,]
#
#    region             label T_Value
#   <chr>              <chr>   <dbl>
#   7Networks_RH_Vis_1 rh_7Networks_RH_Vis_1    3.48
#   7Networks_RH_Vis_2 rh_7Networks_RH_Vis_2    3.27
#   7Networks_LH_Vis_2 NA                       4.82
#   7Networks_LH_Vis_3 NA                       5.71

