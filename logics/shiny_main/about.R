box::use(
    shiny[NS, tagList, div, icon, tags, HTML, moduleServer],
    bslib[card, card_header, card_body],
)

# ---- UI ----
about_ui = function(id) {
    ns = NS(id)
    div(
        class = "main-content",
        card(
            card_header(class = "module-card-header", "About this app"),
            card_body(
                tags$p(
                    class = "lead",
                    "A modular R Shiny application for dengue outbreak monitoring across all 17 Philippine regions, covering 2018–2025."
                ),
                tags$hr(),
                tags$h5("Modelling approach"),
                tags$p(HTML(
                    "A lagged OLS regression model is fitted on the national yearly time series:<br><br>
                    <code>ŷ(t) = β₀ + β₁ · rainfall(t−1) + β₂ · temp_anomaly(t) + ε</code><br><br>
                    The one-year lag on rainfall reflects the biological lifecycle of <em>Aedes aegypti</em>:
                    elevated rainfall expands breeding sites, and the resulting increase in mosquito density
                    translates into elevated case counts in the following transmission season."
                )),
                tags$hr(),
                tags$h5("Data sources (simulated)"),
                tags$table(
                    class = "table table-sm table-bordered",
                    tags$thead(tags$tr(tags$th("Field"), tags$th("Suggested real source"))),
                    tags$tbody(
                        tags$tr(tags$td("Cases"), tags$td("DOH Philippines Epidemiology Bureau")),
                        tags$tr(tags$td("Rainfall index"), tags$td("PAGASA / NOAA GPCC")),
                        tags$tr(tags$td("Temperature anomaly"), tags$td("PAGASA / NASA GISS")),
                        tags$tr(tags$td("Region coordinates"), tags$td("PSA / NAMRIA"))
                    )
                ),
                tags$hr(),
                tags$p(
                    tags$strong("Note: "),
                    "All case counts, rainfall indices, and temperature anomalies are procedurally generated and do not represent official recordings."
                ),
                tags$p(tags$a(
                    href = "https://github.com/joshuamarie/dengue-monitoring",
                    icon("github"), " View on GitHub",
                    target = "_blank"
                ))
            )
        )
    )
}

# ---- Server ----
about_server = function(id) {
    moduleServer(id, function(input, output, session) {
        # ...static page — no server logic needed...
    })
}
