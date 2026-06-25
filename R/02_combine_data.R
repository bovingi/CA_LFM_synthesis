rm(list = ls())
library(dplyr)
library(tidyr)
library(lubridate)
library(here)

spc <- read.csv('data/SpCodes.csv')

# --- Pepperwood ---
lw <- read.csv('data/PWD_Oct2021+Jun2022_LFM_WP_Calcs.csv', as.is = T) %>%
  mutate(date = ymd(Date))
lw$SpCode6 <- spc$SpCode6[match(lw$Species, spc$Pepperwood.spp)]

# --- Stunt Ranch (SoCal, Pivovaroff) ---
p <- read.csv('data/other_studies/Pivovaroff_WP_vs_LFM.csv', as.is = T) %>%
  mutate(date = mdy(Date))
p$SpCode6 <- spc$SpCode6[match(p$Species, spc$SoCal.spp)]
p$lfm <- p$LFM_. / 100

# --- Sierra (SEKI) ---
m <- read.csv('data/other_studies/sierra_lfm_mpa.csv') %>%
  mutate(date = ymd(date))
m$SpCode6 <- spc$SpCode6[match(m$Species, spc$SEKI.spp)]
m$lfm <- m$lfm / 100

# --- Sedgwick ---
s <- read.csv('data/other_studies/sedgwick_22_lfm_mpa_df20230724.csv') %>%
  mutate(date = ymd(date_lfm)) %>%
  filter(time == "md")
s$SpCode6 <- spc$SpCode6[match(s$species, spc$Sedgwick.spp)]
s$lfm <- s$lfm_percent / 100
s$mpa_mean <- -s$mpa_mean

# --- Standardize columns and combine ---
lwx <- lw[, c('SpCode6', 'date', 'Midday.mean', 'Bulk.LFM')]
names(lwx) <- c('Species', 'date', 'mwp', 'lfm')
lwx$study <- 'Pepperwood'

px <- p[, c('SpCode6', 'date', 'WP_md_MPa', 'lfm')]
names(px) <- c('Species', 'date', 'mwp', 'lfm')
px$study <- 'StuntRanch'

mx <- m[, c('SpCode6', 'date', 'water_potential', 'lfm', 'tissue_age')]
names(mx) <- c('Species', 'date', 'mwp', 'lfm', 'tissue_age')
mx$study <- 'SEKI'

sx <- s[, c('SpCode6', 'date', 'mpa_mean', 'lfm')]
names(sx) <- c('Species', 'date', 'mwp', 'lfm')
sx$study <- 'Sedgwick'

lwa <- bind_rows(lwx, px, mx, sx)
lwa$Sp.Site <- paste(lwa$Species, lwa$study, sep = "_")

lwa <- lwa[complete.cases(lwa[, c('mwp', 'lfm')]), ]
lwa <- lwa[-which(is.na(lwa$Species)), ]

write.csv(lwa, here('data', 'all-data-combined.csv'))

# --- Predawns (includes predawn + midday WP) ---

m <- read.csv('data/other_studies/sierra_lfm_mpa_withpredawns.csv') %>%
  mutate(date = ymd(date))
m$SpCode6 <- spc$SpCode6[match(m$Species, spc$SEKI.spp)]
m$lfm <- m$lfm / 100

s <- read.csv('data/other_studies/sedgwick_22_lfm_mpa_df20230724.csv') %>%
  mutate(date = ymd(date_lfm))
s$SpCode6 <- spc$SpCode6[match(s$species, spc$Sedgwick.spp)]
s$lfm <- s$lfm_percent / 100
s$mpa_mean <- -s$mpa_mean

lw <- read.csv('data/PWD_Oct2021+Jun2022_LFM_WP_Calcs.csv', as.is = T) %>%
  mutate(date = ymd(Date)) %>%
  pivot_longer(cols = c("Predawn.mean", "Midday.mean"),
               names_to = "time",
               values_to = "water_potential")
lw$SpCode6 <- spc$SpCode6[match(lw$Species, spc$Pepperwood.spp)]

lwx <- lw[, c('SpCode6', 'date', 'water_potential', 'time', 'Bulk.LFM')]
names(lwx) <- c('Species', 'date', 'wp', 'time', 'lfm')
lwx$study <- 'Pepperwood'

mx <- m[, c('SpCode6', 'date', 'water_potential', 'time', 'lfm', 'tissue_age')]
names(mx) <- c('Species', 'date', 'wp', 'time', 'lfm', 'tissue_age')
mx$study <- 'SEKI'

sx <- s[, c('SpCode6', 'date', 'mpa_mean', 'time', 'lfm')]
names(sx) <- c('Species', 'date', 'wp', 'time', 'lfm')
sx$study <- 'Sedgwick'

lwa <- bind_rows(lwx, mx, sx)
lwa$Sp.Site <- paste(lwa$Species, lwa$study, sep = "_")

lwa <- lwa[complete.cases(lwa[, c('wp', 'lfm')]), ]
lwa <- lwa[-which(is.na(lwa$Species)), ]

lwa <- lwa %>%
  mutate(time = case_when(
    time %in% c("Predawn.mean", "predawn", "pd") ~ "pd",
    time %in% c("Midday.mean", "midday", "md")   ~ "md",
  ))

write.csv(lwa, here('data', 'all-data-combined-predawns.csv'))
