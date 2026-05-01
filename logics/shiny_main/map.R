box::use(
    shiny[
        NS, tagList, div, h4, p, tags, reactive,
        radioButtons, sliderInput, moduleServer
    ],
    dplyr[keep_when = filter, group_by, summarise, left_join, mutate, ungroup, rowwise],
    ggplot2[
        ggplot, aes, geom_sf, scale_fill_gradient2,
        theme_void, theme, element_text, element_rect,
        element_blank, labs, coord_sf
    ],
    ggiraph[
        geom_sf_interactive, girafe, girafe_options,
        opts_hover, opts_hover_inv, opts_toolbar,
        opts_sizing, opts_zoom,
        girafeOutput, renderGirafe
    ],
    scales[label_comma],
    stats[median]
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
                    ns("metric"),
                    label = NULL,
                    choices = c(
                        "Case Count"                  = "cases",
                        "Incidence Rate (per 100,000)" = "incidence_rate"
                    ),
                    selected = "cases"
                )
            ),

            ### ---- Map ----
            girafeOutput(ns("map"), height = "500px"),

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
                keep_when(year >= input$year[1], year <= input$year[2]) |>
                group_by(region_code, region_name) |>
                summarise(
                    cases = sum(cases, na.rm = TRUE),
                    population = mean(population, na.rm = TRUE),
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

        ## ---- Render ggiraph map ----
        output$map = renderGirafe({
            df = map_df()
            metric = input$metric
            label = if (metric == "cases") "Cases" else "Incidence\n(per 100k)"
            fmt_val = if (metric == "cases") label_comma() else label_comma(accuracy = 0.01)

            p = ggplot(df) +
                geom_sf_interactive(
                    aes(
                        geometry = geometry,
                        fill = .data[[metric]],
                        tooltip = paste0(
                            "<b style='font-size:1rem;'>", region_name, "</b><br/>",
                            "<span style='font-size:0.78rem; opacity:0.7;'>",
                            area_label, "</span><br/>",
                            areas_html, "<br/><br/>",
                            "<b>", label, ":</b> ", fmt_val(round(.data[[metric]], 2))
                        ),
                        data_id = region_code
                    ),
                    color = "#ffffff",
                    linewidth = 0.4
                ) +
                scale_fill_gradient2(
                    low = "#2dc653",
                    mid = "#f4a11d",
                    high = "#e5383b",
                    midpoint = median(df[[metric]], na.rm = TRUE),
                    name = label,
                    labels = fmt_val
                ) +
                coord_sf(expand = FALSE, clip = "on") +
                theme_void() +
                theme(
                    legend.position = "right",
                    legend.title = element_text(size = 9),
                    legend.text = element_text(size = 8),
                    plot.background = element_rect(fill = "transparent", color = NA),
                    panel.background = element_rect(fill = "transparent", color = NA)
                ) +
                labs(title = NULL)

            girafe(
                ggobj = p,
                options = list(
                    opts_hover(
                        css = "fill-opacity:1; stroke:#ffffff; stroke-width:2px;"
                    ),
                    opts_hover_inv(
                        css = "fill-opacity:0.25;"
                    ),
                    opts_toolbar(
                        saveaspng = FALSE,
                        hidden = c("zoom_rect", "zoom_reset")
                    ),
                    opts_sizing(rescale = TRUE, width = 1),
                    opts_zoom(min = 1, max = 5)
                )
            )
        })

        ## ---- Return year_range for other modules ----
        list(year_range = reactive({ input$year }))
    })
}
