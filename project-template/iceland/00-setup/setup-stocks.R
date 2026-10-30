## Stocks: immature and mature sub-stocks, or a single stock (single_stock_model)

if (single_stock_model) {
  single_stock <- g3_stock(c(species = tolower(species_name)), seq({{MINLENGTH}}, {{MAXLENGTH}}, {{LENGTH_BIN}})) |>
    g3s_livesonareas(areas[c("1")]) |>
    g3s_age(minage = {{MINAGE}}, maxage = {{MAXAGE}})
  stocks <- list(single_stock)
} else {
  imm_stock <- g3_stock(c(species = tolower(species_name), "imm"), seq({{IMM_MINLENGTH}}, {{IMM_MAXLENGTH}}, {{LENGTH_BIN}})) |>
    g3s_livesonareas(areas[c("1")]) |>
    g3s_age(minage = {{IMM_MINAGE}}, maxage = {{IMM_MAXAGE}})
  mat_stock <- g3_stock(c(species = tolower(species_name), "mat"), seq({{MAT_MINLENGTH}}, {{MAT_MAXLENGTH}}, {{LENGTH_BIN}})) |>
    g3s_livesonareas(areas[c("1")]) |>
    g3s_age(minage = {{MAT_MINAGE}}, maxage = {{MAT_MAXAGE}})
  stocks <- list(imm_stock, mat_stock)
}
