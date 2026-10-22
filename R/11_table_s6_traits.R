# Table S6 (SI): species-mean trait values and their sources, formatted for Word
# Input:  output/tables/Table_S06_traits.csv (written by script 08), data/SpCodes.csv,
#         data/traits_rd_20250327.csv (functional type, growth form)
# Output: output/tables/Table_S06_traits.docx and .html

library(tidyverse)
library(here)
library(flextable)
library(officer)
source(here("R", "00_figure_setup.R"))  # leaf_habit_class()

traits <- read_csv(here("output", "tables", "Table_S06_traits.csv"), show_col_types = FALSE)
spp <- read_csv(here("data", "SpCodes.csv"), show_col_types = FALSE) %>%
  select(sp_code = SpCode6, Genus_species)
habit <- read_csv(here("data", "traits_rd_20250327.csv"), show_col_types = FALSE) %>%
  select(sp_code, functional_type, growth_form)
# species actually analysed (CEAMEG is in the trait sheet but has no LFM data)
analysed <- read_csv(here("data", "concept_df.csv"), show_col_types = FALSE) %>%
  distinct(species) %>% pull(species)

# Readable source labels; TRY values cite the database
source_label <- function(x) {
  case_when(
    x == "TRY" ~ "TRY database (Kattge et al. 2020)",
    str_detect(x, "^TRY \\(") ~ "TRY database (Kattge et al. 2020)",  # same TRY citation as the text
    TRUE ~ x
  )
}

trait_cols <- c("plc50_stem", "psi_tlp", "ldmc", "sla")
digits <- c(plc50_stem = 2, psi_tlp = 2, ldmc = 2, sla = 1)

tab <- traits %>%
  filter(sp_code %in% analysed) %>%
  left_join(spp, by = "sp_code") %>%
  left_join(habit, by = "sp_code") %>%
  mutate(across(all_of(paste0(trait_cols, "_source")), source_label),
         group = if_else(functional_type == "gymnosperm", "Gymnosperms", "Angiosperms"),
         group = factor(group, levels = c("Gymnosperms", "Angiosperms")),
         growth_form = str_to_sentence(growth_form),
         leaf_habit = leaf_habit_class(sp_code)) %>%
  arrange(group, Genus_species)

# Number sources in order of first appearance, reading across rows
src_long <- tab %>%
  select(sp_code, all_of(paste0(trait_cols, "_source"))) %>%
  pivot_longer(-sp_code, values_to = "source") %>%
  filter(!is.na(source))
src_key <- tibble(source = unique(src_long$source)) %>% mutate(n = row_number())

for (tr in trait_cols) {
  num <- src_key$n[match(tab[[paste0(tr, "_source")]], src_key$source)]
  tab[[paste0(tr, "_ref")]] <- if_else(is.na(num), "", as.character(num))
  tab[[paste0(tr, "_txt")]] <- if_else(is.na(tab[[tr]]), "–",
                                       formatC(tab[[tr]], format = "f", digits = digits[[tr]]) %>%
                                         str_replace("^-", "\u2212"))  # typographic minus
}

ft_df <- tab %>%
  transmute(group, species = Genus_species, sp_code, growth_form, leaf_habit,
            p50 = plc50_stem_txt, tlp = psi_tlp_txt, ldmc = ldmc_txt, sla = sla_txt,
            p50_ref = plc50_stem_ref, tlp_ref = psi_tlp_ref, ldmc_ref = ldmc_ref, sla_ref = sla_ref)

ft <- as_grouped_data(ft_df, groups = "group") %>%
  as_flextable(col_keys = c("species", "sp_code", "growth_form", "leaf_habit", "p50", "tlp", "ldmc", "sla"),
               hide_grouplabel = TRUE) %>%
  # value with its source number as a superscript
  compose(j = "p50",  value = as_paragraph(p50,  as_sup(p50_ref)),  i = ~ !is.na(species)) %>%
  compose(j = "tlp",  value = as_paragraph(tlp,  as_sup(tlp_ref)),  i = ~ !is.na(species)) %>%
  compose(j = "ldmc", value = as_paragraph(ldmc, as_sup(ldmc_ref)), i = ~ !is.na(species)) %>%
  compose(j = "sla",  value = as_paragraph(sla,  as_sup(sla_ref)),  i = ~ !is.na(species)) %>%
  set_header_labels(species = "Species", sp_code = "Code", growth_form = "Growth form",
                    leaf_habit = "Leaf habit") %>%
  compose(part = "header", j = "p50",  value = as_paragraph("P", as_sub("50"), " (MPa)")) %>%
  compose(part = "header", j = "tlp",  value = as_paragraph("Ψ", as_sub("TLP"), " (MPa)")) %>%
  compose(part = "header", j = "ldmc", value = as_paragraph("LDMC (g g", as_sup("−1"), ")")) %>%
  compose(part = "header", j = "sla",  value = as_paragraph("SLA (cm", as_sup("2"), " g", as_sup("−1"), ")")) %>%
  italic(j = "species", part = "body") %>%
  bold(i = ~ !is.na(group), part = "body") %>%
  bold(part = "header") %>%
  align(j = c("p50", "tlp", "ldmc", "sla"), align = "right", part = "all") %>%
  font(fontname = "Times New Roman", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  padding(padding.top = 1, padding.bottom = 1, part = "all") %>%
  line_spacing(space = 1, part = "all") %>%
  border_remove() %>%
  hline_top(border = fp_border(width = 1.2), part = "header") %>%
  hline_bottom(border = fp_border(width = 0.8), part = "header") %>%
  hline_bottom(border = fp_border(width = 1.2), part = "body") %>%
  add_footer_lines(paste0(
    "Superscript numbers give the source of each value: ",
    paste0(src_key$n, ", ", src_key$source, collapse = "; "),
    ". LDMC from Medeiros et al. (2025) is the mean of individuals at the named site nearest our study site. ",
    "Drought-deciduous species shed some or all leaves in summer drought (ERIFAS is semi-deciduous); ",
    "winter-deciduous species shed leaves in winter. ",
    "– indicates no value available.")) %>%
  fontsize(size = 9, part = "footer") %>%
  set_caption(as_paragraph(
    as_chunk("Table S6. ", props = fp_text_default(font.family = "Times New Roman", font.size = 11, bold = TRUE)),
    as_chunk("Species-mean trait values used in the trait analyses (Q3, Q4), with the source of each value.",
             props = fp_text_default(font.family = "Times New Roman", font.size = 11))),
    align_with_table = FALSE) %>%
  autofit()

ft

sect <- prop_section(page_size = page_size(orient = "landscape"),
                     page_margins = page_mar(left = 0.75, right = 0.75, top = 0.75, bottom = 0.75))
save_as_docx(ft, path = here("output", "tables", "Table_S06_traits.docx"), pr_section = sect)
# htmltools route: flextable::save_as_html() needs pandoc
htmltools::save_html(htmltools_value(ft), file = here("output", "tables", "Table_S06_traits.html"))
