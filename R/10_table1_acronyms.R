# Table 1 (main text): acronyms, symbols, and abbreviations used in the manuscript
# Outputs: output/figures/main/Table1_acronyms.csv and .html

library(tidyverse)
library(here)
library(kableExtra)

table1 <- tribble(
  ~Category, ~Abbreviation, ~Definition, ~Units,
  # --- Fuel moisture and water status ---
  "Fuel moisture and water status", "LFM", "Live fuel moisture: mass of water as a percentage of tissue dry mass", "%",
  "Fuel moisture and water status", "iLFM", "Inverse live fuel moisture (1/LFM)", "g dry mass g⁻¹ water",
  "Fuel moisture and water status", "LFMmax", "Maximum LFM: LFM predicted at Ψ = 0 MPa, the reciprocal of the species iLFM–ΨMD intercept (Eq. 3)", "%",
  "Fuel moisture and water status", "LFMmin", "Minimum observed LFM for a species", "%",
  "Fuel moisture and water status", "Max. observed LFM", "Highest LFM measured for a species", "%",
  "Fuel moisture and water status", "Slope", "Species slope of iLFM against ΨMD", "MPa⁻¹",
  "Fuel moisture and water status", "Ψ", "Water potential", "MPa",
  "Fuel moisture and water status", "ΨMD", "Midday water potential", "MPa",
  "Fuel moisture and water status", "Ψmin", "Species minimum midday water potential", "MPa",
  # --- Plant traits ---
  "Plant traits", "P50", "Stem water potential at 50% loss of hydraulic conductivity", "MPa",
  "Plant traits", "ΨTLP (TLP)", "Leaf water potential at turgor loss point", "MPa",
  "Plant traits", "SLA", "Specific leaf area: leaf area per unit dry mass", "cm² g⁻¹",
  "Plant traits", "LDMC", "Leaf dry matter content: leaf dry mass per unit saturated fresh mass", "g g⁻¹"
)

dir.create(here("output", "figures", "main"), showWarnings = FALSE, recursive = TRUE)
write_csv(table1, here("output", "figures", "main", "Table1_acronyms.csv"))

# HTML for copy/pasting into Word, grouped by category
subscript <- function(x) {
  x %>%
    str_replace_all("Ψ(MD|min|TLP)", "Ψ<sub>\\1</sub>") %>%
    str_replace_all("LFM(max|min)", "LFM<sub>\\1</sub>") %>%
    str_replace_all("\\bP50\\b", "P<sub>50</sub>")
}

pub_table <- table1 %>%
  select(-Category) %>%
  mutate(across(c(Abbreviation, Definition), subscript)) %>%
  kable(format = "html", escape = FALSE, align = "lll",
        caption = "Table 1. Acronyms, symbols, and abbreviations used in the text.") %>%
  kable_styling(bootstrap_options = c("striped", "condensed"), full_width = FALSE, position = "left") %>%
  pack_rows(index = table(fct_inorder(table1$Category)))

tryCatch(save_kable(pub_table, file = here("output", "figures", "main", "Table1_acronyms.html")),
         error = function(e) message("Note: HTML table skipped (pandoc not available)"))
