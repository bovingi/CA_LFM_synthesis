# SI sensitivity: gymnosperm LFM–Ψ relationships with all tissue vs current-year foliage only
# Supports Discussion L515–519 ("constraining our analysis to current year foliage ...")
# SEKI conifers (ABICON, CALDEC, PINJEF) were sampled as new and old tissue separately;
# PSEMEN (Pepperwood) is mixed tissue only, so it appears unchanged in both fits.
# Outputs: output/figures/SI/unused_conifer_new_tissue_fits.jpg
#          output/figures/SI/Fig_S11_conifer_new_tissue_slopes.jpg (SI Fig S11)
#          output/tables/Table_S_conifer_new_tissue.csv

library(tidyverse)
library(here)
library(lme4)
library(emmeans)
library(patchwork)

source(here("R", "00_figure_setup.R"))

gymno_spp <- c("ABICON", "CALDEC", "PINJEF", "PSEMEN")

df1 <- read_csv(here("data", "df1.csv"), show_col_types = FALSE) %>%
  mutate(group = if_else(species %in% gymno_spp, "Gymnosperm", "Angiosperm"))

# New-tissue dataset: drop old gymnosperm foliage; angiosperms unchanged
# (SEKI ARCPAT and CEACOR also have old tissue but are not part of this sensitivity)
df_new <- df1 %>% filter(!(group == "Gymnosperm" & tissue_age == "old"))

datasets <- list("All tissue" = df1, "Current-year only" = df_new)
data_cols <- c("All tissue" = "grey45", "Current-year only" = "#1B7837")

# ---- Species fits (iLFM ~ Ψ, per gymnosperm) ----
sp_fits <- imap_dfr(datasets, function(d, nm) {
  d %>%
    filter(species %in% gymno_spp) %>%
    group_by(species) %>%
    group_modify(~ {
      m <- lm(ilfm ~ mwp, data = .x)
      ci <- confint(m)["mwp", ]
      tibble(slope = coef(m)[["mwp"]], lo = ci[[1]], hi = ci[[2]],
             r2 = summary(m)$r.squared,
             p = summary(m)$coefficients["mwp", 4], n = nrow(.x))
    }) %>%
    ungroup() %>%
    mutate(data = nm)
})

# ---- Common gymnosperm slope (same model as Table S5) ----
grp_slopes <- imap_dfr(datasets, function(d, nm) {
  m <- lmer(ilfm ~ mwp * group + (1 | species), data = d, REML = TRUE)
  summary(emtrends(m, ~ group, var = "mwp", lmer.df = "satterthwaite")) %>%
    as_tibble() %>%
    transmute(group, slope = mwp.trend, lo = lower.CL, hi = upper.CL, data = nm)
})

out_tab <- bind_rows(
  sp_fits %>% mutate(level = "Species"),
  grp_slopes %>% rename(species = group) %>% mutate(level = "Group (common slope)")
) %>%
  select(level, species, data, slope, lo, hi, r2, p, n)
write_csv(out_tab, here("output", "tables", "Table_S_conifer_new_tissue.csv"))
print(out_tab, n = Inf)

# ---- Figure A: species scatter with both fits (LFM %, back-transformed) ----
pts <- df1 %>%
  filter(species %in% gymno_spp) %>%
  mutate(tissue = case_when(tissue_age == "new" ~ "Current-year",
                            tissue_age == "old" ~ "Previous years",
                            TRUE ~ "Mixed"),
         tissue = factor(tissue, levels = c("Current-year", "Previous years", "Mixed")))

lines_df <- imap_dfr(datasets, function(d, nm) {
  d %>%
    filter(species %in% gymno_spp) %>%
    group_by(species) %>%
    group_modify(~ {
      m <- lm(ilfm ~ mwp, data = .x)
      grid <- tibble(mwp = seq(min(.x$mwp), max(.x$mwp), length.out = 100))
      mutate(grid, lfm_pred = 100 / predict(m, grid))
    }) %>%
    ungroup() %>%
    mutate(data = nm)
})

lab_df <- sp_fits %>%
  mutate(lab = sprintf("%s: slope %.2f, R² %.2f", if_else(data == "All tissue", "All", "Current-yr"), slope, r2)) %>%
  group_by(species) %>%
  summarise(lab = paste(lab, collapse = "\n"))

figA <- ggplot(pts, aes(x = mwp, y = lfm * 100)) +
  geom_point(aes(shape = tissue, fill = tissue), size = 1.8, alpha = 0.7, colour = "grey20", stroke = 0.3) +
  geom_line(data = lines_df, aes(y = lfm_pred, colour = data, linetype = data), linewidth = 0.9) +
  geom_text(data = lab_df, aes(label = lab), x = -Inf, y = Inf, hjust = -0.04, vjust = 1.2,
            size = 3, lineheight = 0.95, inherit.aes = FALSE) +
  facet_wrap(~ species, scales = "free_x", nrow = 1) +
  scale_shape_manual(values = c("Current-year" = 24, "Previous years" = 21, "Mixed" = 22), name = "Tissue") +
  scale_fill_manual(values = c("Current-year" = "#A6DBA0", "Previous years" = "grey55", "Mixed" = "white"), name = "Tissue") +
  scale_colour_manual(values = data_cols, name = "Fit") +
  scale_linetype_manual(values = c("All tissue" = "dashed", "Current-year only" = "solid"), name = "Fit") +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.25))) +
  labs(x = expression(Psi[MD]~"(MPa)"), y = "LFM (%)") +
  theme(legend.position = "bottom", legend.box = "vertical", legend.key = element_blank(),
        strip.text = element_text(face = "bold"),
        strip.background = element_blank())

ggsave(here("output", "figures", "SI", "unused_conifer_new_tissue_fits.jpg"),
       figA, width = 11, height = 4.5, dpi = 300)

# ---- Figure B: slope comparison (species and common gymnosperm slope) ----
slope_df <- bind_rows(
  sp_fits %>% select(species, data, slope, lo, hi),
  grp_slopes %>% filter(group == "Gymnosperm") %>%
    transmute(species = "Common\n(gymnosperms)", data, slope, lo, hi)
) %>%
  mutate(species = factor(species, levels = rev(c(gymno_spp, "Common\n(gymnosperms)"))))

figB <- ggplot(slope_df, aes(x = slope, y = species, colour = data)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_hline(yintercept = 1.5, colour = "grey80") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(width = 0.5), size = 0.4) +
  scale_colour_manual(values = data_cols, name = NULL) +
  labs(x = expression("Slope of iLFM vs."~Psi[MD]~"(MPa"^-1*")"), y = NULL) +
  theme(legend.position = "bottom", legend.key = element_blank())

ggsave(here("output", "figures", "SI", "Fig_S11_conifer_new_tissue_slopes.jpg"),
       figB, width = 6, height = 4.5, dpi = 300)
