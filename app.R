box::use(
    # ---- Essential namespaces ----
    shiny[
        fluidPage, tags, tabsetPanel, tabPanel, br,
        div, span, p, reactive, shinyApp, HTML
    ],
    dplyr[filter, mutate],

    # ---- Data and modelling ----
    ./logics/data_simulation[simulate_dengue_data],
    ./logics/modeling[classify_risk],

    # ---- Main Shiny interface logics ----
    ./logics/shiny_main/map,
    ./logics/shiny_main/trends,
    ./logics/shiny_main/risk,
    ./logics/shiny_main/metrics,
)


SIM_DATA = simulate_dengue_data()

ui = fluidPage(
    tags$head(
        tags$title("Dengue Surveillance | Philippines"),
        tags$link(
            rel = "stylesheet",
            type = "text/css",
            href = "styles.css"
        )
    ),

    # ---- Navigation bar ----
    div(
        class = "top-nav",
        span("🦟"),
        div(
            p("Dengue Early Warning & Surveillance System", class = "app-title"),
            p("Philippines  |  All Regions  |  2018-2025  |  Simulated Data", class = "app-subtitle")
        ),
        span(class = "badge-live", "LIVE")
    ),

    # ---- Main content ----
    div(
        class = "main-content",
        ## ---- Tabset ----
        tabsetPanel(
            id = "main_tabs",

            ### ---- Tab 1: Map ----
            tabPanel(
                "Map",
                br(),
                div(
                    class = "module-card",
                    map$map_ui("map")
                )
            ),

            ### ---- Tab 2: Trends ----
            tabPanel(
                "Trends",
                br(),
                div(
                    class = "module-card",
                    trends$trends_ui("trends")
                )
            ),

            ### ---- Tab 3: Risk Prediction ----
            tabPanel(
                "Risk",
                br(),
                div(
                    class = "module-card",
                    risk$risk_ui("risk")
                )
            ),

            ### ---- Tab 4: Metrics ----
            tabPanel(
                "Metrics",
                br(),
                div(
                    class = "module-card",
                    metrics$metrics_ui("metrics")
                )
            )
        ),

        div(
            class = "app-footer",
            "Built with R Shiny  |  Modular architecture  |  Epidemiological modeling  |  Philippines Dengue Surveillance Demo"
        )
    )
)

server = function(input, output, session) {

    national_ts = reactive({
        SIM_DATA$national
    })

    region_ts = reactive({
        SIM_DATA$regional
    })

    # Wire up modules
    map$map_server("map", region_ts = region_ts)
    trends$trends_server("trends", national_ts = national_ts, region_ts = region_ts)
    risk$risk_server("risk", national_ts = national_ts)
    metrics$metrics_server("metrics", national_ts = national_ts, region_ts = region_ts)
}

shinyApp(ui, server)
