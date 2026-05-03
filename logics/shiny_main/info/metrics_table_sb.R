box::use(
    shiny[renderUI, tags],
    ./region_summary[compute_region_summary]
)

#' Compact sidebar table for the Overview tab.
#' @param output The Shiny output object from the parent module server.
#' @param filtered_region_ts Reactive returning a filtered regional data frame.
render_metrics_table_sb = function(output, filtered_region_ts) {
    output$region_table_compact = renderUI({
        df = compute_region_summary(filtered_region_ts()) |>
            dplyr::select(Region, Cases, Risk)

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
                    tags$th("Risk",  style = "text-align:center;")
                )
            ),
            tags$tbody(rows)
        )
    })
}
