box::use(
    shiny[
        NS, tagList, div, h4, p, tags, reactive,
        radioButtons, sliderInput, moduleServer
    ],
    dplyr[keep_when = filter, group_by, summarise, left_join, mutate, ungroup, rowwise],
    ggiraph[girafeOutput, renderGirafe],
    mp = ./plots/map
)

# ---- UI ----
map_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Regional Risk Map"),
            p(
                "Color intensity = selected metric per region",
                class = "module-subtitle"
            )
        ),
        div(
            style = "position: relative;",

            ### ---- Floating metric toggle ----
            div(
                class = "map-filter-panel",
                radioButtons(
                    ns("metrics"),
                    label = "Metric:",
                    choices = c(
                        "Case Count" = "cases",
                        "Incidence Rate (per 100,000)" = "incidence_rate"
                    ),
                    selected = "cases",
                    inline = FALSE
                )
            ),

            ### ---- Map ----
            girafeOutput(ns("mapping"), height = "500px"),

            ### ---- Year slider ----
            div(
                class = "map-timeline",
                sliderInput(
                    ns("year"),
                    label = NULL,
                    min = 2018,
                    max = 2025,
                    value = c(2018, 2025),
                    step = 1,
                    sep = "",
                    ticks = TRUE,
                    width = "100%"
                )
            )
        )
    )
}

# ---- Server ----
map_server = function(id, region_ts, ph_regions, regions_meta) {
    moduleServer(id, function(input, output, session) {

        ## ---- Aggregate region_ts over selected year range ----
        map_df = reactive({
            region_ts() |>
                keep_when(.data$year >= input$year[1], .data$year <= input$year[2]) |>
                group_by(.data$region_code, .data$region_name) |>
                summarise(
                    cases = sum(.data$cases, na.rm = TRUE),
                    population = mean(.data$population, na.rm = TRUE),
                    .groups = "drop"
                ) |>
                mutate(
                    incidence_rate = round(cases / population * 100000, 2)
                ) |>
                left_join(regions_meta, by = "region_code") |>
                left_join(ph_regions, by = "region_code") |>
                rowwise() |>
                mutate(
                    areas_html = paste0(
                        "\u2022 ", areas, collapse = "<br/>"
                    )
                ) |>
                ungroup()
        })

        ## ---- ggiraph map ----
        ## Call `regional_map()` from the imported
        ## `./plots/map` as `mp`
        output$mapping = renderGirafe({
            mp$regional_map(map_df(), input$metrics)
        })

        list(
            year_range = reactive({ input$year }),
            metric = reactive({ input$metrics }),
            hovered = reactive({ input$mapping_hovered })
        )
    })
}
