box::use(
    shiny[observe, isTruthy],
    DT[datatable, renderDT, dataTableProxy, selectRows],
    dplyr[select, mutate, case_when],
    ./region_summary[compute_region_summary]
)

#' Compact sidebar table for the Overview tab.
#' @param output The Shiny output object from the parent module server.
#' @param session The Shiny session object from the parent module server.
#' @param filtered_region_ts Reactive returning a filtered regional data frame.
#' @param metric Reactive input of chosen metrics.
#' @param hovered Reactive returning the hovered region code from the map.
render_metrics_table_sb = function(output, session, filtered_region_ts, metric = NULL, hovered = NULL) {
    output$region_table_compact = renderDT({
        df = compute_region_summary(filtered_region_ts())
        use_incidence = !is.null(metric) && metric() == "incidence_rate"

        df = if (use_incidence) {
            select(df, Region, `Incidence (per 100,000)`, Risk) |>
                mutate(`Incidence (per 100,000)` = format(`Incidence (per 100,000)`, nsmall = 1))
        } else {
            select(df, Region, Cases, Risk) |>
                mutate(Cases = format(Cases, big.mark = ","))
        }

        df$Risk = case_when(
            df$Risk == "Low" ~ '<span class="badge text-bg-success">Low</span>',
            df$Risk == "Medium" ~ '<span class="badge text-bg-warning">Medium</span>',
            df$Risk == "High" ~ '<span class="badge text-bg-danger">High</span>',
            TRUE ~ df$Risk
        )

        datatable(
            df,
            rownames = FALSE,
            escape = FALSE,
            selection = list(mode = "single", style = "highlight"),
            options = list(
                dom = "t",
                ordering = FALSE,
                pageLength = nrow(df),
                columnDefs = list(
                    list(className = "dt-right", targets = 1),
                    list(className = "dt-center", targets = 2)
                )
            )
        )
    })

    observe({
        if (is.null(hovered)) return()

        proxy = dataTableProxy("region_table_compact", session = session)

        code = hovered()
        if (!isTruthy(code)) {
            selectRows(proxy, NULL)
            return()
        }

        df = compute_region_summary(filtered_region_ts())
        row_idx = which(df$region_code == code)
        selectRows(proxy, row_idx)
    })
}
