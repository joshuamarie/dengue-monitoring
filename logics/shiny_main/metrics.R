box::use(
    shiny[
        NS, tagList, div, h4, h5, p, hr, strong, span,
        uiOutput, tableOutput, moduleServer, reactive,
        renderUI, renderTable
    ],
    dplyr[select, arrange, desc, keep_when = filter, mutate],
    ../modeling[compute_metrics, classify_risk],
)

metrics_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Key Epidemiological Metrics"),
            p("National summary across all years", class = "module-subtitle")
        ),
        uiOutput(ns("kpi_row")),
        hr(),
        h5("Regional Summary (latest year)"),
        tableOutput(ns("region_table"))
    )
}

metrics_server = function(id, national_ts, region_ts) {
    moduleServer(id, function(input, output, session) {

        metrics = reactive({
            compute_metrics(national_ts())
        })

        output$kpi_row = renderUI({
            m = metrics()

            growth_icon = if (!is.na(m$growth_pct) && m$growth_pct > 0) "▲" else "▼"
            growth_color = if (!is.na(m$growth_pct) && m$growth_pct > 0) "#e5383b" else "#2dc653"

            div(
                class = "kpi-row",
                kpi_card(
                    "Latest Year Cases",
                    format(m$latest_cases, big.mark = ","), "#1565c0"
                ),
                kpi_card(
                    "Year-on-Year Change",
                    span(
                        growth_icon, abs(m$growth_pct), "%",
                        style = paste0("color:", growth_color)
                    ),
                    "#e65100", raw = TRUE
                ),
                kpi_card(
                    "Peak Year",
                    paste0(
                        m$peak_year, " (", format(m$peak_cases, big.mark = ","), " cases)"
                    ),
                    "#1b5e20"
                ),
                kpi_card(
                    "Total Cases (2018-2025)",
                    format(m$total_all_years, big.mark = ","), "#4e342e"
                )
            )
        })

        output$region_table = renderTable(
            {
                latest_year = max(region_ts()$year)
                region_ts() |>
                    keep_when(year == latest_year) |>
                    mutate(risk = classify_risk(incidence_rate)) |>
                    select(
                        Region = region_name,
                        Cases = cases,
                        `Incidence (per 100,000)` = incidence_rate,
                        Risk = risk
                    ) |>
                    arrange(desc(Cases))
            },
            striped = TRUE,
            hover = TRUE,
            bordered = TRUE
        )
    })
}

# Helper: single KPI card
kpi_card = function(label, value, accent, raw = FALSE) {
    val_ui = if (raw) value else strong(value)
    div(
        class = "kpi-card",
        style = paste0("border-top: 4px solid ", accent, ";"),
        div(class = "kpi-value", val_ui),
        div(class = "kpi-label", label)
    )
}
