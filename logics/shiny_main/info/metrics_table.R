box::use(
    shiny[renderUI],
    DT[renderDT, datatable, DTOutput, styleEqual, formatStyle],
    ./region_summary[compute_region_summary]
)

#' Full DT table for the Metrics tab.
#' @param output The Shiny output object from the parent module server.
#' @param filtered_region_ts Reactive returning a filtered regional data frame.
render_metrics_table = function(output, filtered_region_ts) {
    output$region_table = renderDT({
        df = compute_region_summary(filtered_region_ts()) |>
            dplyr::mutate(
                Cases = scales::comma(Cases)
                # `Incidence (per 100,000)` = {
                #     percent_hundreds = scales::label_percent(accuracy = 0.01)
                #     percent_hundreds(`Incidence (per 100,000)` / 100)
                # }
            )
        datatable(
            df,
            extensions = c('SearchPanes', 'Select', 'Buttons'),
            rownames = FALSE,
            options = list(
                dom = 'PBfrtip',
                columnDefs = list(
                    list(searchPanes = list(show = TRUE),  targets = 0),
                    list(searchPanes = list(show = FALSE), targets = c(1, 2, 3)),
                    list(targets = 0, className = 'noVis')
                ),
                searchPanes = list(initCollapsed = TRUE),
                buttons = list(
                    list(
                        extend = 'colvis',
                        text = 'Columns',
                        columns = c(1, 2, 3)
                    )
                )
            ),
            selection = 'none'
        ) |>
            formatStyle(
                "Risk",
                backgroundColor = styleEqual(
                    c("Low", "Medium", "High"),
                    c("#d4edda", "#fff3cd", "#f8d7da")
                )
            )
    }, server = FALSE)
}
