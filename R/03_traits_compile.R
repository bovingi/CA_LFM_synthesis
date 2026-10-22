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


medeiros_site_map <- tribble(
  ~study       , ~Site          , ~site_rank ,
  "Pepperwood" , "Angelo Coast" ,          1 ,
  "StuntRanch" , "Stunt Ranch"  ,          1 ,
  "Sedgwick"   , "Stunt Ranch"  ,          1 ,
  "SEKI"       , "Yosemite"     ,          1 ,
  "SEKI"       , "Onion Creek"  ,          2
)

species_studies <- read_csv(here("data", "all-data-combined.csv")) %>%
  distinct(sp_code = Species, study)

ldmc_medeiros <- read_csv(here(
  "data",
  "other_studies",
  "Medeiros_Simplification_of_woody_plant_trait_networks_among_communities_along_a_climatic_aridity_gradient_individualTraits.csv"
)) %>%
  filter(LDMC_g.g.1 < 1) %>%
  inner_join(
    SpCodes %>%
      select(sp_code = SpCode6, Genus_species) %>%
      filter(!is.na(sp_code)),
    by = c("Species" = "Genus_species")
  ) %>%
  inner_join(
    species_studies %>%
      inner_join(
        medeiros_site_map,
        by = "study",
        relationship = "many-to-many"
      ),
    by = c("sp_code", "Site"),
    relationship = "many-to-many"
  ) %>%
  group_by(sp_code) %>%
  filter(site_rank == min(site_rank)) %>%
  distinct(sp_code, Site, Individual, LDMC_g.g.1) %>%
  summarise(
    ldmc_med = mean(LDMC_g.g.1, na.rm = T),
    ldmc_sites = paste(unique(Site), collapse = "+"),
    .groups = "drop"
  )

ldmc_try_spp <- c("QUEDOU", "QUEDUR")
ldmc_fletcher_spp <- c("CEAMEG", "CEACUN")

# QUEKEL (not in Medeiros): Boving et al. 2025b pressure-volume curves (SEKI), LDMC =
# dry / saturated fresh mass, mean of 8 curves (Oct 2020, Sep 2021). Broadleaf, so no
# shoot-vs-leaf issue as for the conifer PV samples.
ldmc_pv_quke <- read_csv(
  here("data", "other_studies", "sierra_pv_curves_clean_boving2025b.csv"),
  show_col_types = FALSE
) %>%
  filter(
    spp == "QUKE",
    !is.na(fresh_weight_saturated),
    !is.na(dry_weight),
    fresh_weight_saturated > 0
  ) %>%
  distinct(date, sample, fresh_weight_saturated, dry_weight) %>%
  summarise(ldmc = mean(dry_weight / fresh_weight_saturated)) %>%
  pull(ldmc)

traits_compiled_df <- traits_compiled_df %>%
  left_join(ldmc_medeiros, by = "sp_code") %>%
  mutate(
    ldmc_source = case_when(
      sp_code %in% ldmc_fletcher_spp & !is.na(ldmc) ~ "Fletcher et al. 2018",
      !is.na(ldmc_med) ~ paste0("Medeiros et al. 2025 (", ldmc_sites, ")"),
      sp_code %in%
        ldmc_try_spp &
        !is.na(ldmc) ~ "TRY (Dahlin et al. 2013; dry/fresh mass)",
      sp_code == "QUEKEL" ~ "Boving et al. 2025b (PV curves)",
      TRUE ~ NA_character_
    ),
    ldmc = case_when(
      sp_code %in% ldmc_fletcher_spp ~ ldmc,
      !is.na(ldmc_med) ~ ldmc_med,
      sp_code %in% ldmc_try_spp ~ ldmc,
      sp_code == "QUEKEL" ~ ldmc_pv_quke,
      TRUE ~ NA_real_
    )
  ) %>%
  select(-ldmc_med, -ldmc_sites)

# --- SLA for CALDEC: Madsen-Hepp et al. (Dryad), mean of individual means (cm2/g) ---
# Medeiros LMA gives 92-103 cm2/g and FATES (Law & Berner 2015) 64 cm2/g, but both sources'
# conifer SLAs run 1.6-3.6x the TRY/Boving values used for our other conifers (likely a
# different leaf-area basis for scale and needle leaves). Swapping the previous sheet value
# (25.99) for Madsen-Hepp changes no model ranking or Q3 conclusion.
sla_mh_caldec <- read_csv(
  here("data", "other_studies", "dryad_leaftraits_medson_hepp.csv"),
  show_col_types = FALSE
) %>%
  filter(code == "CALDEC") %>%
  group_by(rep) %>%
  summarise(sla = mean(SLA, na.rm = TRUE)) %>%
  summarise(sla = mean(sla)) %>%
  pull(sla)

traits_compiled_df <- traits_compiled_df %>%
  mutate(
    sla_source = NA_character_,
    sla = if_else(sp_code == "CALDEC", sla_mh_caldec, sla)
  )

# --- Sources for P50, TLP, SLA ---
# Values are TRY means unless listed here (from the "Reference if not TRY" columns
# of species-traits-withseki.csv, which pair references and traits as free text).
non_try_sources <- tribble(
  ~sp_code , ~trait       , ~source                      ,
  "ABICON" , "psi_tlp"    , "Boving et al. 2025b"        ,
  "ABICON" , "sla"        , "Boving et al. 2025b"        ,
  "ARBMEN" , "plc50_stem" , "Chacon et al. 2020"         ,
  "CALDEC" , "sla"        , "Madsen-Hepp et al. (Dryad)" ,
  "CEACOR" , "sla"        , "Knight & Ackerly 2001"      ,
  "CEACUN" , "psi_tlp"    , "Fletcher et al. 2018"       ,
  "CEACUN" , "sla"        , "Fletcher et al. 2018"       ,
  "CEAMEG" , "psi_tlp"    , "Fletcher et al. 2018"       ,
  "CEAMEG" , "sla"        , "Fletcher et al. 2018"       ,
  "PSEMEN" , "plc50_stem" , "Condo & Reinhardt 2019"     ,
  "QUEAGR" , "psi_tlp"    , "Chacon et al. 2020"         ,
  "QUEDOU" , "psi_tlp"    , "Allen et al. in prep."      ,
  "QUEGAR" , "psi_tlp"    , "John et al. 2018"           ,
  "UMBCAL" , "psi_tlp"    , "John et al. 2018"
) %>%
  pivot_wider(
    names_from = trait,
    values_from = source,
    names_glue = "{trait}_source"
  )

traits_compiled_df <- traits_compiled_df %>%
  rows_patch(
    non_try_sources %>%
      select(sp_code, sla_source) %>%
      filter(!is.na(sla_source)),
    by = "sp_code",
    unmatched = "ignore"
  ) %>%
  left_join(non_try_sources %>% select(-sla_source), by = "sp_code") %>%
  mutate(
    plc50_stem_source = case_when(
      !is.na(plc50_stem_source) ~ plc50_stem_source,
      !is.na(plc50_stem) ~ "TRY"
    ),
    psi_tlp_source = case_when(
      !is.na(psi_tlp_source) ~ psi_tlp_source,
      !is.na(psi_tlp) ~ "TRY"
    ),
    sla_source = case_when(!is.na(sla_source) ~ sla_source, !is.na(sla) ~ "TRY")
  )

rd_df <- read_csv(here(
  "data",
  "other_studies",
  "Plant_Rooting_Depth_Database_20210525_update_sheet2.csv"
)) %>%
  clean_names() %>%
  select(scientific_name, max_rooting_depth_m) %>%
  mutate(Genus_species = scientific_name) %>%
  merge(., SpCodes, by = c("Genus_species")) %>%
  select(SpCode6, 3, 4) %>%
  mutate(
    min_or_max = case_when(
      max_rooting_depth_m %in% c("> 2.45") ~ "min",
      max_rooting_depth_m %in% c("> 2.74") ~ "min",
      max_rooting_depth_m %in% c("> 1.52") ~ "min",
      max_rooting_depth_m %in% c("> 1.22") ~ "min",
      max_rooting_depth_m %in% c(">4") ~ "min",
      max_rooting_depth_m %in% c("> 0.61") ~ "min",
      TRUE ~ "max"
    )
  ) %>%
  mutate(
    max_rooting_depth_m = case_when(
      max_rooting_depth_m %in% c("> 2.45") ~ 2.45,
      max_rooting_depth_m %in% c("> 2.74") ~ 2.74,
      max_rooting_depth_m %in% c("> 1.52") ~ 1.52,
      max_rooting_depth_m %in% c("> 1.22") ~ 1.22,
      max_rooting_depth_m %in% c(">4") ~ 4,
      max_rooting_depth_m %in% c("> 0.61") ~ 0.61,
      TRUE ~ as.numeric(max_rooting_depth_m)
    )
  ) %>%
  rename(sp_code = SpCode6) %>%
  group_by(sp_code) %>%
  mutate(max_rooting_depth_m = max(max_rooting_depth_m, na.rm = T)) %>%
  mutate(
    max_rooting_depth_m = case_when(
      max_rooting_depth_m %in% c(-Inf) ~ NA,
      TRUE ~ as.numeric(max_rooting_depth_m)
    )
  ) %>%
  select(-min_or_max) %>%
  distinct() %>%
  ungroup()

traits_rd_df <- merge(
  rd_df,
  traits_compiled_df,
  by = c("sp_code"),
  all.y = T
) %>%
  select(-dr_max_rooting_depth)

write_csv(traits_rd_df, here("data", "traits_rd_20250327.csv"))

# --- TRY database summary (all species) ---

try_all <- read.csv(here('data', 'try_all_20241014.csv')) %>%
  select(SpeciesName, OriglName, StdValue) %>%
  filter(
    OriglName %in%
      c(
        "P50",
        "P88",
        "LDMC",
        "Pmin predawn (Mpa)",
        "Pmin midday (Mpa)",
        "SLA (cm2 g-1)",
        "Water potential at 50% loss of conductivity Psi_50 (MPa)",
        "P50 (MPa)",
        "P88 (MPa)",
        "SLA",
        "LMA (g/m2)"
      )
  ) %>%
  mutate(
    trait_name = case_when(
      OriglName %in%
        c(
          "P50",
          "Water potential at 50% loss of conductivity Psi_50 (MPa)",
          "P50 (MPa)"
        ) ~ "P50",
      OriglName %in% c("P88", "P88 (MPa)") ~ "P88",
      OriglName %in% c("SLA (cm2 g-1)") ~ "SLA (cm2 g-1)",
      OriglName %in% c("SLA") ~ "SLA",
      TRUE ~ OriglName
    )
  ) %>%
  select(-OriglName) %>%
  distinct() %>%
  mutate(
    SpeciesName = str_replace_all(SpeciesName, "_", " "),
    Genus_species = stringr::word(SpeciesName, 1, 2)
  ) %>%
  group_by(Genus_species, trait_name) %>%
  mutate(tsd = sd(StdValue, na.rm = T), tmn = mean(StdValue, na.rm = T)) %>%
  select(-StdValue) %>%
  distinct() %>%
  pivot_wider(names_from = c(trait_name), values_from = c(tmn, tsd)) %>%
  merge(SpCodes %>% select(SpCode6, Genus_species)) %>%
  select(-SpeciesName) %>%
  rename_with(~ str_remove(., "tmn_")) %>%
  group_by(Genus_species, SpCode6) %>%
  fill(c(2:15), .direction = "downup") %>%
  distinct()
