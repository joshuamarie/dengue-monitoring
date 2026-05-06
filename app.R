box::use(
    shiny[
        tags, div, span, p, reactive, shinyApp, HTML, icon
    ],
    bslib[
        page_navbar, nav_panel, nav_spacer, nav_item,
        sidebar, layout_sidebar, input_dark_mode,
        card, card_header, card_body,
        layout_columns
    ],
    dplyr[filter, mutate],

    ./logics/geo[load_ph_regions],
    ./logics/regions_meta[REGIONS_META],
    ./logics/data_simulation[simulate_dengue_data],
    ./logics/modeling[classify_risk],

    ./logics/shiny_main/map,
    ./logics/shiny_main/trends,
    ./logics/shiny_main/risk,
    ./logics/shiny_main/metrics,
    ./logics/shiny_main/about,

    ./themes/app[app_theme]
)

SIM_DATA = simulate_dengue_data(seed = 123)
PH_REGIONS = load_ph_regions()

# ---- UI ----
ui = page_navbar(
    title = tags$span(
        tags$img(
            src = "images/doh-logo.jpg",
            style = "margin-right: 8px; width: 37px; height: 24px; vertical-align: middle;"
        ),
        tags$span(
            "Dengue Early Warning & Surveillance System",
            class = "app-title"
        ),
        tags$img(
            src = "images/pagasa-logo.png",
            style = "margin-right: 8px; width: 30px; height: 30px; vertical-align: middle;"
        ),
        tags$span(
            tags$span(class = "badge-live", "LIVE"),
            style = "margin-left: 12px;"
        )
    ),
    theme = app_theme,
    id = "main_tabs",
    # bg = "#0d1b2a",
    # inverse = TRUE,
    # collapsible = TRUE,
    navbar_options = bslib::navbar_options(
        bg = "#0d1b2a",
        underline = TRUE,
        collapsible = TRUE
    ),
    header = tags$head(
        tags$link(
            rel = "stylesheet",
            type = "text/css",
            href = "styles.css"
        ),
        tags$script(src = "map-drag.js")
    ),
    footer = tags$div(
        class = "app-footer",
        "Built with R Shiny + bslib  |  Modular architecture  |  Epidemiological modeling  |  Philippines Dengue Surveillance Demo"
    ),

    ### ---- Tab 1: Map ----
    nav_panel(
        title = tags$span(icon("map"), " Overview"),
        value = "map_tab",
        layout_sidebar(
            fillable = TRUE,
            sidebar = sidebar(
                width = 340,
                open = "always",
                metrics$metrics_ui("metrics_sidebar")
            ),
            map$map_ui("map")
        )
    ),

    ### ---- Tab 2: Trends ----
    nav_panel(
        title = tags$span(icon("chart-line"), " Trends"),
        value = "trends_tab",
        div(
            class = "main-content",
            card(
                full_screen = TRUE,
                card_header(class = "module-card-header", "Epidemiological Trends"),
                card_body(trends$trends_ui("trends"))
            )
        )
    ),

    ### ---- Tab 3: Risk ----
    nav_panel(
        title = tags$span(icon("triangle-exclamation"), " Risk"),
        value = "risk_tab",
        div(
            class = "main-content",
            card(
                full_screen = TRUE,
                card_header(class = "module-card-header", "Risk Prediction"),
                card_body(risk$risk_ui("risk"))
            )
        )
    ),

    ### ---- Tab 4: Metrics ----
    nav_panel(
        title = tags$span(icon("table-cells"), " Metrics"),
        value = "metrics_tab",
        div(
            class = "main-content",
            metrics$metrics_detail_ui("metrics_detail")
        )
    ),

    ### ---- Tab 5: About ----
    nav_panel(
        title = tags$span(icon("circle-info"), " About"),
        value = "about_tab",
        about$about_ui("about")
    ),

    ## ---- Right side: dark mode toggle ----
    nav_spacer(),
    nav_item(
        tags$span(
            class = "app-subtitle d-none d-md-inline",
            "Philippines  |  All Regions  |  2018–2025",
            style = "margin-right: 12px; opacity: 0.7; font-size: 0.78rem;"
        )
    ),
    nav_item(
        input_dark_mode(id = "color_mode", mode = "light")
    )
)

# ---- Server ----
server = function(input, output, session) {
    national_ts = reactive({ SIM_DATA$national })
    region_ts = reactive({ SIM_DATA$regional })

    ## ---- Server modules wire-ups ----

    ### ---- "Map" server ----
    map_filters = map$map_server(
        "map",
        region_ts = region_ts,
        ph_regions = PH_REGIONS,
        regions_meta = REGIONS_META
    )
    ### ---- "Trends" server ----
    trends$trends_server("trends", national_ts = national_ts, region_ts = region_ts)
    ### ---- "Risk" server ----
    risk$risk_server("risk", national_ts = national_ts)
    ### ---- "Metrics" server ----
    metrics$metrics_server(
        "metrics_sidebar",
        national_ts = national_ts,
        region_ts = region_ts,
        year_range = map_filters$year_range
    )
    metrics$metrics_server(
        "metrics_detail",
        national_ts = national_ts,
        region_ts = region_ts,
        year_range = NULL
    )
}

shinyApp(ui, server)
