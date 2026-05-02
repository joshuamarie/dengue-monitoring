box::use(
    dplyr[keep_when = filter],
    ggplot2[
        ggplot, aes, geom_area, geom_line, geom_point, geom_col,
        scale_y_continuous, scale_x_continuous, sec_axis,
        labs, theme_minimal, theme, element_blank, element_text
    ],
    scales[comma]
)

national_plot = function(df) {
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
            labels = comma,
            sec.axis = sec_axis(\(x) x / scale_f, name = "Rainfall Index")
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
}

regional_plot = function(df, region) {
    df = df |> keep_when(region_name == region)

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
            labels = comma,
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
