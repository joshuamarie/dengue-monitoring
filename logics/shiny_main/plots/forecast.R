box::use(
    ggplot2[
        ggplot, aes, geom_ribbon, geom_line, geom_vline,
        scale_color_manual, scale_x_continuous,
        scale_y_continuous, labs, theme_minimal, theme,
        element_blank, element_text
    ],
    ggiraph[
        geom_point_interactive, geom_line_interactive, girafe,
        opts_hover, opts_hover_inv, opts_toolbar, opts_sizing, opts_zoom
    ],
    dplyr[keep_when = filter, bind_rows],
    glue[f_string = glue]
)

forecast_plot = function(df, year) {
    obs = keep_when(df, type == "Observed")
    fcast = keep_when(df, type == "Forecast")

    connector = bind_rows(obs[nrow(obs), ], fcast[1, ])

    p = ggplot(df) +
        aes(x = year, y = predicted, color = type, group = type) +
        geom_ribbon(
            data = fcast,
            aes(ymin = lower, ymax = upper),
            fill = "#ffe082",
            alpha = 0.45,
            color = NA
        ) +
        geom_line_interactive(
            data = obs,
            aes(tooltip = type, data_id = type),
            linewidth = 1.15
        ) +
        geom_line_interactive(
            data = fcast,
            aes(tooltip = type, data_id = type),
            linewidth = 1.15
        ) +
        geom_line(
            data = connector,
            aes(x = year, y = predicted),
            color = "#1565c0",
            linewidth = 1.15,
            inherit.aes = FALSE
        ) +
        geom_point_interactive(
            data = obs,
            aes(
                tooltip = f_string("Year: {year}\nCases: {scales::comma(predicted)}"),
                data_id = type
            ),
            size = 2.8
        ) +
        geom_point_interactive(
            data = fcast,
            aes(
                tooltip = f_string("Year: {year}\nCases: {scales::comma(predicted)}"),
                data_id = type
            ),
            size = 2.8
        ) +
        geom_vline(
            xintercept = min(year) - 0.5,
            linetype = "dashed",
            color = "grey50"
        ) +
        scale_color_manual(
            values = c("Observed" = "#1565c0", "Forecast" = "#e65100")
        ) +
        scale_x_continuous(breaks = seq(min(df$year), max(year))) +
        scale_y_continuous(labels = scales::comma) +
        labs(
            x = NULL,
            y = "Cases",
            color = NULL,
            caption = "Shaded band = 95% prediction interval"
        ) +
        theme_minimal(base_size = 13) +
        theme(
            panel.grid.minor = element_blank(),
            legend.position = "none",
            plot.caption = element_text(color = "grey55", size = 10)
        )

    girafe(
        ggobj = p,
        width_svg = 11,
        height_svg = 5,
        options = list(
            opts_hover(
                css = "stroke-width:2.5px; stroke-opacity:1; fill-opacity:1;"
            ),
            opts_hover_inv(
                css = "stroke-opacity:0.2; fill-opacity:0.2;"
            ),
            opts_sizing(rescale = TRUE, width = 1),
            opts_zoom(min = 1, max = 2)
        )
    )
}
