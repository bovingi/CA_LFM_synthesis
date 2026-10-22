library(ggplot2)
library(here)

dir.create(here("output", "figures", "main"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "figures", "SI"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# Custom ggplot wrapper with clean theme
ggplot <- function(...) {
  ggplot2::ggplot(...) +
    theme(
      panel.background = element_rect(fill = 'white', colour = 'black'),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "white")
    )
}

theme_minimal <- theme_minimal() +
  theme(
    panel.background = element_rect(fill = 'white', colour = 'black'),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "white")
  )

th <- theme(
  panel.background = element_rect(fill = 'white', colour = 'black'),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank()
)

# --- Species color palettes (used across Q1–Q4) ---

color_species <- scale_color_manual(
  values = c(
    ABICON = "#17154f",
    ADEFAS = "#2f357c",
    ARBMEN = "#6c5d9e",
    ARCGLA = "#9d9cd5",
    ARCPAT = "#b0799a",
    CALDEC = "#59385c",
    CEACUN = "#f6b3b0",
    CEACOR = "#f6b3e0",
    CEAPAR = "#b38711",
    CEASPI = "#e48171",
    CERBET = "#d8b847",
    ERIFAS = "#bf3729",
    HETARB = "#e69b00",
    MALLAU = "#f5bb50",
    PINJEF = "#ada43b",
    PSEMEN = "#355828",
    QUEAGR = "#5b859e",
    QUEBER = "#1e395f",
    QUEDOU = "#75884b",
    QUEDUR = "#1e5a46",
    QUEGAR = "#df8d71",
    QUEKEL = "#af4f2f",
    SALLEU = "#d48f90",
    SALMEL = "#732f30",
    UMBCAL = "#46a39a"
  ),
  drop = FALSE
)

color_genus_species <- scale_color_manual(
  values = c(
    "Abies concolor"              = "#17154f",
    "Adenostoma fasciculatum"     = "#2f357c",
    "Arbutus menziesii"           = "#6c5d9e",
    "Arctostaphylos glandulosa"   = "#9d9cd5",
    "Arctostaphylos patula"       = "#b0799a",
    "Calocedrus decurrens"        = "#59385c",
    "Ceanothus cordulatus"        = "#f6b3e0",
    "Ceanothus cuneatus"          = "#f6b3b0",
    "Ceanothus parryi"            = "#b38711",
    "Ceanothus spinosus"          = "#e48171",
    "Cercocarpus betuloides"      = "#d8b847",
    "Eriogonum fasciculatum"      = "#bf3729",
    "Heteromeles arbutifolia"     = "#e69b00",
    "Malosma laurina"             = "#f5bb50",
    "Pinus jeffreyi"              = "#ada43b",
    "Pseudotsuga menziesii"       = "#355828",
    "Quercus agrifolia"           = "#5b859e",
    "Quercus berberidifolia"      = "#1e395f",
    "Quercus douglasii"           = "#75884b",
    "Quercus durata"              = "#1e5a46",
    "Quercus garryana"            = "#df8d71",
    "Quercus kelloggii"           = "#af4f2f",
    "Salvia leucophylla"          = "#d48f90",
    "Salvia mellifera"            = "#732f30",
    "Umbellularia californica"    = "#46a39a"
  ),
  drop = FALSE
)

# --- Site / study palettes ---

color_fill <- scale_fill_manual(
  values = c("#B9C7E2", "#ECAB99", "#5B6530", "#9484B1", "#F1C100")
)

color_fill_site <- scale_fill_manual(
  values = c("#B9C7E2", "#ECAB99", "#5B6530", "#9484B1", "#F1C100")
)

color <- scale_color_manual(
  values = c("#ECAB99", "#5B6530", "#9484B1", "#F1C100")
)

color_line_site <- scale_color_manual(
  values = c("#c969a1", "#ce4441", "#ee8577", "#eb7926", "#ffbb44",
             "#859b6c", "#62929a", "#004f63", "#122456")
)

color_line_size <- scale_color_manual(
  values = c("#004f63", "#62929a")
)

Cross <- list(c("#c969a1", "#ce4441", "#ee8577", "#eb7926", "#ffbb44",
                "#859b6c", "#62929a", "#004f63", "#122456"))

# --- Leaf habit (deciduous species split by phenology; used in Q1-Q3 and Table S6) ---

winter_dec_spp  <- c("QUEDOU", "QUEGAR", "QUEKEL")
drought_dec_spp <- c("SALLEU", "SALMEL", "ERIFAS")  # summer-deciduous / semi-deciduous

leaf_habit_class <- function(sp) {
  dplyr::case_when(
    sp %in% winter_dec_spp  ~ "Winter-deciduous",
    sp %in% drought_dec_spp ~ "Drought-deciduous",
    TRUE ~ "Evergreen"
  )
}

# Colorblind-safe: distinct under simulated deutan/protan/tritan vision (min dE 39)
# and in greyscale (dark / light / mid lightness)
color_leaf_habit <- c(
  "Evergreen"         = "#00441B",
  "Winter-deciduous"  = "#E69F00",
  "Drought-deciduous" = "#9970AB"
)
