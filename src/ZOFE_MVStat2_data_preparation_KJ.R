# ZOFE Multivariate Stats 2, ZOFE nutrient fluxes exercise

setwd ("C:/1_Work/R/ZOFE")
# install.packages("readxl")

library(readxl)
library(ggplot2)
library(dplyr)

### plant data

# Load the Excel file
ZOFE_crops <- read_excel("crop data.xlsx", sheet = 1)  # sheet can be name or index

# Define the column titles in the specified order
column_titles <- c(
  "plot_nr", "replicate", "treatment_ID", "treatment_en", "treatment", "crop_abr", "year",
  "fert_Nmin_tot", "fert_Norg_tot", "fert_N_tot", "fert_P_tot", "fert_K_tot", "fert_Mg_tot",
  "annual_N_uptake", "annual_P_uptake", "annual_K_uptake", "annual_Mg_uptake",
  "annual_total_biomass_maincrop_DM"
)


# Extract the columns from the data frame
ZOFE_extracted <- ZOFE_crops[, column_titles, drop = FALSE]

ZOFE_extracted$crop <- ZOFE_extracted$crop_abr

ZOFE_extracted$treatment_en


ZOFE_extracted$crop_abr

WW <- ZOFE_extracted[ZOFE_extracted$crop_abr == "WW", ]
WW$crop_abr

#### Soil data

ZOFE_soil <- read_excel("soil data.xlsx", sheet = 1)  # sheet can be name or index

plot(ZOFE_soil$soil_0_20_Ntot)

names(ZOFE_soil)
ZOFE_soil$treatment_en
# View(ZOFE_soil)

column_titles_soil <- c(
  "year", "treatment_en", "crop", "soil_0_20_Ntot", "soil_0_20_P_test",
  "soil_0_20_K_test", "replicate", "treatment"
)

ZOFE_soil_extracted <- ZOFE_soil[, column_titles_soil, drop = FALSE]



ZOFE_combined <- inner_join(ZOFE_extracted, ZOFE_soil_extracted, 
                            by = c("treatment_en","year", 
                            "replicate", "treatment",
                            "crop" ))
ZOFE_WW <- ZOFE_combined[ZOFE_combined$crop_abr == "WW", ]
ZOFE_WW

names(ZOFE_WW)

ZOFE_WW <- ZOFE_WW %>%
  mutate(across(c("fert_Nmin_tot", "fert_Norg_tot", "fert_N_tot",
                  "fert_P_tot", "fert_K_tot", "fert_Mg_tot", 
                  "annual_N_uptake", "annual_P_uptake", "annual_K_uptake", "annual_Mg_uptake"
                  ), as.numeric))

str(ZOFE_WW)

# creation of DAG

# fert_Nmin_tot -> soil_0_20_Ntot -> annual_N_uptake -> annual_total_biomass_maincrop_DM
# fert_P_tot -> soil_0_20_P_test ->  annual_P_uptake -> annual_total_biomass_maincrop_DM
# fert_K_tot -> soil_0_20_K_test -> annual_K_uptake -> annual_total_biomass_maincrop_DM

###

# install.packages("dagitty")
# install.packages("lavaan") 
library(dagitty)
library(lavaan)
library(dplyr)

### create DAG

dag <- dagitty('dag {
bb="0,0,10,6"

fert_Nmin_tot [pos="1,5"]
soil_0_20_Ntot [pos="3,5"]
annual_N_uptake [pos="5,5"]

fert_P_tot [pos="1,3"]
soil_0_20_P_test [pos="3,3"]
annual_P_uptake [pos="5,3"]

fert_K_tot [pos="1,1"]
soil_0_20_K_test [pos="3,1"]
annual_K_uptake [pos="5,1"]

annual_total_biomass_maincrop_DM [pos="8,3"]

fert_Nmin_tot -> soil_0_20_Ntot
soil_0_20_Ntot -> annual_N_uptake
annual_N_uptake -> annual_total_biomass_maincrop_DM

fert_P_tot -> soil_0_20_P_test
soil_0_20_P_test -> annual_P_uptake
annual_P_uptake -> annual_total_biomass_maincrop_DM

fert_K_tot -> soil_0_20_K_test
soil_0_20_K_test -> annual_K_uptake
annual_K_uptake -> annual_total_biomass_maincrop_DM
}')

plot(dag)


# create SEM

vars_sem <- c(
  "fert_Nmin_tot",
  "soil_0_20_Ntot",
  "annual_N_uptake",
  "fert_P_tot",
  "soil_0_20_P_test",
  "annual_P_uptake",
  "fert_K_tot",
  "soil_0_20_K_test",
  "annual_K_uptake",
  "annual_total_biomass_maincrop_DM"
)

ZOFE_WW_sem <- ZOFE_WW %>%
  select(all_of(vars_sem)) %>%        # keep only variables used in the SEM
  mutate(across(everything(), scale)) # standardize variables to avoid scale problems

sem_model <- '

  soil_0_20_Ntot ~ fert_Nmin_tot
  # soil nitrogen is modeled as a function of nitrogen fertilization

  annual_N_uptake ~ soil_0_20_Ntot
  # crop nitrogen uptake is modeled as a function of soil nitrogen

  soil_0_20_P_test ~ fert_P_tot
  # soil phosphorus is modeled as a function of phosphorus fertilization

  annual_P_uptake ~ soil_0_20_P_test
  # crop phosphorus uptake is modeled as a function of soil phosphorus

  soil_0_20_K_test ~ fert_K_tot
  # soil potassium is modeled as a function of potassium fertilization

  annual_K_uptake ~ soil_0_20_K_test
  # crop potassium uptake is modeled as a function of soil potassium

  annual_total_biomass_maincrop_DM ~ annual_N_uptake +
                                     annual_P_uptake +
                                     annual_K_uptake
  # total main-crop biomass is modeled as a function of N, P and K uptake
'

fit <- sem(
  model = sem_model,
  data = ZOFE_WW_sem,
  missing = "fiml",  # use all available information despite missing values
  fixed.x = FALSE    # allows fertilizer variables to have missing values
)

summary(
  fit,
  standardized = TRUE, # show standardized coefficients
  fit.measures = TRUE, # show model fit indices
  rsquare = TRUE       # show explained variance for dependent variables
)

varTable(fit) # check whether variable variances/scales are reasonable


#### Remove soil as mediator:

sem_model2 <- '

  # Fertilization affects nutrient uptake
  annual_N_uptake ~ fert_Nmin_tot
  annual_P_uptake ~ fert_P_tot
  annual_K_uptake ~ fert_K_tot

  # Nutrient uptake affects biomass
  annual_total_biomass_maincrop_DM ~ annual_N_uptake +
                                      annual_P_uptake +
                                      annual_K_uptake

  # Fertilizer variables are allowed to correlate
  fert_Nmin_tot ~~ fert_P_tot
  fert_Nmin_tot ~~ fert_K_tot
  fert_P_tot ~~ fert_K_tot
'

fit2 <- sem(
  model = sem_model2,
  data = ZOFE_WW_sem,
  missing = "fiml",
  fixed.x = FALSE
)

summary(
  fit2,
  standardized = TRUE,
  fit.measures = TRUE,
  rsquare = TRUE
)




###################################################
### correlation plots
################################################


# N
plot (ZOFE_WW$fert_N_tot, ZOFE_WW$soil_0_20_Ntot)
ggplot (ZOFE_WW, aes (x = fert_N_tot, y = soil_0_20_Ntot)) + 
  geom_point () + 
  ggtitle ("N, fertilizer -> soil")

ggplot (ZOFE_WW, aes (x = soil_0_20_Ntot, y = annual_N_uptake)) + 
  geom_point () + 
  ggtitle ("N, soil -> plant")

ggplot (ZOFE_WW, aes (x = fert_N_tot, y = annual_N_uptake)) + 
  geom_point () + 
  ggtitle ("N, fertilizer -> plant")

ggplot (ZOFE_WW, aes (x = fert_N_tot, y = annual_total_biomass_maincrop_DM)) + 
  geom_point (aes (colour = treatment_en)) + 
  ggtitle ("N, fertilizer -> yield") 

# P

plot (ZOFE_WW$fert_P_tot, ZOFE_WW$soil_0_20_P_test)
ggplot (ZOFE_WW, aes (x = fert_P_tot, y = soil_0_20_P_test)) + 
  geom_point () + 
  ggtitle ("P, fertilizer -> soil")

ggplot (ZOFE_WW, aes (x = soil_0_20_P_test, y = annual_P_uptake)) + 
  geom_point () + 
  ggtitle ("P, soil -> plant")

ggplot (ZOFE_WW, aes (x = fert_P_tot, y = annual_P_uptake)) + 
  geom_point () + 
  ggtitle ("P, fertilizer -> plant")

ggplot (ZOFE_WW, aes (x = fert_P_tot, y = annual_total_biomass_maincrop_DM)) + 
  geom_point (aes (colour = treatment_en)) + 
  ggtitle ("P, fertilizer -> yield") 

# K

plot (ZOFE_WW$fert_K_tot, ZOFE_WW$soil_0_20_K_test)
ggplot (ZOFE_WW, aes (x = fert_K_tot, y = soil_0_20_K_test)) + 
  geom_point () + 
  ggtitle ("K, fertilizer -> soil")

ggplot (ZOFE_WW, aes (x = soil_0_20_K_test, y = annual_K_uptake)) + 
  geom_point () + 
  ggtitle ("K, soil -> plant")

ggplot (ZOFE_WW, aes (x = fert_K_tot, y = annual_K_uptake)) + 
  geom_point () + 
  ggtitle ("K, fertilizer -> plant")

ggplot (ZOFE_WW, aes (x = fert_K_tot, y = annual_total_biomass_maincrop_DM)) + 
  geom_point (aes (colour = treatment_en)) + 
  ggtitle ("K, fertilizer -> yield") 

names (ZOFE_WW)

# 

################################################
### Linear modelling
################################################



lm.yield <- lm (annual_total_biomass_maincrop_DM ~ fert_N_tot, data = ZOFE_WW)
summary(lm.yield)

lm.yield <- lm (annual_total_biomass_maincrop_DM ~ fert_N_tot * treatment , data = ZOFE_WW)
summary(lm.yield)

interaction.plot(
  x.factor = ZOFE_WW$fert_N_tot,
  trace.factor = ZOFE_WW$treatment,
  response = ZOFE_WW$annual_total_biomass_maincrop_DM,
  fun = mean,
  type = "b",
  col = 1:length(unique(ZOFE_WW$treatment)),
  pch = 19,
  xlab = "Total N fertilization",
  ylab = "Annual total biomass DM",
  trace.label = "Treatment"
)


lm.yield <- lm (annual_total_biomass_maincrop_DM ~ fert_Nmin_tot + fert_Norg_tot, data = ZOFE_WW)
summary(lm.yield)

lm.yield <- lm (annual_total_biomass_maincrop_DM ~ fert_N_tot + fert_P_tot + fert_K_tot, data = ZOFE_WW)
summary(lm.yield)

lm.yield <- lm (annual_total_biomass_maincrop_DM ~ fert_Nmin_tot + fert_P_tot + fert_K_tot, data = ZOFE_WW)
summary(lm.yield)


