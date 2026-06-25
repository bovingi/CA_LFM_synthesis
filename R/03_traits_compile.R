# NOTE: This script requires data/try_all_20241014.csv (~31 MB, TRY Plant Trait Database)
# which is not included in this repository due to size and licensing restrictions.
# The output (data/traits_rd_20250327.csv) is included pre-built.
# To regenerate, obtain TRY data from https://www.try-db.org/ and place it
# in data/try_all_20241014.csv, then run this script.

library(tidyverse)
library(here)
library(janitor)

SpCodes <- read_csv(here("data", "SpCodes.csv"))

# --- Compile traits with rooting depth ---

traits_compiled_df <- read_csv(here("data", "species-traits-withseki.csv")) %>%
  clean_names() %>%
  mutate(species = sp_code)

rd_df <- read_csv(here("data", "other_studies",
                       "Plant_Rooting_Depth_Database_20210525_update_sheet2.csv")) %>%
  clean_names() %>%
  select(scientific_name, max_rooting_depth_m) %>%
  mutate(Genus_species = scientific_name) %>%
  merge(., SpCodes, by = c("Genus_species")) %>%
  select(SpCode6, 3, 4) %>%
  mutate(min_or_max = case_when(
    max_rooting_depth_m %in% c("> 2.45") ~ "min",
    max_rooting_depth_m %in% c("> 2.74") ~ "min",
    max_rooting_depth_m %in% c("> 1.52") ~ "min",
    max_rooting_depth_m %in% c("> 1.22") ~ "min",
    max_rooting_depth_m %in% c(">4")     ~ "min",
    max_rooting_depth_m %in% c("> 0.61") ~ "min",
    TRUE ~ "max"
  )) %>%
  mutate(max_rooting_depth_m = case_when(
    max_rooting_depth_m %in% c("> 2.45") ~ 2.45,
    max_rooting_depth_m %in% c("> 2.74") ~ 2.74,
    max_rooting_depth_m %in% c("> 1.52") ~ 1.52,
    max_rooting_depth_m %in% c("> 1.22") ~ 1.22,
    max_rooting_depth_m %in% c(">4")     ~ 4,
    max_rooting_depth_m %in% c("> 0.61") ~ 0.61,
    TRUE ~ as.numeric(max_rooting_depth_m)
  )) %>%
  rename(sp_code = SpCode6) %>%
  group_by(sp_code) %>%
  mutate(max_rooting_depth_m = max(max_rooting_depth_m, na.rm = T)) %>%
  mutate(max_rooting_depth_m = case_when(
    max_rooting_depth_m %in% c(-Inf) ~ NA,
    TRUE ~ as.numeric(max_rooting_depth_m)
  )) %>%
  select(-min_or_max) %>%
  distinct() %>%
  ungroup()

traits_rd_df <- merge(rd_df, traits_compiled_df, by = c("sp_code"), all.y = T) %>%
  select(-dr_max_rooting_depth)

write_csv(traits_rd_df, here("data", "traits_rd_20250327.csv"))

# --- TRY database summary (all species) ---

try_all <- read.csv(here('data', 'try_all_20241014.csv')) %>%
  select(SpeciesName, OriglName, StdValue) %>%
  filter(OriglName %in% c("P50", "P88", "LDMC", "Pmin predawn (Mpa)", "Pmin midday (Mpa)",
                           "SLA (cm2 g-1)", "Water potential at 50% loss of conductivity Psi_50 (MPa)",
                           "P50 (MPa)", "P88 (MPa)", "SLA", "LMA (g/m2)")) %>%
  mutate(trait_name = case_when(
    OriglName %in% c("P50", "Water potential at 50% loss of conductivity Psi_50 (MPa)", "P50 (MPa)") ~ "P50",
    OriglName %in% c("P88", "P88 (MPa)") ~ "P88",
    OriglName %in% c("SLA (cm2 g-1)") ~ "SLA (cm2 g-1)",
    OriglName %in% c("SLA") ~ "SLA",
    TRUE ~ OriglName
  )) %>%
  select(-OriglName) %>%
  distinct() %>%
  mutate(SpeciesName = str_replace_all(SpeciesName, "_", " "),
         Genus_species = stringr::word(SpeciesName, 1, 2)) %>%
  group_by(Genus_species, trait_name) %>%
  mutate(tsd = sd(StdValue, na.rm = T),
         tmn = mean(StdValue, na.rm = T)) %>%
  select(-StdValue) %>%
  distinct() %>%
  pivot_wider(names_from = c(trait_name),
              values_from = c(tmn, tsd)) %>%
  merge(SpCodes %>% select(SpCode6, Genus_species)) %>%
  select(-SpeciesName) %>%
  rename_with(~ str_remove(., "tmn_")) %>%
  group_by(Genus_species, SpCode6) %>%
  fill(c(2:15), .direction = "downup") %>%
  distinct()
