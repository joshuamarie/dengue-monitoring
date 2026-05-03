box::use(
    shiny[icon, p],
    bslib[value_box, layout_columns],
    glue[f_string = glue]
)

kpi_value_boxes = function(m, col_widths, yr) {
    growth_pos = !is.na(m$growth_pct) && m$growth_pct > 0

    layout_columns(
        col_widths = col_widths,
        fill = FALSE,
        gap = "8px",

        value_box(
            title = "Latest year cases",
            value = format(m$latest_cases, big.mark = ","),
            showcase = icon("users"),
            theme = "primary"
        ),

        value_box(
            title = "Year-on-year change",
            value = paste0(if (growth_pos) "▲ " else "▼ ", abs(m$growth_pct), "%"),
            showcase = icon(if (growth_pos) "arrow-trend-up" else "arrow-trend-down"),
            theme = if (growth_pos) "danger" else "success"
        ),

        value_box(
            title = "Peak year",
            value = as.character(m$peak_year),
            p(format(m$peak_cases, big.mark = ","), " cases recorded"),
            showcase = icon("calendar-days"),
            theme = "warning"
        ),

        value_box(
            title = f_string("Cumulative burden ({yr[1]}–{yr[2]})"),
            value = format(m$total_all_years, big.mark = ","),
            p("total reported cases"),
            showcase = icon("circle-exclamation"),
            theme = "secondary"
        )
    )
}
