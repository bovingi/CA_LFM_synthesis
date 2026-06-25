rm(list = ls())
library(here)

# --- Oct 2021 data ---
lw <- read.csv(
  here("data", "raw", "PWD_Oct2021_LFM_WP_Final.csv"),
  na.strings = c("", "NA")
)

names(lw)[1] <- 'Site'
lw$Sampling <- 'Oct21'
lw <- lw[c('Site', 'Species', 'Sample.number', 'Sampling', 'Alternate.number',
           'DBH', 'Height', 'Date', 'Predawn.mean', 'Midday.mean',
           'Bulk.wet', 'Bulk.dry', 'Bulk.change',
           'Leaf.wet', 'Leaf.dry', 'Leaf.change',
           'Stem.wet', 'Stem.dry', 'Stem.change')]

# For plants where leaves and stems were separated in the field,
# calculate bulk values from stem + leaf
nobulk <- which(is.na(lw$Bulk.change))
lw$Bulk.wet[nobulk]    <- lw$Leaf.wet[nobulk] + lw$Stem.wet[nobulk]
lw$Bulk.dry[nobulk]    <- lw$Leaf.dry[nobulk] + lw$Stem.dry[nobulk]
lw$Bulk.change[nobulk] <- lw$Bulk.wet[nobulk] - lw$Bulk.dry[nobulk]

# --- Jun 2022 data ---
lw2 <- read.csv(
  here("data", "raw", "PWD_JUN2022_LFM_Final.csv"),
  na.strings = c("", "NA")
)

names(lw2)[1] <- 'Site'
lw2$Sampling <- 'Jun22'
names(lw2)[which(names(lw2) == 'Wet.wt')]  <- 'Bulk.wet'
names(lw2)[which(names(lw2) == 'Dry.wt')]  <- 'Bulk.dry'
names(lw2)[which(names(lw2) == 'Change')]  <- 'Bulk.change'
lw2 <- lw2[, c('Site', 'Species', 'Sample.number', 'Sampling', 'Alternate.number',
               'DBH', 'Height', 'Date', 'Predawn.mean', 'Midday.mean',
               'Bulk.wet', 'Bulk.dry', 'Bulk.change')]

lw2$Leaf.wet    <- NA
lw2$Leaf.dry    <- NA
lw2$Leaf.change <- NA
lw2$Stem.wet    <- NA
lw2$Stem.dry    <- NA
lw2$Stem.change <- NA

# Reverse sign of water potentials in June data
lw2$Predawn.mean <- (-1) * lw2$Predawn.mean
lw2$Midday.mean  <- (-1) * lw2$Midday.mean

stopifnot(all(names(lw) == names(lw2)))

lw <- rbind(lw, lw2)

# Calculate Live Fuel Moisture: LFM = water weight / dry weight
lw$Leaf.LFM <- lw$Leaf.change / lw$Leaf.dry
lw$Stem.LFM <- lw$Stem.change / lw$Stem.dry
lw$Bulk.LFM <- lw$Bulk.change / lw$Bulk.dry

# Predawn-midday differential
lw$WPdiff <- lw$Midday.mean - lw$Predawn.mean

write.csv(lw, here("data", "PWD_Oct2021+Jun2022_LFM_WP_Calcs.csv"))
