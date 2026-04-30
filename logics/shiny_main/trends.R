box::use(
    shiny[
        NS, tagList, div, h4, p, icon, strong, selectInput,
        checkboxInput, plotOutput, textOutput, moduleServer,
        reactive, renderPlot, renderText
    ],
    ggplot2[
        ggplot, aes, geom_col, geom_line, geom_point, geom_area,
        scale_y_continuous, scale_x_continuous, scale_color_manual,
        scale_fill_manual, facet_wrap, labs, theme_minimal, theme,
        element_blank, element_text, sec_axis
    ],
    dplyr[filter, mutate, group_by, summarise],
)

trends_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Epidemiological Trends"),
            p("Yearly dengue cases and rainfall index, 2018-2025", class = "module-subtitle")
        ),
        div(
            class = "control-row",
            selectInput(
                ns("view"), "View:",
                choices = c(
                    "National total" = "national",
                    "By region" = "regional"
                ),
                width = "200px"
            ),
            selectInput(
                ns("region"), "Region (regional view):",
                choices = NULL,
                width = "260px"
            )
        ),
        plotOutput(ns("trend_plot"), height = "360px"),
        div(
            class = "interpretation-box",
            icon("lightbulb"),
            strong(" Interpretation: "),
            textOutput(ns("interp"), inline = TRUE)
        )
    )
}

trends_server = function(id, national_ts, region_ts) {
    moduleServer(id, function(input, output, session) {

        shiny::observe({
            choices = unique(region_ts()$region_name)
            names(choices) = choices
            shiny::updateSelectInput(session, "region", choices = choices)
        })

        output$trend_plot = renderPlot({
            if (input$view == "national") {
                df = national_ts()
                scale_f = max(df$cases) / max(df$rainfall_index)

                ggplot(df, aes(x = year)) +
                    geom_area(
                        aes(y = rainfall_index * scale_f),
                        fill = "#90caf9",
                        alpha = 0.4
                    ) +
                    geom_line(
                        aes(y = cases),
                        color = "#e5383b",
                        linewidth = 1.2
                    ) +
                    geom_point(aes(y = cases), color = "#e5383b", size = 3) +
                    scale_y_continuous(
                        name = "Total Cases",
                        labels = scales::comma,
                        sec.axis = sec_axis(~ . / scale_f, name = "Rainfall Index")
                    ) +
                    scale_x_continuous(breaks = 2018:2025) +
                    labs(
                        x = NULL,
                        caption = "Blue area = rainfall index  |  Red line = national dengue cases"
                    ) +
                    theme_minimal(base_size = 13) +
                    theme(
                        panel.grid.minor = element_blank(),
                        axis.title.y = element_text(color = "#e5383b"),
                        axis.title.y.right = element_text(color = "#1565c0"),
                        plot.caption = element_text(color = "grey55", size = 10)
                    )
            } else {
                df = region_ts() |>
                    filter(region_name == input$region)

                ggplot(df, aes(x = year, y = cases)) +
                    geom_col(fill = "#1b3a5c", alpha = 0.8, width = 0.6) +
                    geom_line(
                        aes(y = incidence_rate * max(cases) / max(incidence_rate)),
                        color = "#e5383b",
                        linewidth = 1.1
                    ) +
                    geom_point(
                        aes(y = incidence_rate * max(cases) / max(incidence_rate)),
                        color = "#e5383b",
                        size = 2.5
                    ) +
                    scale_y_continuous(
                        name = "Cases",
                        labels = scales::comma,
                        sec.axis = sec_axis(
                            \(x) x * max(df$incidence_rate) / max(df$cases),
                            name = "Incidence (per 100,000)"
                        )
                    ) +
                    scale_x_continuous(breaks = 2018:2025) +
                    labs(
                        x = NULL,
                        caption = "Bars = case count  |  Red line = incidence rate per 100,000"
                    ) +
                    theme_minimal(base_size = 13) +
                    theme(
                        panel.grid.minor = element_blank(),
                        axis.title.y = element_text(color = "#1b3a5c"),
                        axis.title.y.right = element_text(color = "#e5383b"),
                        plot.caption = element_text(color = "grey55", size = 10)
                    )
            }
        }, res = 110)

        output$interp = renderText({
            df = national_ts()
            peak_yr = df$year[which.max(df$cases)]
            peak_c = format(max(df$cases), big.mark = ",")
            rain_peak = df$rainfall_index[df$year == peak_yr]

            paste0(
                "National peak of ", peak_c, " cases occurred in ", peak_yr,
                " (rainfall index: ", rain_peak, "). ",
                "Elevated rainfall increases Aedes aegypti breeding sites, ",
                "driving case surges in the following transmission season."
            )
        })
    })
}
