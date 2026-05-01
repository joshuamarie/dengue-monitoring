box::use(
    shiny[
        NS, tagList, div, h5, h6, p, hr, strong, span, icon,
        uiOutput, tableOutput, moduleServer, reactive,
        renderUI, renderTable, tags, sliderInput, req
    ],
    bslib[
        value_box, layout_columns, card, card_header, card_body
    ],
    dplyr[select, arrange, desc, keep_when = filter, mutate, group_by, summarise],
    ../modeling[compute_metrics, classify_risk],
    glue[glue],
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
            card_body(tableOutput(ns("region_table")))
        )
    )
}

# ---- Shared server ----
metrics_server = function(id, national_ts, region_ts, year_range = NULL) {
    moduleServer(id, function(input, output, session) {

        filtered_national_ts = reactive({
            df = national_ts()
            yr = if (!is.null(year_range)) year_range() else input$year_detail
            if (!is.null(yr) && length(yr) == 2)
                df = df |> keep_when(year >= yr[1] & year <= yr[2])
            df
        })

        metrics = reactive({ compute_metrics(filtered_national_ts()) })

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
                    title = glue("Cumulative burden ({yr[1]}–{yr[2]})"),
                    value = format(m$total_all_years, big.mark = ","),
                    p("total reported cases"),
                    showcase = icon("circle-exclamation"),
                    theme = "secondary"
                )
            )
        }

        ## ---- KPI boxes: sidebar (2x2) ----
        output$kpi_boxes_sidebar = renderUI({
            kpi_value_boxes(metrics(), col_widths = c(6, 6, 6, 6), yr = if (!is.null(year_range)) year_range() else c(2018, 2025))
        })

        ## ---- KPI boxes: detail page (4-in-a-row) ----
        output$kpi_boxes_detail = renderUI({
            yr = if (!is.null(year_range)) year_range() else input$year_detail
            kpi_value_boxes(metrics(), col_widths = c(3,3,3,3), yr = yr)
        })

        filtered_region_ts = reactive({
            df = region_ts()
            yr = if (!is.null(year_range)) year_range() else input$year_detail
            if (!is.null(yr) && length(yr) == 2)
                df = df |> keep_when(year >= yr[1] & year <= yr[2])
            df
        })

        ## ---- Full table (Metrics tab) ----
        output$region_table = renderTable(
            {
                filtered_region_ts() |>
                    group_by(region_name) |>
                    summarise(
                        cases = sum(cases, na.rm = TRUE),
                        incidence_rate = round(
                            sum(cases, na.rm = TRUE) /
                                sum(population, na.rm = TRUE) *
                                100000,
                            1
                        )
                    ) |>
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
            bordered = TRUE,
            width = "100%"
        )

        ## ---- Compact table (sidebar) ----
        output$region_table_compact = renderUI({
            df = filtered_region_ts() |>
                group_by(region_name) |>
                summarise(
                    cases = sum(cases, na.rm = TRUE),
                    incidence_rate = round(
                        sum(cases, na.rm = TRUE) /
                            sum(population, na.rm = TRUE) *
                            100000,
                        1
                    )
                ) |>
                mutate(risk = classify_risk(incidence_rate)) |>
                select(
                    Region = region_name,
                    Cases = cases,
                    Risk = risk
                ) |>
                arrange(desc(Cases))

            risk_badge = function(r) {
                cls = switch(r, Low = "success", Medium = "warning", High = "danger", "secondary")
                tags$span(class = paste0("badge text-bg-", cls), r)
            }

            rows = lapply(seq_len(nrow(df)), function(i) {
                tags$tr(
                    tags$td(df$Region[i], style = "font-size:0.78rem;"),
                    tags$td(format(df$Cases[i], big.mark = ","), style = "font-size:0.78rem; text-align:right;"),
                    tags$td(risk_badge(df$Risk[i]), style = "text-align:center;")
                )
            })

            tags$table(
                class = "table table-sm table-hover table-bordered compact-table",
                style = "font-size:0.78rem;",
                tags$thead(
                    class = "table-dark",
                    tags$tr(
                        tags$th("Region"),
                        tags$th("Cases", style = "text-align:right;"),
                        tags$th("Risk", style = "text-align:center;")
                    )
                ),
                tags$tbody(rows)
            )
        })
    })
}
