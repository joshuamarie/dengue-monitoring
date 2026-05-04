box::use(
    shiny[
        NS, tagList, div, hr, icon,
        uiOutput, moduleServer, reactive,
        renderUI, tags, sliderInput
    ],
    bslib[card, card_header, card_body],
    DT[DTOutput],
    dplyr[keep_when = filter],
    ../modeling[compute_metrics],
    ./info/kpi,
    mt = ./info/metrics_table,
    mtsb = ./info/metrics_table_sb
)

# ---- Sidebar compact view (homepage) ----
metrics_ui = function(id) {
    ns = NS(id)
    tagList(
        tags$div(
            class = "sidebar-metrics-header",
            tags$h6(
                icon("chart-bar"), " National Summary",
                class = "sidebar-section-title"
            ),
            tags$p("All regions · 2018–2025", class = "sidebar-section-sub")
        ),
        uiOutput(ns("kpi_boxes_sidebar")),
        hr(style = "margin: 12px 0;"),
        tags$h6(
            icon("table"), " Regional Summary (latest year)",
            class = "sidebar-section-title"
        ),
        uiOutput(ns("region_table_compact"))
    )
}

# ---- Full metrics page ----
metrics_detail_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "map-timeline",
            sliderInput(
                ns("year_detail"),
                label = NULL,
                min = 2018, max = 2025,
                value = c(2018, 2025),
                step = 1, sep = "", ticks = TRUE, width = "100%"
            )
        ),
        uiOutput(ns("kpi_boxes_detail")),
        card(
            card_header(
                class = "module-card-header",
                icon("table"), " Regional Summary (latest year)"
            ),
            card_body(DTOutput(ns("region_table")))
        )
    )
}

# ---- Shared server ----
metrics_server = function(id, national_ts, region_ts, year_range = NULL) {
    moduleServer(id, function(input, output, session) {
        yr = reactive({
            if (!is.null(year_range)) year_range() else input$year_detail
        })

        filtered_national_ts = reactive({
            df = national_ts()
            # y = yr()
            if (!is.null(yr()) && length(yr()) == 2)
                df = df |> keep_when(year >= yr()[1] & year <= yr()[2])
            df
        })

        filtered_region_ts = reactive({
            df = region_ts()
            # y = yr()
            if (!is.null(yr()) && length(yr()) == 2)
                df = df |> keep_when(year >= yr()[1] & year <= yr()[2])
            df
        })

        metrics = reactive({ compute_metrics(filtered_national_ts()) })

        output$kpi_boxes_sidebar = renderUI({
            kpi$kpi_value_boxes(metrics(), col_widths = c(6, 6, 6, 6), yr = yr())
        })

        output$kpi_boxes_detail = renderUI({
            kpi$kpi_value_boxes(metrics(), col_widths = c(3, 3, 3, 3), yr = yr())
        })

        mt$render_metrics_table(output, filtered_region_ts)
        mtsb$render_metrics_table_sb(output, filtered_region_ts)
    })
}
